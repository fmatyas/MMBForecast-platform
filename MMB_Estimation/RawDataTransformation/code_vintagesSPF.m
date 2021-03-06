%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Should be ran as a standalone file %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


global PGNP zone  FirstObs Start OBSERVATION VINTAGES;
zone = 'us';

DataInitialization
FirstObs = cell2mat(PGNP(2,1)); a=ObsInfos(2,2);a=a{:};
OBSERVATION=[];VINTAGES=[];

str=date;
for y = 1940:str2num(str([8:11]))+20
    
    for q = 1:4
        OBSERVATION = [OBSERVATION;[num2str(y) ':Q' num2str(q)]];
        a = num2str(y);
        VINTAGES = [VINTAGES;[a(end-1:end) 'Q' num2str(q)]];
    end
end
l = size(RawData,2)+1; 
%%%%%%%%%%%%%This part extracts SPF forecasts and creates vintage with
%%%%%%%%%%%%%appopriate names using the script code_vintagesSPF
cd1 = cd;

cd('..\DATA\USDATA\SPF')

location = cd;

cd(cd1);

f = ObsInfos(2,1);

[~,~,PGNP] = xlsread(cell2mat(f{1}));
a = cell2mat(PGNP(1,2)); m = size(a,2);
Start = a(m-3:m);
PGNP = [[PGNP(1,1) PGNP(1,find(strcmp(PGNP(1,:), ['P' Start])):end)];...
    [PGNP(find(strcmp(PGNP(:,1), FirstObs)):end,1), PGNP(find(strcmp(PGNP(:,1), FirstObs)):end,...
    find(strcmp(PGNP(1,:), ['P' Start])):end)]];

SPFDATAMAT{1} = [];
SFP_Files = {'SPFRGDP';'SPFPGDP';'FEDFUNDS'}; 
for val = 1:3
handles.filename = ObsInfos(val,1) ;
 
handles.VintLabel = ObsInfos(val,2);
 
a=ObsInfos(val,3);a=a{:};
handles.quarterly = a;

 handles.obsformat = ObsInfos(val,4); 

handles.vintformat = ObsInfos(val,5);  

handles.posobservation = ObsInfos(val,6); 

handles.posrelease = ObsInfos(val,7); 

handles.transformation = ObsInfos(val,8);

handles.variables = ObsInfos(val,9); 

handles.Observables=ObsInfos(val,10); 

handles.variables_a = ObsInfos(val,11); 

handles.spffilename={[RawData cell2mat(SFP_Files(val,:))]};   

SPFDATAMAT{val} = extend_forecast(handles ,SPFDATAMAT{1});
    
end


%%%%%%%%%%%%%This part extracts SPF forecasts and creates vintage with
%%%%%%%%%%%%%appopriate names using the script code_vintagesSPF
cd1 = cd;

cd('..\DATA\USDATA\SPF')

location = cd;
cd(cd1);
Vintages = {'Vintages','Available','Missing Variables'};

Vintages(2,:) = {[],[],[]};

horizon = 5;

for vint = 2:size(SPFDATAMAT{1}(1,:),2)
    for n = 1:3
        SPFBenchmark{n} = num2cell(-999*ones(horizon,1));
    end
    
    a = cellstr(SPFDATAMAT{1}(1,vint)); a = a{1}; m = size(a,2)-3; namevint = get_vint_name(a);
    
    Vintages(vint,1) = {namevint};
    
    l = find(strcmp(VINTAGES,{[a(m:m+1) 'Q' a(end)]})==1);
    
    position_FirstObs = find(strcmp(SPFDATAMAT{1}(:,1),OBSERVATION(l,:))==1)-1;
    
    if position_FirstObs<(size(SPFDATAMAT{1},1)-horizon-1)
        
        Quarter(:,1) = SPFDATAMAT{1}(position_FirstObs+1:position_FirstObs+horizon,1);
        for i = 1:horizon
            for n = 1:3
                if (cell2mat(SPFDATAMAT{n}(position_FirstObs+i,vint))~=-999 && cell2mat(SPFDATAMAT{n}(position_FirstObs+i,vint))~=-99)
                    SPFBenchmark{n}(i,1) = {4*cell2mat(SPFDATAMAT{n}(position_FirstObs+i,vint))};
                end
            end
        end
    end
    for n = 1:3
        SPFBenchmark{n} = [Quarter SPFBenchmark{n}];
    end
    
    missing = zeros(1,3);
    
    for n = 1:3
        for i = 1:size(SPFBenchmark{n},1)
            if ((cell2mat(SPFBenchmark{n}(i,2))==-99)||(cell2mat(SPFBenchmark{n}(i,2))==-999))
                missing(n) = 1;
            end
        end
    end
    
    if isempty(find(missing==1))
       
        Vintages(vint,2) = cellstr('yes');
        
        VintData=[SPFDATAMAT(1,1);SPFBenchmark{1}(:,1)];
        for i=1:3
            aaa=ObsInfos(i,11);        
            VintData=[VintData [cell2mat(aaa{:});SPFBenchmark{i}(:,2)]];
        end
        
        xlswrite([location '\ExcelFileSPF\' namevint],VintData,1)
        xlswrite([location '\ExcelFileSPFNC\' namevint],[VintData(1,:);VintData(3:end,:)],1)
    else
        Vintages(vint,2) = cellstr('no');
        missinglist = [];
        b = find(missing==1);
        for i = 1:size(b,2)
            aaa=ObsInfos(i,11);
            if i == 1                
                missinglist = [missinglist cell2mat(aaa{:})];
            else
                missinglist = [missinglist ', ' cell2mat(aaa{:})];
            end
        end
        Vintages(vint,3) = cellstr(missinglist);
    end
end

xlswrite([location '\Vintagesrev'],Vintages,'Vintages') 
