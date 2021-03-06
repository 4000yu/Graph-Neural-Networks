%Copyright (c) 2006, Franco Scarselli
%All rights reserved.
%
%Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
%
%Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
%Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
%
%THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



function makeSecondOrderNeighborsDataset(file)
% Create a dataset for the 2nd-order Neighbors problem
% USAGE: makeSecondOrderNeighborsDataset(<file.config>)


global dataSet params params_name
if ~isempty(dataSet)
    dataSet=[];
end


% load parameters from file
try
    if nargin ~= 1
        file='SecondOrderNeighborsDataset.config';     %default config file
    end
    [fid,message] = fopen(file,'rt');
    if fid == -1
        err(0,['<' file '>: ' message]);
    end
    
    params = [0 0 0 0 0 0 0];
    % graphDim graphDensity nodeLabelsDim maxLabel trainSet.supervisedNodeNumber
    % validationSet.supervisedNodeNumber testSet.supervisedNodeNumber
    params_name={'graphDim' 'graphDensity' 'nodeLabelsDim' 'maxLabel'...
        'trainSet.supervisedNodeNumber' 'validationSet.supervisedNodeNumber' 'testSet.supervisedNodeNumber'};
    
    delimiter = [';' ' ' 9 13];         %ASCII(9) = TABS, ASCII(13) = carriage return
    numline=0;
    while feof(fid) == 0
        numline=numline+1;
        line = fgetl(fid);
        if isempty(line)
            warn(numline, 'line is empty. Please remove it or comment it');
        elseif line(1)=='#'
            %this is a comment line
            continue;
        else    
            line = strtok(line, delimiter);
            k = strfind(line,'=');
            if size(k,2)==0
                err(numline,'No ''='' detected');
            elseif (size(k,2)>1)
                err(numline,'More than one "=" detected');
            end
            name = line(1:k-1);
            value = line(k+1:end);
            check_valueok(name,value,num2str(numline));            
        end
    end
    fclose(fid);
    check_thereisall;
catch
    fclose all;
    return;
end


dataSet.config.type='regression';
dataSet.config.nodeLabelsDim = 1;

%GRAPH GENERATION START

dataSet.config.supervisedNodeNumber=dataSet.trainSet.supervisedNodeNumber+dataSet.testSet.supervisedNodeNumber+...
    dataSet.validationSet.supervisedNodeNumber;

dataSet.trainSet.nNodes=dataSet.config.graphDim;
dataSet.testSet.nNodes=dataSet.config.graphDim;
dataSet.validationSet.nNodes=dataSet.config.graphDim;


b=randperm(dataSet.config.supervisedNodeNumber);

dataSet.trainSet.supervisedNodes=b(1:dataSet.trainSet.supervisedNodeNumber);
dataSet.validationSet.supervisedNodes=b((dataSet.trainSet.supervisedNodeNumber+1):...
    (dataSet.trainSet.supervisedNodeNumber+dataSet.validationSet.supervisedNodeNumber));
dataSet.testSet.supervisedNodes=b((dataSet.trainSet.supervisedNodeNumber+dataSet.validationSet.supervisedNodeNumber+1):...
    (dataSet.config.supervisedNodeNumber));
dataSet.config.supervisedNodes=b;

