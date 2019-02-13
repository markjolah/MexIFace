% profile_test.m
%
% A simple script to experiment with profiling from the command line
%
Nrep=100;
r=rand(1000,1);
test_obj = MexIFace.Test.TestArmadillo(r);
for i=1:Nrep
    test_obj.inc(test_obj.ret());
end
