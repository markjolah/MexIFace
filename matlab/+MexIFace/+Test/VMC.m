%Mark J Olah
% Test MexIFace operation with simple vector, matrix, cube (VMC) class

classdef VMC < MexIFace.MexIFaceMixin
    methods
        function obj = VMC(v,m,c)
            obj = obj@MexIFace.MexIFaceMixin('VMC_IFace');
            obj.openIFace(v,m,c);
        end
        
        function v = getVec(obj)
            v = obj.call('getVec');
        end
        
        function s = vecSum(obj, arr1, arr2)
            s = obj.callstatic('vecSum',arr1,arr2);
        end

    end
end
