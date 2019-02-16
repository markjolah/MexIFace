#!/usr/bin/env python
#
# create-matlab-linker-stub.sh [options] <matlab_root_dirs...>
#
# Find and produce linkable stubs for as many valid matlab programs as found in the list of matlab_root_dirs.
# These are saved as matlab_stub_$ARCH_$VERS.tar.bz2 archives in --outdir which defaults to _mat
import os
import os.path
import re
import argparse
import subprocess

CORE_MATLAB_LIBS = ['mex','mx','eng','mat', 'mwblas','mwlapack']
DEFAULT_OUTDIR='_matlab_stubs'
KNOWN_ARCHS=['glnxa64','win64'] #All known archs
DEFAULT_ARCHS=['glnx64','win64'] #Default archs to accept
LIB_SEARCH_PARENT_DIRS=['bin','sys/os'] #Each of these needs an ARCH subdir to be an actual path to a lib-search dir
BASE_TAR_LIST=['VersionInfo.xml',
               'appdata/version.xml',
               'appdata/products/*',
               'extern/*']
REQUIRED_TAR_LIST=['bin/*/MATLAB']
DEFAULT_STUB_BASE_NAME='matlab_stub'
DEFAULT_STUB_EXT='tar.bz2'
MATLAB_ROOT_ENVIRONMENT_VARS=['MATLAB_ROOT','MATLAB_ROOTS']
MATLAB_VERS_INFO_RE=re.compile("<version>(?P<vers>[0-9]+\.[0-9]+)")
MATLAB_APPDATA_PRODUCTS_FILENAME_RE=re.compile("MATLAB (?P<vers>[0-9\\.]+) (?P<arch>[A-Za-z0-9_]+) [0-9]+.xml")
OBJDUMP_DLL_DEP_RE=re.compile("DLL Name:[ \t]+(?P<dep>[A-Za-z0-9\._+\-]+\.[dD][lL][lL])")
READELF_DEP_RE=re.compile("\(?NEEDED\)?[ \t]+[A-Za-z ]+:[ \t]*\[(?P<dep>[^\]]+)\][ \t\r]*")

ARCH_LIB_EXT_RE={'glnxa64':re.compile('(?P<name>\.so[\.\d+]*$)'),
                 'win64':re.compile('(?P<name>\.[dD][lL][lL]$)')}



VERS_TO_RELEASE={'8.0':'r2012b',
                 '8.1':'r2013a',
                 '8.2':'r2013b',
                 '8.3':'r2014a',
                 '8.4':'r2014b',
                 '8.5':'r2015a',
                 '8.6':'r2015b',
                 '9.0':'r2016a',
                 '9.1':'r2016b',
                 '9.2':'r2017a',
                 '9.3':'r2017b',
                 '9.4':'r2018a',
                 '9.5':'r2018b',
                 '9.6':'r2019a'}

#Parse arguments
parser = argparse.ArgumentParser(description='Prepare a linkable matlab stub directories from as many functioning matlab roots as can be reached from matlab roots')
parser.add_argument('-a','--archs',nargs='+',default=DEFAULT_ARCHS,
                    help='Restrict to one or more specific matlab arch supported options:[glnxa64, maci64, or win64].  Default t')

parser.add_argument('-o', '--outdir', default=DEFAULT_OUTDIR,
                    help='Output directory for archive files. [Default:%s]'%DEFAULT_OUTDIR)
parser.add_argument('-f', '--force',action='store_true', help='force overwrite of existent stub files')
parser.add_argument('-l', '--libs',nargs='+',
                    help='Additional lib names from bin/arch/ to include in dependency list.  Do not use -l syntax.  lib prefix is automatically appended if not found under given name.')
parser.add_argument('-n', '--name',default=DEFAULT_STUB_BASE_NAME,
                    help='Stub base name for output archives.')
parser.add_argument('matlab_roots', nargs='*',
                    help='Matlab root directories or parent directories of matlab root directories.')


def get_matlab_roots(args):
    if not args.matlab_roots:
        matlab_env = MATLAB_ROOT_ENVIRONMENT_VARS
        matlab_env.extend(['%s_%s'%(x,arch.upper()) for arch in args.archs for x in MATLAB_ROOT_ENVIRONMENT_VARS])
        matlab_roots = [x for x in (os.environ.get(env) for env in matlab_env) if x]
        matlab_roots = list(set(filter(None,(c for r in matlab_roots for c in re.findall('[^;:]+',r)))))
        if not matlab_roots:
            print('Error: No matlab roots given on command line or in environment variables: %s'%matlab_env)
            exit(1)
        return matlab_roots
    else:
        return args.matlab_roots

#determine if a director is a matlab root and find version, release and arch
def get_matlab_directory_info(matlab_dir):
    vers = None;
    release = None;
    arch = None;
    vers_file_path = os.path.join(matlab_dir,'VersionInfo.xml')
    products_dir = os.path.join(matlab_dir,'appdata','products')
    if os.path.isfile(vers_file_path):
        with open(vers_file_path, 'r') as version_f:
            m = re.search(MATLAB_VERS_INFO_RE, version_f.read())
        if m:
            vers = m.group('vers')
            release = VERS_TO_RELEASE[vers]
        for a in KNOWN_ARCHS:
            if os.path.isdir(os.path.join(matlab_dir,'bin',a)):
                arch = a
    elif os.path.isdir(products_dir):
        fnames = os.listdir(products_dir)
        for name in fnames:
            m = re.search(MATLAB_APPDATA_PRODUCTS_FILENAME_RE, name)
            if m:
                vers = m.group('vers')
                arch = m.group('arch').lower()
                release = VERS_TO_RELEASE[vers]
                break
    return arch, vers, release

