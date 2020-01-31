%drgcmDecodeddFFPreProcess
%Does pre-processing of dFF for decoding LFP power from single cell dFF
clear all
close all
 
use_raw=0; %If this is 1 the program uses the raw trace, otherwise it uses the inferred trace

figNo=0;

%Theta
handles.lowF(1)=6;
handles.highF(1)=14;

%Beta
handles.lowF(2)=15;
handles.highF(2)=30;

%Low gamma
handles.lowF(3)=35;
handles.highF(3)=55;

%High gamma
handles.lowF(4)=65;
handles.highF(4)=95;

%Names of bandwidths
handles.bw_names{1}='Theta';
handles.bw_names{2}='Beta';
handles.bw_names{3}='Low gamma';
handles.bw_names{4}='High gamma';

%Ask user for the file with the traces
[choiceFileName,choiceBatchPathName] = uigetfile({'*batch_per_file.mat'},'Select the .mat file for analysis');
fprintf(1, ['\ndrgcmCrossPCArhddFF run for ' choiceFileName '\n\n']);

cd(choiceBatchPathName)
load(choiceFileName)

%rho
ii_rho=0;
rho_dFF=[];
pval_rho_dFF=[];
rho_dFFc=[];
pval_rho_dFFc=[];
ii_drho=0;
rho_ddFF=[];
pval_rho_ddFF=[];
rho_fileNo=[];
rho_dFFtrace_no=[];
rho_electrode_no=[];
rho_bwii=[];


%Shuffled rho
ii_rhos=0;
rhos_dFF=[];
pval_rhos_dFF=[];
rhos_ddFF=[];
pval_rhos_ddFF=[];
rhos_fileNo=[];
rhos_dFFtrace_no=[];
rhos_electrode_no=[];
rhos_bwii=[];

