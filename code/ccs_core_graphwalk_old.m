function PR = ccs_core_graphwalk_old(A,r,type)
%CCS_CORE_GRAPHWALK Number of walks on a graph
%   Inputs:
%     A - adjacency matrix
%     r - walk distance
%     type - type of walk
%
%   Outputs:
%     PR - matrix indexing numbers of r-walks of type on the graph A
%
% Copyright:
%   Xi-Nian Zuo firstly codes this function in 11/20/2019, Seattle, Washington.
%   This is part of the Connectome Computation System (CCS)
%   Updates: 12/06/2021

% Website: 
%   https://github.com/zuoxinian/CCS
%   
% References:
%   [1] Arrigo et al., 2018, Linear Algebra and its Applications, 556:381-399.
%   [2] Xu et al., 2015, Science Bulletin, 60(1):86-95.
%   [3] Xing et al., 2021, Science Bulletin, xx(x):xx-xx.

if nargin<3
    type = 'normal';
end

A(A~=0) = 1; %binarized
A = A - diag(diag(A));
D = diag(diag(A^2));
S = A.*A';
if r==0
    PR = eye(size(A)); 
end
if r==1
    PR = A; 
end
if r==2
    PR = A^2;% - D;
end
if r>2
    switch type
        case 'normal' %all walks counted
            PR1 = ccs_core_graphwalk_old(A,r-1);
%             PR1 = PR1 - diag(diag(PR1));
            PR = A*PR1;
        case 'nbtw' %non-back-tracking-walk
            if issymmetric(A)    
                PR1 = ccs_core_graphwalk_old(A,r-2,'nbtw');
                PR1 = PR1 - diag(diag(PR1));
                PR2 = ccs_core_graphwalk_old(A,r-1,'nbtw');
                PR2 = PR2 - diag(diag(PR2));
                PR = A*PR2 - (D-eye(size(A)))*PR1;
            else
                PR1 = ccs_core_graphwalk_old(A,r-3,'nbtw');
%                 PR1 = PR1 - diag(diag(PR1));
                PR2 = ccs_core_graphwalk_old(A,r-2,'nbtw');
%                 PR2 = PR2 - diag(diag(PR2));
                PR3 = ccs_core_graphwalk_old(A,r-1,'nbtw');
%                 PR3 = PR3 - diag(diag(PR3));
                PR = A*PR3 - (D-eye(size(A)))*PR2 - (A-S)*PR1;
            end
        otherwise
            disp('Please assign the type of walks: normal, nbtw, ...')
    end
end

end