#Iterate through all the matlab
checked_dirs = set()
def matlab_root_iter(matlab_roots):
    for mroot in matlab_roots:
        if mroot in checked_dirs:
            continue
        checked_dirs.add(mroot)
        if not os.path.isdir(mroot):
            continue
        arch, vers, release = get_matlab_directory_info(mroot);
        if arch:
            yield mroot, arch, vers, release
        else:
            dirs = [os.path.join(mroot,x) for x in os.listdir(mroot) if os.path.isdir(os.path.join(mroot,x))];
            if dirs:
                yield from matlab_root_iter(dirs)



def get_direct_dependencies(arch, dep_paths, lib_path):
    #lib_path is full path to library fill to find deps for
    #dep_paths is a dict mapping file to full_path, that are to be matched for dependencies
    #returns a generator for all the full paths to direct dependencies of lib_path library only.
    if arch=='win64':
        #win64
        task = subprocess.Popen("objdump -p %s | grep -i \'DLL Name\'"%lib_path, shell=True, stdout=subprocess.PIPE)
        deps = re.findall(OBJDUMP_DLL_DEP_RE, str(task.stdout.read()));
    elif arch=='glnxa64':
        #glnxa64
        task = subprocess.Popen("readelf -d %s"%lib_path, shell=True, stdout=subprocess.PIPE)
        deps = re.findall(READELF_DEP_RE, str(task.stdout.read()));
    else:
        raise NameError('Bad arch: %s'%arch)
    return (dep_paths[d] for d in deps if d in dep_paths)

def resolve_all_libs(arch, dep_paths, unresolved_libs):
    if isinstance(unresolved_libs,str):
        unresolved_libs=[unresolved_libs]
    unresolved_libs = set(unresolved_libs)
    resolved_libs=set()
    while(unresolved_libs):
        lib = unresolved_libs.pop()
        deps= set(get_direct_dependencies(arch, dep_paths, lib))
        new_deps = deps-resolved_libs;
        unresolved_libs|=new_deps;
        resolved_libs.add(lib)
    return resolved_libs


def find_matlab_lib_deps(mroot,arch,lib_dirs,lib_list):
    dep_paths = dict()
    for lib_dir in lib_dirs:
        if os.path.isdir(lib_dir):
            dep_paths.update((fs,os.path.join(lib_dir,fs)) for fs in os.listdir(lib_dir))
    full_paths=[]
    for lib in lib_list:
        names=[p%lib for p in ['%s','lib%s','%s.so','lib%s.so','%s.dll','lib%s.dll']]
        full_path=None
        for n in names:
            if n in dep_paths:
                _,ext = os.path.splitext(n)
                if ext:
                    full_path=dep_paths[n];
                    break;
        full_paths.append(full_path)
    return (re.sub('^%s/'%mroot, '',s) for s in resolve_all_libs(arch,dep_paths, full_paths)) #remove mroot

def generate_matlab_stubs(args):
    matlab_roots = get_matlab_roots(args)
    lib_list = CORE_MATLAB_LIBS
    if args.libs:
        lib_list.extend(args.libs)
    archs = args.archs
    outdir = args.outdir
    basename = args.name
    ext = DEFAULT_STUB_EXT
    print('Matlab Roots: ',matlab_roots)
    print('Linked Matlab Libs: ', lib_list)
    print('Matlab Archs: ', archs)
    for mroot, arch, vers, release in matlab_root_iter(matlab_roots):
        print
        outfile = os.path.abspath(os.path.join(outdir,'%s-%s-%s.%s'%(basename,arch,vers,ext)))
        if os.path.isfile(outfile) and not args.force:
            print('File exits. Unable to make archive [--force to override]:%s'%outfile)
            continue
        if not os.path.isdir(outdir):
            os.mkdir(outdir)

        print('Resolving MATLAB [%s] %s(%s): %s'%(arch,release,vers,mroot))
        lib_dirs = [os.path.join(mroot,x,arch) for x in LIB_SEARCH_PARENT_DIRS]
        base_list = set( f for f in BASE_TAR_LIST if os.path.exists(os.path.join(mroot,re.sub('[*]', '', f))) )
        tar_list = set(REQUIRED_TAR_LIST) | base_list | set(find_matlab_lib_deps(mroot,arch,lib_dirs,lib_list))
        tar_cmd='tar cvf %s --xform s:^:%s/%s/: %s' % (outfile, arch,release,' '.join(tar_list))
        print("Tar_cmd:\n%s"%tar_cmd)
        print('   * Archiving --> %s'%(outfile))
        task = subprocess.Popen( tar_cmd, cwd=mroot, shell=True, stdout=subprocess.PIPE)
        result = str(task.stdout.read());
        #print('result: ',result)

if __name__=="__main__":
    args = parser.parse_args()
    generate_matlab_stubs(args)
