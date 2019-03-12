function Features(hObject, eventdata, handles, numOfReturnedImages,metric)
% input:
%   numOfReturnedImages : num of images returned by query
%   queryImageFeatureVector: query image in the form of a feature vector
%   dataset: the whole dataset of images transformed in a matrix of
%   features
% 
% output: 
%   plot: plot images returned by query

guidata(hObject, handles);
siradata = getappdata(0, 'siradata');

if (~isfield(handles, 'imagedataset'))
    errordlg('Please load a dataset first. If you dont have pne then you should consider creating one!');
    return;
else
    dataset = getappdata(siradata,'dataset');
end

if (isappdata(siradata, 'queryimagename'))
    
    queryimagename = str2num(getappdata(siradata,'queryimagename'));
else
    errordlg('Please select image for search!');
    return;
end

if(isappdata(siradata,'feedbackdataset'))
    handles.feedbackdataset = getappdata(siradata,'feedbackdataset');
else
    if(exist('feedbackdatabase','file')==0)
        mkdir 'feedbackdatabase';
        filepath = fileparts('feedbackdatabase/');
    else
        filepath = fileparts('feedbackdatabase/');
    end
    filepath = fullfile(filepath,strcat('feedback_',getappdata(siradata,'imagedatasetname'),'.mat'));
    
    if(exist(filepath,'file') == 0)
        [rows,cols] = size(dataset);
        feedbackdataset = int32.empty(rows,0);
        feedbackdataset(1:rows,1:rows) = 0;
        save(filepath,'feedbackdataset');
        clear('feedbackdataset');
    else
        fprintf('Database Exist...Loading Dataset...\r\n');
    end
    handles.feedbackdataset = load(filepath);
    handles.feedbackdataset = handles.feedbackdataset.feedbackdataset;
    guidata(hObject, handles);
    setappdata(siradata, 'feedbackdataset', handles.feedbackdataset);
    setappdata(siradata, 'feedbackpath', filepath);
end    


queryImageFeatureVector = handles.query_image_feature;

% extract image fname from queryImage and dataset
query_image_name = queryImageFeatureVector(:, end);
dataset_image_names = dataset(:, end);

queryImageFeatureVector(:, end) = [];
dataset(:, end) = [];

if (metric == 1)
    manhattan = zeros(size(dataset, 1), 1);
    progress_bar = waitbar(0,'Loading...','Name','SIRA--Create Database','CreateCancelBtn','setappdata(gcbf,''cancel_callback'',1)');
    setappdata(progress_bar,'cancel_callback',0);
    steps = size(dataset, 1);
    for k = 1:size(dataset, 1)
    %     manhattan(k) = sum( abs(dataset(k, :) - queryImageFeatureVector) );
        % ralative manhattan distance
        if getappdata(progress_bar,'cancel_callback')
            break;
        end
        waitbar(k/steps,progress_bar,sprintf('Loading...%.2f%%',k/steps*100));
        manhattan(k) = sum( abs(dataset(k, :) - queryImageFeatureVector) ./ ( 1 + dataset(k, :) + queryImageFeatureVector ) );
    end
    % add image fnames to manhattan
    manhattan = [manhattan dataset_image_names];

    % sort them according to smallest distance
    [sortedDist indx] = sortrows(manhattan);
    sortedImgs = sortedDist(:, 2);
    delete(progress_bar)

elseif (metric == 2)
    euclidean = zeros(size(dataset, 1), 1);
    progress_bar = waitbar(0,'Loading...','Name','SIRA--Create Database','CreateCancelBtn','setappdata(gcbf,''cancel_callback'',1)');
    setappdata(progress_bar,'cancel_callback',0);
    steps = size(dataset, 1);
    % compute euclidean distance
    for k = 1:size(dataset, 1)
        if getappdata(progress_bar,'cancel_callback')
            break;
        end
        waitbar(k/steps,progress_bar,sprintf('Loading...%.2f%%',k/steps*100));
        euclidean(k) = sqrt( sum( power( dataset(k, :) - queryImageFeatureVector, 2 ) ) );
    end
    % add image fnames to euclidean
    euclidean = [euclidean dataset_image_names];

    % sort them according to smallest distance
    [sortDist indxs] = sortrows(euclidean);
    sortedImgs = sortDist(:, 2);
    delete(progress_bar)
    
