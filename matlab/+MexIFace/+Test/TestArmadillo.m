%Mark J Olah
% Test MexIFace operation wiht Armadillo vectors

classdef TestArmadillo < MexIFace.MexIFaceMixin
    methods
        function obj = TestArmadillo(vec)
            obj = obj@MexIFace.MexIFaceMixin('TestArmadilloIFace');
            obj.openIFace(vec);
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
        function echoArray(obj, arr)
            %Convert strings to char arrays as C MEX API cannot access string objects
            obj.call('echoArray',cellstr(arr)); 
        end
        function s = vecSum(obj, arr1, arr2)
            s = obj.callstatic('vecSum',arr1,arr2);
        end

    end
end