for fileNo=1:handles_per_file.no_files
    for bwii=1:4
        no_timepoints_dFF=size(handles_per_file.file(fileNo).dFFtraces,2);
        if use_raw==1
            dFFtraces=handles_per_file.file(fileNo).dFFtraces;
        else
            dFFtraces=handles_per_file.file(fileNo).dFFtraces_inferred;
        end
        no_traces_dFF=size(handles_per_file.file(fileNo).dFFtraces,1);
        decimated_LFP_logPtraces=zeros(handles_per_file.file(fileNo).no_electrodes,no_timepoints_dFF);
        LFPtime=handles_per_file.file(fileNo).log_P_time;
        dFFtime=handles_per_file.file(fileNo).dFF_time;
        dt_dFF=dFFtime(2)-dFFtime(1);
        for elect_no=1:handles_per_file.file(fileNo).no_electrodes
            decimated_LFP_logPtraces(elect_no,1)=mean(handles_per_file.file(fileNo).log_P_timecourses_per_bw(elect_no,bwii,(LFPtime>dFFtime(1))&(LFPtime<=dFFtime(1)+(dt_dFF/2))),3);
            decimated_LFP_logPtraces(elect_no,end)=mean(handles_per_file.file(fileNo).log_P_timecourses_per_bw(elect_no,bwii,(LFPtime>dFFtime(end)-(dt_dFF/2))&(LFPtime<=dFFtime(end))),3);
            for ii_time=2:no_timepoints_dFF-1
                decimated_LFP_logPtraces(:,ii_time)=mean(handles_per_file.file(fileNo).log_P_timecourses_per_bw(:,bwii,(LFPtime>dFFtime(ii_time)-(dt_dFF/2))&(LFPtime<=dFFtime(ii_time)+(dt_dFF/2))),3);
            end
        end
        
        %Save the decimated data
        save([choiceFileName(1:end-19) '_dFF.txt'],'dFFtraces','-ascii')
        save([choiceFileName(1:end-19) '_LFP_' handles.bw_names{bwii} '.txt'],'decimated_LFP_logPtraces','-ascii')
        dFFtraces_t=dFFtraces';
        decimated_LFP_logPtraces_t=decimated_LFP_logPtraces';
        save([choiceFileName(1:end-19) '_dec_' handles.bw_names{bwii} '.mat'],'dFFtraces_t','decimated_LFP_logPtraces_t','dFFtime')
        
        %Convolve lick_freq using a window of 0.9 sec
        no_conv_points=5;
        conv_win=ones(1,no_conv_points);
        conv_dFFtraces=zeros(no_traces_dFF,no_timepoints_dFF);
        
        for trace_no=1:no_traces_dFF
            conv_dFFtraces(trace_no,:)=conv(dFFtraces(trace_no,:),conv_win,'same')/no_conv_points;
        end
        
        
        %Convolve LFP using a window of 4.5 sec
        no_conv_points=25;
        conv_win=ones(1,no_conv_points);
        conv_LFP_logPtraces=zeros(16,no_timepoints_dFF);
        
        for elNo=1:16
            conv_LFP_logPtraces(elNo,:)=conv(decimated_LFP_logPtraces(elNo,:),conv_win,'same')/no_conv_points;
        end
        conv_LFP_logPtraces_t=conv_LFP_logPtraces';
        save([choiceFileName(1:end-19) '_dec_c_' handles.bw_names{bwii} '.mat'],'dFFtraces_t','conv_LFP_logPtraces_t','dFFtime')
        
        
        %Calculate rho and choose the mose correlated Ca traces
        no_tr_out=16;
        mask_dFF=~isnan(decimated_LFP_logPtraces(1,:));
        for elect_no=1:handles_per_file.file(fileNo).no_electrodes
            these_rhos=zeros(no_traces_dFF,1);
            these_rhosc=zeros(no_traces_dFF,1);
            for trace_no=1:no_traces_dFF
                ii_rho=ii_rho+1;
                [rho_dFF(ii_rho),pval_rho_dFF(ii_rho)] = corr(dFFtraces(trace_no,mask_dFF)',decimated_LFP_logPtraces(elect_no,mask_dFF)');
                [rho_dFFc(ii_rho),pval_rho_dFFc(ii_rho)] = corr(dFFtraces(trace_no,mask_dFF)',decimated_LFP_logPtraces(elect_no,mask_dFF)');
                rho_fileNo(ii_rho)=fileNo;
                rho_dFFtrace_no(ii_rho)=trace_no;
                rho_electrode_no(ii_rho)=elect_no;
                rho_bwii(ii_rho)=bwii;
                these_rhos(trace_no)=rho_dFF(ii_rho);
                these_rhosc(trace_no)=rho_dFF(ii_rho);
            end
        end
        
        %Now output the most correlated dFFtraces
        data_to_sort=zeros(no_traces_dFF,2);
        data_to_sort(:,1)=abs(these_rhos);
        data_to_sort(:,2)=[1:no_traces_dFF];
        sorted_rows=sortrows(data_to_sort,'descend');
        dFFtraces_purged=zeros(length(dFFtime),16);
        for ii=1:16
            dFFtraces_purged(:,ii)=dFFtraces_t(:,sorted_rows(ii,2));
        end
        
        save([choiceFileName(1:end-19) '_dec_purged_' handles.bw_names{bwii} '.mat'],'dFFtraces_purged','decimated_LFP_logPtraces_t','dFFtime')
        
        %Now output the most correlated convolved dFFtraces
        data_to_sort=zeros(no_traces_dFF,2);
        data_to_sort(:,1)=abs(these_rhosc);
        data_to_sort(:,2)=[1:no_traces_dFF];
        sorted_rows=sortrows(data_to_sort,'descend');
        dFFtracesc_purged=zeros(length(dFFtime),16);
        for ii=1:16
            dFFtracesc_purged(:,ii)=conv_dFFtraces(:,sorted_rows(ii,2));
        end
        
        save([choiceFileName(1:end-19) '_dec_purged_' handles.bw_names{bwii} '.mat'],'dFFtracesc_purged','decimated_LFP_logPtraces_t','dFFtime')
        
        %Now calculate rho for shuffled dFF
        no_segments=10;
        no_shuffles=10;
        segments=[1:no_segments];
        per_seg=perms(segments);
        seg_ii=randi(size(per_seg,1),1,10000);
        ii_used=0;
        seg_length=floor(sum(mask_dFF)/no_segments);
        
        for shuf_ii=1:no_shuffles
            found_shuffle=0;
            while found_shuffle==0
                ii_used=ii_used+1;
                if sum(per_seg(seg_ii(ii_used),:)==segments)==0
                    found_shuffle=1;
                end
            end
          
            for elect_no=1:handles_per_file.file(fileNo).no_electrodes
                for trace_no=1:no_traces_dFF
                    shdFFtrace=zeros(1,no_segments*seg_length);
                    this_per_ii=per_seg(seg_ii(ii_used),:);
                    for ii=1:no_segments
                        shdFFtrace(1,(ii-1)*seg_length+1:ii*seg_length)=dFFtraces(trace_no,(this_per_ii(ii)-1)*seg_length+1:this_per_ii(ii)*seg_length);
                    end
                    ii_rhos=ii_rhos+1;
                    [rhos_dFF(ii_rhos),pval_rhos_dFF(ii_rhos)] = corr(shdFFtrace(1,:)',decimated_LFP_logPtraces(elect_no,1:length(shdFFtrace))');
                    
                    rhos_fileNo(ii_rhos)=fileNo;
                    rhos_dFFtrace_no(ii_rhos)=trace_no;
                    rhos_electrode_no(ii_rhos)=elect_no;
                    rhos_bwii(ii_rhos)=bwii;
                end
            end
        end
        
