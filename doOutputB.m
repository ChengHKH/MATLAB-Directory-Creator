% create( 'res_agreement');

if ~exist( fullfile( '..','plots'), 'dir')
    mkdir( fullfile( '..','plots'));
end
create( 'plots')

function create( folder)
caseData = readtable( '../caseList.csv', 'ReadVariableNames', true, ...
    'TextType', 'string', 'Format', '%s%s');

inflation = ["tlc" "frc+bag" "rv"];



if isequal( folder, 'res_agreement')
    
    for row = 6:height( caseData)
        caseID = caseData.CaseID{row};
        
        if ~exist( fullfile( '..','output',caseID,folder,'B'), 'dir')
            mkdir( fullfile( '..','output',caseID,folder,'B'));
        end
        
        metric( 'total');
        metric( 'lungs');
        metric( 'airway');
        
    end
    
elseif isequal( folder, 'plots')
    
    plots( 'total');
    plots( 'lungs');
    plots( 'airway');
    
end

    function metric( metricType)
        
        for i = 1:3
            caseFileName = [inflation{i} '_pmask.mha'];
            caseFile = fullfile( '..','output',caseID,'mapping','my_data',caseFileName);
            case_lbl = MetaImage.read( caseFile);
            
            refFileName = ['lbl_fusion_' inflation{i} '.mha'];
            antsFile = fullfile( '..','output',caseID,'mapping','mas',refFileName);
            try ants_lbl = MetaImage.read( antsFile); end
            niftyFile = fullfile( '..','output',caseID,'mapping','mas_nifty',refFileName);
            try nifty_lbl = MetaImage.read( niftyFile); end
            
            if isequal( metricType, 'total')
                case_lbl.data( case_lbl.data > 1) = 1;
                try ants_lbl.data( ants_lbl.data > 1) = 1; end
                try nifty_lbl.data( nifty_lbl.data > 1) = 1; end
            elseif isequal( metricType, 'lungs')
                case_lbl.data = case_lbl.data == 1;
                try ants_lbl.data = ants_lbl.data == 1; end
                try nifty_lbl.data = nifty_lbl.data == 1; end
            elseif isequal( metricType, 'airway')
                case_lbl.data = case_lbl.data == 4;
                try ants_lbl.data = ants_lbl.data == 4; end
                try nifty_lbl.data = nifty_lbl.data == 4; end
            end
            
            case_PEDT = bwdist( imcomplement(case_lbl.data));
            case_NEDT = -(bwdist( case_lbl.data));
            case_SEDT = case_PEDT + case_NEDT;
            
            volumes(i,1).Inflation = inflation{i};
            volumes(i,1).Case = prod( case_lbl.spacing) * nnz( case_lbl.data);
            try volumes(i,1).Ants = prod( ants_lbl.spacing) * nnz( ants_lbl.data); catch volumes(i,1).Ants = 0; end
            volumes(i,1).Ants_Error = abs( volumes(i,1).Case - volumes(i,1).Ants) / volumes(i,1).Case;
            try volumes(i,1).Nifty = prod( nifty_lbl.spacing) * nnz( nifty_lbl.data); catch volumes(i,1).Nifty = 0; end
            volumes(i,1).Nifty_Error = abs( volumes(i,1).Case - volumes(i,1).Nifty) / volumes(i,1).Case;
            
            try
                ants(i,1).Inflation = inflation{i};
                ants(i,1).TP = nnz( case_lbl.data & ants_lbl.data);
                ants(i,1).TP_Fraction = ants(i,1).TP / nnz( case_lbl.data);
                ants(i,1).TN = nnz( ~case_lbl.data & ~ants_lbl.data);
                ants(i,1).TN_Fraction = ants(i,1).TN / nnz( ~case_lbl.data);
                ants(i,1).FP = nnz( ~case_lbl.data) - ants(i,1).TN;
                ants(i,1).FP_Fraction = ants(i,1).FP / nnz( ~case_lbl.data);
                ants(i,1).FN = nnz( case_lbl.data) - ants(i,1).TP;
                ants(i,1).FN_Fraction =  ants(i,1).FN / nnz( case_lbl.data);
                ants(i,1).XOR = ( ants(i,1).FP + ants(i,1).FN) / nnz( case_lbl.data);
                dif = abs( double(case_lbl.data) - double(ants_lbl.data));
                ants(i,1).Proxy_1 = sum( abs( case_SEDT) .* dif, 'all') / nnz( case_lbl.data);
                ants(i,1).Proxy_2 = sum( (( case_SEDT ./ 10).^4) .* dif, 'all') / nnz( case_lbl.data);
                ants(i,1).Proxy_3 = sum( exp( -( case_SEDT ./ 10).^4) .* dif, 'all') / nnz( case_lbl.data);
            end
            
            try
                nifty(i,1).Inflation = inflation{i};
                nifty(i,1).TP = nnz( case_lbl.data & nifty_lbl.data);
                nifty(i,1).TP_Fraction = nifty(i,1).TP / nnz( case_lbl.data);
                nifty(i,1).TN = nnz( ~case_lbl.data & ~nifty_lbl.data);
                nifty(i,1).TN_Fraction = nifty(i,1).TN / nnz( ~case_lbl.data);
                nifty(i,1).FP = nnz( ~case_lbl.data) - nifty(i,1).TN;
                nifty(i,1).FP_Fraction = nifty(i,1).FP / nnz( ~case_lbl.data);
                nifty(i,1).FN = nnz( case_lbl.data) - nifty(i,1).TP;
                nifty(i,1).FN_Fraction =  nifty(i,1).FN / nnz( case_lbl.data);
                nifty(i,1).XOR = ( nifty(i,1).FP + nifty(i,1).FN) / nnz( case_lbl.data);
                dif = abs( double(case_lbl.data) - double(nifty_lbl.data));
                nifty(i,1).Proxy_1 = sum( abs( case_SEDT) .* dif, 'all') / nnz( case_lbl.data);
                nifty(i,1).Proxy_2 = sum( (( case_SEDT ./ 10).^4) .* dif, 'all') / nnz( case_lbl.data);
                nifty(i,1).Proxy_3 = sum( exp( -( case_SEDT ./ 10).^4) .* dif, 'all') / nnz( case_lbl.data);
            end
            
        end
        
        writetable( struct2table( volumes), fullfile( '..','output',caseID,folder,'B',[metricType 'Volumes.csv']));
        writetable( struct2table( ants), fullfile( '..','output',caseID,folder,'B',[metricType 'AntsMetrics.csv']));
        writetable( struct2table( nifty), fullfile( '..','output',caseID,folder,'B',[metricType 'NiftyMetrics.csv']));
        
    end

    function plots( plotsType)
        
        for row = 6:height( caseData)
            caseID = caseData.CaseID{row};
            
            if isequal( plotsType, 'total')
                volumes = readtable( fullfile( '..','output',caseID,'res_agreement','B',[plotsType 'Volumes.csv']), ...
                    'ReadVariableNames', true, 'Format', '%s%f%f%f%f%f');
                try ants = readtable( fullfile( '..','output',caseID,'res_agreement','B',[plotsType 'AntsMetrics.csv']), ...
                        'ReadVariableNames', true, 'Format', '%s%f%f%f%f%f%f%f%f%f%f%f%f'); end
                try nifty = readtable( fullfile( '..','output',caseID,'res_agreement','B',[plotsType 'NiftyMetrics.csv']), ...
                        'ReadVariableNames', true, 'Format', '%s%f%f%f%f%f%f%f%f%f%f%f%f'); end
            elseif isequal( plotsType, 'lungs')
                volumes = readtable( fullfile( '..','output',caseID,'res_agreement','B',[plotsType 'Volumes.csv']), ...
                    'ReadVariableNames', true, 'Format', '%s%f%f%f%f%f');
                try ants = readtable( fullfile( '..','output',caseID,'res_agreement','B',[plotsType 'AntsMetrics.csv']), ...
                        'ReadVariableNames', true, 'Format', '%s%f%f%f%f%f%f%f%f%f%f%f%f'); end
                try nifty = readtable( fullfile( '..','output',caseID,'res_agreement','B',[plotsType 'NiftyMetrics.csv']), ...
                        'ReadVariableNames', true, 'Format', '%s%f%f%f%f%f%f%f%f%f%f%f%f'); end
            elseif isequal( plotsType, 'airway')
                volumes = readtable( fullfile( '..','output',caseID,'res_agreement','B',[plotsType 'Volumes.csv']), ...
                    'ReadVariableNames', true, 'Format', '%s%f%f%f%f%f');
                try ants = readtable( fullfile( '..','output',caseID,'res_agreement','B',[plotsType 'AntsMetrics.csv']), ...
                        'ReadVariableNames', true, 'Format', '%s%f%f%f%f%f%f%f%f%f%f%f%f'); end
                try nifty = readtable( fullfile( '..','output',caseID,'res_agreement','B',[plotsType 'NiftyMetrics.csv']), ...
                        'ReadVariableNames', true, 'Format', '%s%f%f%f%f%f%f%f%f%f%f%f%f'); end
            end
            
            XOR(row - 5,1).CaseID = caseID;
            try XOR(row - 5,1).tlcAntsXOR = ants.XOR(1); end
            try XOR(row - 5,1).tlcNiftyXOR = nifty.XOR(1); end
            try XOR(row - 5,1).frcAntsXOR = ants.XOR(2); end
            try XOR(row - 5,1).frcNiftyXOR = nifty.XOR(2); end
            try XOR(row - 5,1).rvAntsXOR = ants.XOR(3); end
            try XOR(row - 5,1).rvNiftyXOR = nifty.XOR(3); end
            
            volError(row - 5,1).CaseID = caseID;
            try volError(row - 5,1).tlcAntsError = volumes.Ants_Error(1); end
            try volError(row - 5,1).tlcNiftyError = volumes.Nifty_Error(1); end
            try volError(row - 5,1).frcAntsError = volumes.Ants_Error(2); end
            try volError(row - 5,1).frcNiftyError = volumes.Nifty_Error(2); end
            try volError(row - 5,1).rvAntsError = volumes.Ants_Error(3); end
            try volError(row - 5,1).rvNiftyError = volumes.Nifty_Error(3); end
            
        end
        
        writetable( struct2table( XOR), fullfile( '..','plots',[plotsType 'XOR.csv']));
        writetable( struct2table( volError), fullfile( '..','plots',[plotsType 'VolError.csv']));

        frcAntsXOR = [XOR(:).frcAntsXOR];
        frcNiftyXOR = [XOR(:).frcNiftyXOR];
        tlcAntsXOR = [XOR(:).tlcAntsXOR];
        tlcNiftyXOR = [XOR(:).tlcNiftyXOR];
        rvAntsXOR = [XOR(:).rvAntsXOR];
        rvNiftyXOR = [XOR(:).rvNiftyXOR];
        
        frcAntsError = [volError(:).frcAntsError];
        frcNiftyError = [volError(:).frcNiftyError];
        tlcAntsError = [volError(:).tlcAntsError];
        tlcNiftyError = [volError(:).tlcNiftyError];
        rvAntsError = [volError(:).rvAntsError];
        rvNiftyError = [volError(:).rvNiftyError];
        
        f1 = figure;
        ax1 = subplot(1,3,1);
        boxplot(([frcAntsXOR; frcNiftyXOR]*100)', 'Labels',{'ANTs','NiftyReg'});
        xlabel('\bf frc+bag');
        ylabel('Percentage Error');
        ax2 = subplot(1,3,2);
        boxplot(([tlcAntsXOR; tlcNiftyXOR]*100)', 'Labels',{'ANTs','NiftyReg'});
        xlabel('\bf tlc');
        ax3 = subplot(1,3,3);
        boxplot(([rvAntsXOR; rvNiftyXOR]*100)', 'Labels',{'ANTs','NiftyReg'});
        xlabel('\bf rv');
        ylim([ax1 ax2 ax3],[-1 37]);
        sgtitle('Relative Spatial Error');
        print( f1, fullfile( '..','plots',[plotsType 'XOR']), '-dsvg');
        
        f2 = figure;
        ax4 = subplot(1,3,1);
        boxplot(([frcAntsError; frcNiftyError]*100)', 'Labels',{'ANTs','NiftyReg'});
        xlabel('\bf frc+bag');
        ylabel('Percentage Error');
        ax5 = subplot(1,3,2);
        boxplot(([tlcAntsError; tlcNiftyError]*100)', 'Labels',{'ANTs','NiftyReg'});
        xlabel('\bf tlc');
        ax6 = subplot(1,3,3);
        boxplot(([rvAntsError; rvNiftyError]*100)', 'Labels',{'ANTs','NiftyReg'});
        xlabel('\bf rv');
        ylim([ax4 ax5 ax6],[-1 28]);
        sgtitle('Relative Measurement Error');
        print( f2, fullfile( '..','plots',[plotsType 'VolError']), '-dsvg');
        
    end

end