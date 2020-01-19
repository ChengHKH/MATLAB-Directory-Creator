caseData = readtable( '../caseList.csv', 'ReadVariableNames', true, ...
    'TextType', 'string', 'Format', '%s%s');

create( caseData, 'res_agreement');

function create( caseData, folder)
for row = 1:height( caseData)
    caseID = caseData.CaseID{row};
    
    refList = ['reg_tasks+ref_' caseID '.list'];
    refData = readtable( refList, 'FileType', 'text', 'ReadVariableNames', false, ...
        'TextType', 'string', 'Format', '%s');
    
    inflation = ["tlc" "frc+bag" "rv"];
    
    if isequal( folder, 'res_agreement')
        mkdir( fullfile( '..','output',caseID,folder));
        
        if ~exist( fullfile( '..','output',caseID,folder,'A'), 'dir')
            mkdir( fullfile( '..','output',caseID,folder,'A'));
            mkdir( fullfile( '..','output',caseID,folder,'A','all'));
            mkdir( fullfile( '..','output',caseID,folder,'A','all','metric1'));
            mkdir( fullfile( '..','output',caseID,folder,'A','all','metric2'));
            mkdir( fullfile( '..','output',caseID,folder,'A','all','metric3'));
            mkdir( fullfile( '..','output',caseID,folder,'A','all','metric4'));
        end
        
        for ref_row = 1:height( refData)
            
            refFolder=['ref_' refData.Var1{ref_row}];
            outFolder = sprintf( 'multi_atlas_%02d',ref_row);
            
            if ~exist( fullfile( '..','output',caseID,folder,'A',outFolder,'metric1'))
                mkdir( fullfile( '..','output',caseID,folder,'A',outFolder,'metric1'));
            end
                
            if ref_row == 1
                totalTP = struct('OutID',cell(22,1), 'tlc',cell(22,1), 'frc',cell(22,1), 'rv',cell(22,1));
                totalFN = struct('OutID',cell(22,1), 'tlc',cell(22,1), 'frc',cell(22,1), 'rv',cell(22,1));
            end
            
            [totalTP( ref_row,1), totalFN( ref_row,1)] = metric( 'metric1');
            
            if ref_row == height( refData)
                Total_TP_File = fullfile( '..','output',caseID,folder,'A','all','metric1','niftyTotal_TP_Fraction.csv');
                Total_FN_File = fullfile( '..','output',caseID,folder,'A','all','metric1','niftyTotal_FN_Fraction.csv');
                writetable( struct2table( totalTP), Total_TP_File);
                writetable( struct2table( totalFN), Total_FN_File);
            end
            
            
            if ref_row == 1
                airwayTP = struct('OutID',cell(22,1), 'tlc',cell(22,1), 'frc',cell(22,1), 'rv',cell(22,1));
                airwayFN = struct('OutID',cell(22,1), 'tlc',cell(22,1), 'frc',cell(22,1), 'rv',cell(22,1));
            end
            
            [airwayTP( ref_row,1), airwayFN( ref_row,1)] = metric( 'metric2');
            
            if ref_row == height( refData)
                Airway_TP_File = fullfile( '..','output',caseID,folder,'A','all','metric2','niftyAirway_TP_Fraction.csv');
                Airway_FN_File = fullfile( '..','output',caseID,folder,'A','all','metric2','niftyAirway_FN_Fraction.csv');
                writetable( struct2table( airwayTP), Airway_TP_File);
                writetable( struct2table( airwayFN), Airway_FN_File);
            end 
            
        end
        
    end
    
end

    function varargout = metric( metricType)
        for i = 1:3
            try
                caseFileName = [inflation{i} '_pmask.mha'];
                caseFile = fullfile( '..','cases',caseID,caseFileName);
                case_lbl = MetaImage.read( caseFile);
                
                refFileName = ['lbl_est_' inflation{i} '.nii.gz'];
                refFile = fullfile( '..','output',caseID,'mapping',refFolder,[inflation{i} '_nifty'],refFileName);
                ref_lbl = NiftiImage.read( refFile);
                
                if isequal( metricType, 'metric1')
                    TP = nnz(case_lbl.data & ref_lbl.data);
                    TP_Fraction{i} = TP / nnz(case_lbl.data);
                    
                    FN = nnz(case_lbl.data) - TP;
                    FN_Fraction{i} =  FN / nnz(case_lbl.data);
                
                elseif isequal( metricType, 'metric2')
                    TP = nnz(case_lbl.data == 4 & ref_lbl.data == 4);
                    TP_Fraction{i} = TP / nnz(case_lbl.data == 4);
                    
                    FN = nnz(case_lbl.data == 4) - TP;
                    FN_Fraction{i} =  FN / nnz(case_lbl.data == 4);
                   
%                 elseif isequal( metricType, 'metric3')
                    
%                 elseif isequal( metricType, 'metric4')
%                     case_lbl.data( case_lbl.data > 1) = 1;
%                     ref_lbl.data( case_lbl.data >1) = 1;
%                     
%                     case_PEDT = bwdist( imcomplement(case_lbl.data));
%                     case_NEDT = -(bwdist( case_lbl.data));
%                     case_SEDT = case_PEDT + case_NEDT;
%                     
%                     dif = abs( double(case_lbl.data) - double(ref_lbl.data));
%                     
%                     
%                     dis1 = sum( abs( case_SEDT) .* dif, 'all') / nnz( case_lbl.data);
%                     dis2 = sum( (( case_SEDT ./ 10).^4) .* dif, 'all') / nnz( case_lbl.data);
%                     dis3 = sum( exp( -( case_SEDT ./ 10).^4) .* dif, 'all') / nnz( case_lbl.data);
%                     
                    
                end
                
            catch
                TP_Fraction{i} = 'N/A';
                FN_Fraction{i} = 'N/A';
                
            end
            
        end
        
        if isequal( metricType, 'metric1')
            metricFile = ["niftyTotal_TP_Fraction.csv" "niftyTotal_FN_Fraction.csv"];
        elseif isequal( metricType, 'metric2')
            metricFile = ["niftyAirway_TP_Fraction.csv" "niftyAirway_FN_Fraction.csv"];
        end
        
        if isequal( metricType, 'metric1') || isequal(metricType, 'metric2')
            intersection(1,1).OutID = sprintf('%02d',ref_row);
            intersection(1,1).tlc = TP_Fraction{1};
            intersection(1,1).frc = TP_Fraction{2};
            intersection(1,1).rv = TP_Fraction{3};
            varargout{1} = intersection(1,1);
            TP_File = fullfile( '..','output',caseID,folder,'A',outFolder,metricType,metricFile{1});
            writetable( struct2table( intersection(1,1)), TP_File);
            
            intersection(2,1).OutID = sprintf('%02d',ref_row);
            intersection(2,1).tlc = FN_Fraction{1};
            intersection(2,1).frc = FN_Fraction{2};
            intersection(2,1).rv = FN_Fraction{3};
            varargout{2} = intersection(2,1);
            FN_File = fullfile( '..','output',caseID,folder,'A',outFolder,metricType,metricFile{2});
            writetable( struct2table( intersection(2,1)), FN_File);
        end
        
    end

end