%         %Calculate PCs per timepoint
%         for ii_time=1:no_timepoints_dFF
%             these_logPs=zeros(1,handles_per_file.file(fileNo).no_electrodes);
%             these_logPs(1,:)=decimated_LFP_logPtraces(:,ii_time);
%             this_PCs_logP=[];
%             [coeff_logP,this_PCs_logP,latent_logP]=pca(these_logPs');
%             if ii_time==1
%                 PCs_logP=zeros(length(this_PCs_logP),no_timepoints_dFF);
%             end
%             PCs_logP(:,ii_time)=this_PCs_logP;
%             
%             these_dFFs=zeros(1,no_traces_dFF);
%             these_dFFs(1,:)=dFFtraces(:,ii_time);
%             this_PCs_dFF=[];
%             [coeff_logP,this_PCs_dFF,latent_logP]=pca(these_dFFs');
%              if ii_time==1
%                 PCs_dFF=zeros(length(this_PCs_dFF),no_timepoints_dFF);
%             end
%             PCs_dFF(:,ii_time)=this_PCs_dFF;
%         end
%         
%         figNo=figNo+1;
%         try
%             close(figNo)
%         catch
%         end
%         hFig=figure(figNo);
%         set(hFig, 'units','normalized','position',[.05 .1 .85 .8])
%         
%         hold on
%         
%         
%         
%         PC1_dFF=PCs_dFF(1,:)';
%         PC1_logP=PCs_logP(1,:)';
%         PC_mask=(~isnan(PC1_dFF))&(~isnan(PC1_logP));
%         PC1_dFF=PC1_dFF(PC_mask);
%         PC1_logP=PC1_logP(PC_mask);
%         
%         plot(PC1_dFF,PC1_logP,'.k')
%         xlabel('PC1 for dFF')
%         ylabel('PC1 for logP')
%         title(['PC1 plot for ' handles.bw_names{bwii}])
%        
%         [rho,pval] = corr(PC1_dFF,PC1_logP);
%         
%         fprintf(1, ['\nFor file No %d ' handles.bw_names{bwii} 'PC1 dFF vs PC1 logP rho= %d, p value= %d\n'],fileNo,rho, pval);
%         
        %Now do dFF derivative
      
        
        ddFFtraces=zeros(no_traces_dFF,size(dFFtraces,2));
        ddFFtraces(:,2:end)=(conv_dFFtraces(:,2:end)-conv_dFFtraces(:,1:end-1))/dt_dFF;
        ddFFtraces(:,1)=ddFFtraces(:,2);
        ddFFtraces_t=ddFFtraces';
        save([choiceFileName(1:end-19) '_dec_d_' handles.bw_names{bwii} '.mat'],'ddFFtraces_t','decimated_LFP_logPtraces_t','dFFtime')
        pffft=1;
        
        
        %Calculate rho for the derivative and choose the mose correlated ddFF Ca traces
        no_tr_out=16;
        mask_dFF=~isnan(decimated_LFP_logPtraces(1,:));
        for elect_no=1:handles_per_file.file(fileNo).no_electrodes
            these_rhos=zeros(no_traces_dFF,1);
            for trace_no=1:no_traces_dFF
                ii_drho=ii_drho+1;
                [rho_ddFF(ii_drho),pval_rho_ddFF(ii_drho)] = corr(ddFFtraces(trace_no,mask_dFF)',decimated_LFP_logPtraces(elect_no,mask_dFF)');
                these_rhos(trace_no)=rho_dFF(ii_drho);
            end
        end
        
        %Now output the most correlated dFFtraces
        data_to_sort=zeros(no_traces_dFF,2);
        data_to_sort(:,1)=abs(these_rhos);
        data_to_sort(:,2)=[1:no_traces_dFF];
        sorted_rows=sortrows(data_to_sort,'descend');
        dFFtraces_purged=zeros(length(dFFtime),16);
        for ii=1:16
            dFFtraces_purged(:,ii)=dFFtraces_t(:,sorted_rows(ii,2));
        end
        
        save([choiceFileName(1:end-19) '_dec_purged_' handles.bw_names{bwii} '.mat'],'dFFtraces_purged','decimated_LFP_logPtraces_t','dFFtime')
        
%               %Calculate PCs per timepoint
%         for ii_time=1:no_timepoints_dFF
%             
%             
%             these_ddFFtraces=zeros(1,no_traces_dFF);
%             these_ddFFtraces(1,:)=ddFFtraces(:,ii_time);
%             this_PCs_ddFF=[];
%             [coeff_logP,this_PCs_ddFF,latent_logP]=pca(these_ddFFtraces');
%              if ii_time==1
%                 PCs_ddFF=zeros(length(this_PCs_ddFF),no_timepoints_dFF);
%             end
%             PCs_ddFF(:,ii_time)=this_PCs_ddFF;
%         end
%         
%         PCs_ddFF=PCs_ddFF(:,PC_mask);
%         PC1_ddFF=PCs_ddFF(1,:);
%         
%         figNo=figNo+1;
%         try
%             close(figNo)
%         catch
%         end
%         hFig=figure(figNo);
%         set(hFig, 'units','normalized','position',[.05 .1 .85 .8])
%         
%         hold on
%         
%         
%         plot(PC1_ddFF,PC1_logP,'.k')
%         xlabel('PC1 for derivative of dFF')
%         ylabel('PC1 for logP')
%         title(['PC1 plot for ' handles.bw_names{bwii}])
%        
%         [rho,pval] = corr(PC1_dFF,PC1_logP);
%         
%         fprintf(1, ['\nFor file No %d ' handles.bw_names{bwii} 'PC1 dFF derivative vs PC1 logP rho= %d, p value= %d\n'],fileNo,rho, pval);
%         
        %Now add all derivatives
        
%         sumddFFtraces=sum(ddFFtraces,1);
%          sumddFFtraces=sumddFFtraces(1,PC_mask);
%          figNo=figNo+1;
%         try
%             close(figNo)
%         catch
%         end
%         hFig=figure(figNo);
%         set(hFig, 'units','normalized','position',[.05 .1 .85 .8])
%         
%         hold on
%         
%         
%         plot(sumddFFtraces,PC1_logP,'.k')
%         xlabel('Sum of derivatives fot dFF')
%         ylabel('PC1 for logP')
%         title(['PC1 plot for ' handles.bw_names{bwii}])
%        
%         [rho,pval] = corr(sumddFFtraces',PC1_logP);
%         
%         fprintf(1, ['\nFor file No %d ' handles.bw_names{bwii} 'sum of dFF derivatives vs PC1 logP rho= %d, p value= %d\n'],fileNo,rho, pval);
%         
    end
end

%Plot correlation histograms
edges=[-0.2:0.01:0.2];
for bwii=1:4
    figNo=figNo+1;
    try
        close(figNo)
    catch
    end
    hFig=figure(figNo);
    set(hFig, 'units','normalized','position',[.3 .3 .6 .3])
    
    pFDR(bwii)=drsFDRpval(pval_rho_dFF(rho_bwii==bwii));
    fprintf(1, ['\n\npFDR for rho p value for ' handles.bw_names{bwii}  ' = %d\n'],pFDR(bwii));
    
    subplot(1,2,1)
    hold on
    h1=histogram(rho_dFF(rho_bwii==bwii),edges)
    h2=histogram(rho_dFF((rho_bwii==bwii)&(pval_rho_dFF<pFDR(bwii))),edges)
    %         histogram(rho_dFF((rho_bwii==bwii)&(pval_rho_dFF>pFDR(bwii))))
    %         histogram(rho_dFF((rho_bwii==bwii)&(pval_rho_dFF<pFDR(bwii))))
    
    title('Original')
    xlabel('Rho')
    
    
    
    %Plot shuffled correlation histograms
    
    subplot(1,2,2)
    
    pFDRs(bwii)=drsFDRpval(pval_rhos_dFF(rhos_bwii==bwii));
    fprintf(1, ['\n\npFDR for shuffled rho p value for ' handles.bw_names{bwii}  ' = %d\n'],pFDR(bwii));
    
    hold on
    h1=histogram(rhos_dFF(rhos_bwii==bwii),edges)
    h2=histogram(rhos_dFF((rhos_bwii==bwii)&(pval_rhos_dFF<pFDRs(bwii))),edges)
    %         histogram(rho_dFF((rho_bwii==bwii)&(pval_rho_dFF>pFDR(bwii))))
    %         histogram(rho_dFF((rho_bwii==bwii)&(pval_rho_dFF<pFDR(bwii))))
    
    title('Shuffled')
    xlabel('Rho')
    
    suptitle(['Rho for dFF x LFP log P for ' handles.bw_names{bwii} ])
end


figNo=figNo+1;
try
    close(figNo)
catch
end
hFig=figure(figNo);
set(hFig, 'units','normalized','position',[.3 .3 .4 .4])

hold on

ii=0;
for bwii=1:4
    ii=ii+1;
    bar(ii,100*sum(pval_rho_dFF(rho_bwii==bwii)<pFDR(bwii))/sum(rho_bwii==bwii),'r')
     ii=ii+1;
    bar(ii,100*sum(pval_rhos_dFF(rhos_bwii==bwii)<pFDRs(bwii))/sum(rhos_bwii==bwii),'b')
    ii=ii+1;
end

xticks([1.5 4.5 7.5 10.5])
xticklabels({'Theta','Beta','Low gamma','High gamma'})
ylim([0 30])
ylabel('Percent significant rho')
title('Percent of significant correlations')
text(10,28,'Original','Color','red','FontSize',12)
text(10,26,'Shuffled','Color','blue','FontSize',12)

%Plot ddFF correlation histograms
edges=[-0.2:0.01:0.2];
for bwii=1:4
    figNo=figNo+1;
    try
        close(figNo)
    catch
    end
    hFig=figure(figNo);
    set(hFig, 'units','normalized','position',[.3 .3 .6 .3])
    
    pFDRddFF(bwii)=drsFDRpval(pval_rho_ddFF(rho_bwii==bwii));
    fprintf(1, ['\n\npFDR for rho p value for dFF derivative ' handles.bw_names{bwii}  ' = %d\n'],pFDR(bwii));
    
    subplot(1,2,1)
    hold on
    h1=histogram(rho_ddFF(rho_bwii==bwii),edges)
    h2=histogram(rho_ddFF((rho_bwii==bwii)&(pval_rho_ddFF<pFDR(bwii))),edges)
    %         histogram(rho_dFF((rho_bwii==bwii)&(pval_rho_dFF>pFDR(bwii))))
    %         histogram(rho_dFF((rho_bwii==bwii)&(pval_rho_dFF<pFDR(bwii))))
    
    title('dFF derivative')
    xlabel('Rho')
    
    %Plot shuffled correlation histograms
    
    subplot(1,2,2)
    
    pFDRsc(bwii)=drsFDRpval(pval_rhos_dFFc(rho_bwii==bwii));
    fprintf(1, ['\n\npFDR for convolved dFF rho p value for ' handles.bw_names{bwii}  ' = %d\n'],pFDR(bwii));
    
    hold on
    h1=histogram(rhos_dFF(rhos_bwii==bwii),edges)
    h2=histogram(rhos_dFF((rhos_bwii==bwii)&(pval_rhos_dFFc<pFDRs(bwii))),edges)
    %         histogram(rho_dFF((rho_bwii==bwii)&(pval_rho_dFF>pFDR(bwii))))
    %         histogram(rho_dFF((rho_bwii==bwii)&(pval_rho_dFF<pFDR(bwii))))
    
    title('Convolved dFF')
    xlabel('Rho')
    
    suptitle(['Rho for dFF x LFP log P for ' handles.bw_names{bwii} ])
end



pffft=1;