elseif(metric == 3)
    stdeuclidean = zeros(size(dataset, 1), 1);
    progress_bar = waitbar(0,'Loading...','Name','SIRA--Create Database','CreateCancelBtn','setappdata(gcbf,''cancel_callback'',1)');
    setappdata(progress_bar,'cancel_callback',0);
    steps = size(dataset, 1);
    % compute standardized euclidean distance
    weights = nanvar(dataset, [], 1);
    weights = 1./weights;
    for q = 1:size(dataset, 2)
        waitbar(q/steps,progress_bar,sprintf('Loading...%.2f%%',q/steps*100));
        stdeuclidean = stdeuclidean + weights(q) .* (dataset(:, q) - queryImageFeatureVector(1, q)).^2;
    end
    stdeuclidean = sqrt(stdeuclidean);
    
    % add image fnames to euclidean
    stdeuclidean = [stdeuclidean dataset_image_names];

    % sort them according to smallest distance
    [sortDist indxs] = sortrows(stdeuclidean);
    sortedImgs = sortDist(:, 2);
    delete(progress_bar)
    
elseif (metric == 4)
    nmdeuclidean = zeros(size(dataset, 1), 1);
    progress_bar = waitbar(0,'Loading...','Name','SIRA--Create Database','CreateCancelBtn','setappdata(gcbf,''cancel_callback'',1)');
    setappdata(progress_bar,'cancel_callback',0);
    steps = size(dataset, 1);
    % compute normalized euclidean distance
    for k = 1:size(dataset, 1)
        waitbar(k/steps,progress_bar,sprintf('Loading...%.2f%%',k/steps*100));
        nmdeuclidean(k) = sqrt( sum( power( dataset(k, :) - queryImageFeatureVector, 2 ) ./ std(queryImageFeatureVector) ) );
    end
    nmdeuclidean = sqrt(nmdeuclidean);
    
    % add image fnames to euclidean
    nmdeuclidean = [nmdeuclidean dataset_image_names];

    % sort them according to smallest distance
    [sortDist indxs] = sortrows(nmdeuclidean);
    sortedImgs = sortDist(:, 2);
    delete(progress_bar)
    
elseif(metric == 5)
    % compute mahalanobis distance
    weights = nancov(dataset);
    [T, flag] = chol(weights);
    if (flag ~= 0)
        errordlg('The matrix is not positive semidefinite. Please choose another similarity metric!');
        return;
    end
    weights = T \ eye(size(dataset, 2)); %inv(T)
    del = bsxfun(@minus, dataset, queryImageFeatureVector(1, :));
    dsq = sum((del/T) .^ 2, 2);
    dsq = sqrt(dsq);
    mahalanobis = dsq;
    % add image fnames to euclidean
    mahalanobis = [mahalanobis dataset_image_names];

    % sort them according to smallest distance
    [sortDist indxs] = sortrows(mahalanobis);
    sortedImgs = sortDist(:, 2);

elseif(metric == 6)
    cityblock = pdist2(dataset, queryImageFeatureVector, 'cityblock');
    % add image fnames to euclidean
    cityblock = [cityblock dataset_image_names];

    % sort them according to smallest distance
    [sortDist indxs] = sortrows(cityblock);
    sortedImgs = sortDist(:, 2);

elseif (metric == 7)
    minkowski = pdist2(dataset, queryImageFeatureVector, 'minkowski');
    % add image fnames to euclidean
    minkowski = [minkowski dataset_image_names];

    % sort them according to smallest distance
    [sortDist indxs] = sortrows(minkowski);
    sortedImgs = sortDist(:, 2);
    
elseif (metric == 8)
    chebychev = pdist2(dataset, queryImageFeatureVector, 'chebychev');
    % add image fnames to euclidean
    chebychev = [chebychev dataset_image_names];

    % sort them according to smallest distance
    [sortDist indxs] = sortrows(chebychev);
    sortedImgs = sortDist(:, 2);
    
elseif (metric == 9)
    cosine = pdist2(dataset, queryImageFeatureVector, 'cosine');
    % add image fnames to euclidean
    cosine = [cosine dataset_image_names];

    % sort them according to smallest distance
    [sortDist indxs] = sortrows(cosine);
    sortedImgs = sortDist(:, 2);
    
elseif (metric == 10)
    correlation = pdist2(dataset, queryImageFeatureVector, 'correlation');
    % add image fnames to euclidean
    correlation = [correlation dataset_image_names];

    % sort them according to smallest distance
    [sortDist indxs] = sortrows(correlation);
    sortedImgs = sortDist(:, 2);
    
elseif (metric == 11)
    spearman = pdist2(dataset, queryImageFeatureVector, 'spearman');
    % add image fnames to euclidean
    spearman = [spearman dataset_image_names];

    % sort them according to smallest distance
    [sortDist indxs] = sortrows(spearman);
    sortedImgs = sortDist(:, 2);

