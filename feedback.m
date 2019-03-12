function feedback(hObject,eventdata,handles)
%UNTITLED Summary of this function goes here,
%   Detailed explanation goes here
% % check for image query
% hObject
% guidata(hObject,handles);
siradata=getappdata(0,'siradata');

if (isappdata(siradata, 'feedbackdataset'))
    handles.feedbackdataset=getappdata(siradata,'feedbackdataset');
else
    errordlg('FEEDBACK: PLEASE LOAD feedbackdataset FIRST!');
    return;
end
if (isappdata(siradata, 'numOfReturnedImages'))
    handles.no_of_return_images=getappdata(siradata,'numOfReturnedImages');
else
    errordlg('FEEDBACK: PLEASE LOAD numOfReturnedImages FIRST!');
    return;
end

if (isappdata(siradata, 'sortedImgs'))
    handles.sortedImgs=getappdata(siradata,'sortedImgs');
else
    errordlg('FEEDBACK: PLEASE LOAD sortedImgs FIRST!');
    return;
end

if (isappdata(siradata, 'checkbox'))
    handles.checkbox=getappdata(siradata,'checkbox');
else
    errordlg('FEEDBACK: PLEASE LOAD checkbox FIRST!');
    return;
end

if (isappdata(siradata, 'feedbackpath'))
    handles.feedbackpath=getappdata(siradata,'feedbackpath');
else
    errordlg('FEEDBACK: PLEASE LOAD feedbackpath FIRST!');
    return;
end

if (isappdata(siradata, 'dataset'))
    handles.dataset=getappdata(siradata,'dataset');
%     handles.dataset=datasethandler.dataset;
else
    errordlg('FEEDBACK: PLEASE LOAD DATASET FIRST!');
    return;
end
if (isappdata(siradata, 'queryimagename') || isappdata(siradata, 'queryimagepath') || isappdata(siradata, 'queryimageext'))
    queryimagename=str2num(getappdata(siradata, 'queryimagename'));
    queryImagepath=getappdata(siradata, 'queryimagepath');
    queryImageext=getappdata(siradata,'queryimageext');
else
    errordlg('FEEDBACK: PLEASE LOAD DATASET FIRST!');
    return;
end
% fullfile( queryImagepath, strcat(queryimagename, queryImageext) )
% queryImage = imread( fullfile( queryImagepath, strcat(queryimagename, queryImageext) ) );

for m=1:handles.no_of_return_images
   val=get(handles.checkbox(m),'Value');
   image_no=str2num(get(handles.checkbox(m),'string'));
%    fprintf('Image:(%d,%d):%d->%d\r\n',queryimagename,image_no,handles.feedbackdataset(queryimagename,image_no),val);
   
   if (handles.feedbackdataset(queryimagename,image_no) == 0) && (val == 0)
       handles.feedbackdataset(queryimagename,image_no)= -1;
   elseif (handles.feedbackdataset(queryimagename,image_no) == 1) && (val == 1)
       handles.feedbackdataset(queryimagename,image_no)= val;
   elseif (handles.feedbackdataset(queryimagename,image_no) == 0) && (val == 1)
       handles.feedbackdataset(queryimagename,image_no)= val;
   elseif (handles.feedbackdataset(queryimagename,image_no) == -1) && (val == 1)
       handles.feedbackdataset(queryimagename,image_no)= val;
   end
end

location=handles.feedbackpath;
feedbackdataset=handles.feedbackdataset;
save(location,'feedbackdataset');
clear('handles.feedbackdataset','feedbackdataset');
handles.feedbackdataset=load(handles.feedbackpath);
handles.feedbackdataset=handles.feedbackdataset.feedbackdataset;
setappdata(siradata, 'feedbackdataset',handles.feedbackdataset);
helpdlg('Feedback Received Successfully.');
end