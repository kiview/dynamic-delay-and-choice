% taken from https://de.mathworks.com/matlabcentral/answers/93275-how-can-i-randomly-combine-the-elements-of-two-arrays-in-matlab-7-5-r2007b

function out=mixarrays(A,B)

    %This function takes in two horizontal arrays, combines them,
    %and then randomizes the order of the elements in the new array.
    
    %Concatonates the two horizontal arrays into one long horizontal array
    C=[A B];
    
    %Measures the size of the new array
    num_elements=length(C);
    
    %Randomly generates new indecies to generate the randomize the elements
    indexvector=randperm(num_elements);
    
    %Initialize the output vector
    out=zeros(1,num_elements);
    
    %Writes the ourput vector
    for i=1:num_elements
        out(i)=C(indexvector(i));    
    end
    