classdef mesh2d
    % Attributes.
    % \param nodes  2xNn matrix storing the coordinates of the nodes
    % \param elems  MxNe matrix storing for each element the Id's of the
    %               nodes belonging to the element itself; M should be 3
    %               for linear elements, 6 for quadratic elements
    % \param hmax   maximum size of the triangles, i.e. length of the 
    %               longest edge in the mesh 
    % \param hmin   minimum size of the triangles, i.e. length of the
    %               shortest edge in the mesh
    properties
        nodes, elems
        hmax, hmin
    end
    
    methods
        % Constructor.
        % \param n      list of nodes
        % \param e      list of triangles
        % \param hmax   length of longest edge
        % \param hmin   length of shortest edge
        function obj = mesh2d(n,e,varargin)
            % Initialize attributes
            obj.nodes = n;  obj.elems = e;
            
            if (nargin == 2)
                % Compute length for each edge and extract maximum and minimum 
                obj.hmax = -Inf;  obj.hmin = Inf;
                for i = 1:size(obj.elems,2)
                    % Extract vertices Id's
                    ia = obj.elems(1,i);  ib = obj.elems(2,i);  ic = obj.elems(3,i);

                    % Compute edges length
                    ab = norm(obj.nodes(:,ib)-obj.nodes(:,ia)); 
                    bc = norm(obj.nodes(:,ic)-obj.nodes(:,ib)); 
                    ca = norm(obj.nodes(:,ia)-obj.nodes(:,ic)); 

                    % If needed, update maximum
                    if (ab > obj.hmax)
                        obj.hmax = ab;
                    end
                    if (bc > obj.hmax)
                        obj.hmax = bc;
                    end
                    if (ca > obj.hmax)
                        obj.hmax = ca;
                    end

                    % If needed, update minimum
                    if (ab < obj.hmin)
                        obj.hmin = ab;
                    end
                    if (bc < obj.hmin)
                        obj.hmin = bc;
                    end
                    if (ca < obj.hmin)
                        obj.hmin = ca;
                    end
                end
            elseif nargin == 4
                % Catch length of longest and shortest edge
                obj.hmax = varargin{1};  obj.hmin = varargin{2};
            end
        end
                
        % Get the number of nodes.
        % \out  Nn number of nodes
        function Nn = getNumNodes(obj)
            Nn = size(obj.nodes,2);
        end
        
        % Get the number of elements.
        % \out  Ne number of elements
        function Ne = getNumElems(obj)
            Ne = size(obj.elems,2);
        end
    end
end