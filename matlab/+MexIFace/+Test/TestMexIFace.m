% MexIFace.Test.testMexIFace
%
% Class-Based Unit Testing for MexIFace
%

classdef TestMexIFace < matlab.unittest.TestCase
    methods (Test)


        function testConstruct(testCase)
            vec = 1:10;
            obj = MexIFace.Test.TestArmadillo(vec);
            verifyEqual(class(obj),'MexIFace.Test.TestArmadillo')
        end
    end
end