c=(rand(dataSet.config.graphDim)>(1-dataSet.config.graphDensity/2));
c=connectMatrix((c'|c)&(eye(dataSet.config.graphDim)==0));





dataSet.config.connMatrix=sparse(c);
dataSet.config.nodeLabels=round(dataSet.config.maxLabel*rand(dataSet.config.nodeLabelsDim,dataSet.config.graphDim));

dataSet.config.targets=zeros(1,dataSet.config.graphDim);

for i=1:dataSet.config.graphDim
    
    % find fathers
    fathers=find(dataSet.config.connMatrix(:,i));
    %disp(['fathers = ' num2str(fathers')]);
    % find 2nd-order neighbors
    grands=[];
    for j=1:size(fathers,1)
        grands=[grands; find(dataSet.config.connMatrix(:,fathers(j)))];
    end
    
    % i cannot be in i's grandfathers & duplicate values are not admissible
    grands=sort(grands);
    %grands'
    for k=1:size(grands,1)-1
        if grands(k)==i || grands(k)==grands(k+1)
            grands(k)=0;
        end
    end
    dataSet.config.targets(1,i)=size(find(grands),1);
    %dataSet.config.targets(i,1)
end

%scaling of the targets in the interval 0:2
mintarget=min(dataSet.config.targets)-1;
maxtarget=max(dataSet.config.targets);
dataSet.config.targets=(dataSet.config.targets-mintarget)/(maxtarget-mintarget)*2;









%In the following the validation, the test and the
%training set is built from the graph in dataset
dataSet.trainSet.connMatrix=dataSet.config.connMatrix;
dataSet.testSet.connMatrix=dataSet.config.connMatrix;
dataSet.validationSet.connMatrix=dataSet.config.connMatrix;

dataSet.trainSet.nodeLabels=dataSet.config.nodeLabels;
dataSet.testSet.nodeLabels=dataSet.config.nodeLabels;
dataSet.validationSet.nodeLabels=dataSet.config.nodeLabels;

dataSet.trainSet.targets=dataSet.config.targets;
dataSet.testSet.targets=dataSet.config.targets;
dataSet.validationSet.targets=dataSet.config.targets;

dataSet.trainSet.maskMatrix=spdiags(sparse(dataSet.trainSet.supervisedNodes,...
    ones(dataSet.trainSet.supervisedNodeNumber,1),ones(dataSet.trainSet.supervisedNodeNumber,1), ...
    dataSet.config.graphDim,1),0,dataSet.config.graphDim,dataSet.config.graphDim);
dataSet.testSet.maskMatrix=spdiags(sparse(dataSet.testSet.supervisedNodes,...
    ones(dataSet.testSet.supervisedNodeNumber,1),ones(dataSet.testSet.supervisedNodeNumber,1), ...
    dataSet.config.graphDim,1),0,dataSet.config.graphDim,dataSet.config.graphDim);
dataSet.validationSet.maskMatrix=spdiags(sparse(dataSet.validationSet.supervisedNodes,...
    ones(dataSet.validationSet.supervisedNodeNumber,1),ones(dataSet.validationSet.supervisedNodeNumber,1),...
    dataSet.config.graphDim,1),0,dataSet.config.graphDim,dataSet.config.graphDim);



% Check the correctness of the couple <parameter,value>
function check_valueok(name,value,n)
if isempty(value)
    err(n,['makeSecondOrderNeighborsDataset: No value specified for <' name '>']);
end
global params dataSet
switch name
    case 'graphDim'
        v=str2double(value);
        if ~isempty(findstr(value,',')) || (~isempty(findstr(value,'.'))) || isnan(v) || (v<=0)
            err(n,['Parameter <' name '> should be a positive integer. Check "' value '"']);
        end
        if params(5) && params(6) && params(7) && ...
             v<(dataSet.trainSet.supervisedNodeNumber+dataSet.validationSet.supervisedNodeNumber+dataSet.testSet.supervisedNodeNumber)
            err(n,'Parameters <graphDim> should be greater or equal to (<trainSet.supervisedNodeNumber>+<validationSet.supervisedNodeNumber>+<testSet.supervisedNodeNumber>');
        end
        dataSet.config.graphDim=v;
        params(1)=1;
    case 'graphDensity'
        v=str2double(value);
        if isnan(v) || (v<=0) || (v>1)
            err(n,['Parameter <' name '> should be in the interval (0,1]. Check "' value '"']);
        end
        dataSet.config.graphDensity=v;
        params(2)=1;
    case 'nodeLabelsDim'
        v=str2double(value);
        if ~isempty(findstr(value,',')) || (~isempty(findstr(value,'.'))) || isnan(v) || (v<=0)
            err(n,['Parameter <' name '> should be a positive integer. Check "' value '"']);
        end
        dataSet.config.nodeLabelsDim=v;
        params(3)=1;
    case 'maxLabel'
        v=str2double(value);
        if ~isempty(findstr(value,',')) || (~isempty(findstr(value,'.'))) || isnan(v) || (v<=0)
            err(n,['Parameter <' name '> should be a positive integer. Check "' value '"']);
        end
        dataSet.config.maxLabel=v;
        params(4)=1;
    case 'trainSet.supervisedNodeNumber'
        v=str2double(value);
        if ~isempty(findstr(value,',')) || (~isempty(findstr(value,'.'))) || isnan(v) || (v<=0)
            err(n,['Parameter <' name '> should be a positive integer. Check "' value '"']);
        end
        if params(1) && params(6) && params(7) && ...
             v>(dataSet.config.graphDim-dataSet.validationSet.supervisedNodeNumber-dataSet.testSet.supervisedNodeNumber)
            err(n,'Parameters <graphDim> should be greater or equal to (<trainSet.supervisedNodeNumber>+<validationSet.supervisedNodeNumber>+<testSet.supervisedNodeNumber>');
        end
        dataSet.trainSet.supervisedNodeNumber=v;
        params(5)=1;
    case 'validationSet.supervisedNodeNumber'
        v=str2double(value);
        if ~isempty(findstr(value,',')) || (~isempty(findstr(value,'.'))) || isnan(v) || (v<=0)
            err(n,['Parameter <' name '> should be a positive integer. Check "' value '"']);
        end
        if params(1) && params(5) && params(7) && ...
             v>(dataSet.config.graphDim-dataSet.trainSet.supervisedNodeNumber-dataSet.testSet.supervisedNodeNumber)
            err(n,'Parameters <graphDim> should be greater or equal to (<trainSet.supervisedNodeNumber>+<validationSet.supervisedNodeNumber>+<testSet.supervisedNodeNumber>');
        end
        dataSet.validationSet.supervisedNodeNumber=v;
        params(6)=1;
    case 'testSet.supervisedNodeNumber'
        v=str2double(value);
        if ~isempty(findstr(value,',')) || (~isempty(findstr(value,'.'))) || isnan(v) || (v<=0)
            err(n,['Parameter <' name '> should be a positive integer. Check "' value '"']);
        end
        if params(1) && params(5) && params(6) && ...
             v>(dataSet.config.graphDim-dataSet.trainSet.supervisedNodeNumber-dataSet.validationSet.supervisedNodeNumber)
            err(n,'Parameters <graphDim> should be greater or equal to (<trainSet.supervisedNodeNumber>+<validationSet.supervisedNodeNumber>+<testSet.supervisedNodeNumber>');
        end
        dataSet.testSet.supervisedNodeNumber=v;
        params(7)=1;
    otherwise
        err(n,['Parameter <' name '> is unknown']);
end


% Check if all necessary parameters has been set
function check_thereisall
global params params_name
ok=1;
for i=1:size(params,2)
    if params(i)==0
        try
            err(0,['makeSecondOrderNeighborsDataset: No parameter <' char(params_name(i)) '> in the configuration file']);
        catch
            ok=0;
        end
    end
end
if ok==0
    rethrow(lasterr);
end
