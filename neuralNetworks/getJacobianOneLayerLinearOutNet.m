%Copyright (c) 2006, Franco Scarselli
%All rights reserved.
%
%Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
%
%Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
%Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
%
%THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



function [gradient,dInputs]=getJacobianOneLayerLinearOutNet(net,netState,delta,jacNode)
exampleNum=size(netState.inputs,2);
hiddensNum=size(net.weights1,1);
outNum=size(delta,1);

hiddenFirstDer=1-netState.hiddens.*netState.hiddens;
hiddenSecondDer=-2*netState.hiddens .* (1-netState.hiddens.*netState.hiddens);
gradient.weights1=delta*(netState.hiddens .* repmat(net.weights1(:,jacNode),hiddensNum,exampleNum))';
gradient.bias1=zeros(outNum,1);
dnetf1=(net.weights2'*delta) .* hiddenSecondDer .*repmat(net.weights1(:,jacNode),hiddensNum,exampleNum);
df2=(net.weights2'*delta) .* hiddenFirstDer ;
dnetf2=sparse([],[],[],hiddensNum,exampleNum);
dnetf2(:,jacNode)=df2;
gradient.weights1=dnetf1 * netState.inputs';
gradient.bias1=sum(dnetf1,2);    %sum(dnetf1')'



