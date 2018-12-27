%Mark J Olah
% Test MexIFace operation wiht Armadillo vectors

classdef TestArmadillo < MexIFace.IFaceMixin
    properties (Constant=true)
        IFaceName = 'TestIFace';
    end
    methods
        function obj = TestArmadillo(vec)
            %
            iface = str2func(MexIFace.Test.TestArmadillo.IFaceName);
            obj = obj@MexIFace.IFaceMixin(iface);
            obj.openIface(vec);
        end

        function c = add(obj,o)
           c = obj.call('add',o);
        end
        function v = ret(obj)
           v = obj.call('ret');
        end
        function inc(obj,o)
           obj.call('inc',o);
        end

    end
end