elseif (metric == 12)
    reldeviation= zeros(size(dataset, 1), 1);
    progress_bar = waitbar(0,'Loading...','Name','SIRA--Create Database','CreateCancelBtn','setappdata(gcbf,''cancel_callback'',1)');
    setappdata(progress_bar,'cancel_callback',0);
    steps = size(dataset, 1);
    % compute euclidean distance
    for k = 1:size(dataset, 1)
        if getappdata(progress_bar,'cancel_callback')
            break;
        end
        waitbar(k/steps,progress_bar,sprintf('Loading...%.2f%%',k/steps*100));
        reldeviation(k) = sqrt( sum( power( dataset(k, :) - queryImageFeatureVector, 2 ) ) ) ./ 1/2 * ( sqrt( sum( power( dataset(k, :), 2 ) ) ) + sqrt( sum( power( queryImageFeatureVector, 2 ) ) ) );
    end
    % add image fnames to euclidean
    reldeviation= [reldeviation dataset_image_names];

    % sort them according to smallest distance
    [sortDist indxs] = sortrows(reldeviation);
    sortedImgs = sortDist(:, 2);
    delete(progress_bar)

elseif (metric == 13)
    hamming = pdist2(dataset, queryImageFeatureVector, 'hamming');
    % add image fnames to euclidean
    hamming = [hamming dataset_image_names];

    % sort them according to smallest distance
    [sortDist indxs] = sortrows(hamming);
    sortedImgs = sortDist(:, 2);
    
elseif (metric == 14)
    jaccard = pdist2(dataset, queryImageFeatureVector, 'jaccard');
    % add image fnames to euclidean
    jaccard = [jaccard dataset_image_names];

    % sort them according to smallest distance
    [sortDist indxs] = sortrows(jaccard);
    sortedImgs = sortDist(:, 2);    
end

% clear axes
arrayfun(@cla, findall(0, 'type', 'axes'));
arrayfun(@cla, findall(0, 'type', 'checkbox'));

%cla(axes_result_images, 'reset');
%a=axes_result_images;
%axes(a);

% display query image
str_name = int2str(query_image_name);
queryImage = imread( strcat('images\', str_name, '.jpg') );

%subplot(5, 5, 1);
%axes('Units','Pixels','Position',[300,500,100,100]);
%imshow(queryImage, []);

%title('Query Image', 'Color', [1 0 0]);

% dispaly images returned by query
xaxes=300;
yaxes=500;
cnt=0;
imageitr=1;

for m = 1 : size(sortedImgs)
    img_name = sortedImgs(m);
    img_no = img_name;
     
    if(~(handles.feedbackdataset(queryimagename,img_no) == -1))
        if imageitr <= numOfReturnedImages
            img_name = int2str(img_name);
            str_name = strcat('images\', img_name, '.jpg');
            returnedImage = imread(str_name);
            ha = axes('Units','Pixels','Position',[xaxes,yaxes,100,100]);
            imshow(returnedImage,[]);
             
            %subplot(5, 5,m);
            %imshow(returnedImage, []);
            % display_img_name = strcat(img_name, '.jpg');
            %title( display_img_name , 'Color', 'b');
            
            if (handles.feedbackdataset(queryimagename,img_no) == 1)
                checkbox(imageitr) = uicontrol('Style','checkbox',...
                                    'string',img_no,'value',1,'tag',sprintf('checkbox%d',imageitr),...
                                    'Position',[xaxes+85 yaxes+85 20 20]);
            else
                checkbox(imageitr) = uicontrol('Style','checkbox',...
                                    'string',img_no,'tag',sprintf('checkbox%d',imageitr),...
                                    'Position',[xaxes+85 yaxes+85 20 20]);
            end
            xaxes = xaxes+110;
            cnt=cnt+1;
            if mod(cnt,7)==0
                yaxes=yaxes-110;
                xaxes=300;
            end
            imageitr=imageitr+1;
        else
            break;
        end
    end
end

setappdata(siradata,'numOfReturnedImages',numOfReturnedImages);
setappdata(siradata,'sortedImgs',sortedImgs);
setappdata(siradata,'checkbox',checkbox);


btn = uicontrol('Style','pushbutton','String','Feedback',...
                'Position', [1000 17 100 50],...
                'BackgroundColor',[1.0,0.5,0.0],...
                'ForegroundColor',[1.0,1.0,1.0],...
                'Callback', {@feedback,guidata(hObject)});
guidata(hObject,handles);
end