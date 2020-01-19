function Preprocess( directoryName, caseID)
    for lvl = ["frc+bag", "tlc", "rv"]
        input_dir = fullfile( directoryName, 'cases', caseID);
        output_dir = fullfile( directoryName, 'casesPreprocess', caseID);
        
        antsImageFile = fullfile( char(lvl), [char(lvl) '_image.mha']);
        antsMaskFile = fullfile( char(lvl), [char(lvl) '_pmask.mha']);
        niftyImageFile = fullfile( [char(lvl) '_nifty'], [char(lvl) '_image.nii.gz']);
        niftyMaskFile = fullfile( [char(lvl) '_nifty'], [char(lvl) '_pmask.nii.gz']);
        origImg = MetaImage.read( fullfile( input_dir, antsImageFile));
        pprImg = MetaImage( origImg);
        
        q90 = quantile( origImg.data(:), 0.9);
        level = graythresh( min( double( origImg.data) / q90, 1));
        newValue = q90 * level;
        
        % thresholding value estimation
        rightSideData = origImg.data( :, 1:64, :);
        leftSideData = origImg.data( :, 192:256, :);
        
        counts = histcounts( [rightSideData( rightSideData>0); leftSideData( leftSideData>0)], floor(max( origImg.data(:))));
        counts(1:20) = 0;
        smoothedData = smooth( counts, 71);
        [~, cntLoc] = findpeaks( smoothedData, 'NPeaks', 2, 'SortStr', 'descend', ...
            'MinPeakDistance', 71);
        cntLoc = sort( cntLoc);
        [~, tmpVal] = findpeaks( -1 * smoothedData(cntLoc(1):cntLoc(2)), 'NPeaks', 1);
        thrVal = cntLoc(1) + tmpVal;
        
        darkRegion = ~ imbinarize( origImg.data, thrVal);
        innerRegion = darkRegion;
        for slc = 1:size( innerRegion, 3); innerRegion(:,:,slc) = imclearborder( darkRegion(:,:,slc)); end
        
        borderRegion = darkRegion - innerRegion;
        origImg.data( logical(borderRegion)) = newValue;
        
        
        a = 1085.7408528298274073936529326585;
        b = 669.37125128761945538492169264337;
        revVal = a - b * log10( double(origImg.data) * 7/60 + 7.5);
        pprImg.data = abs( revVal) + 0.9 * min( revVal, 0);
        pprImg.saveMetaImage( fullfile( output_dir, antsImageFile));
        
        system(['c3d ' fullfile( output_dir, antsImageFile) ' -type ushort -o ' fullfile( output_dir, niftyImageFile)]);
        
        copyfile( fullfile( input_dir, antsMaskFile), fullfile( output_dir, antsMaskFile));
        copyfile( fullfile( input_dir, niftyMaskFile), fullfile( output_dir, niftyMaskFile));
        
    end

end