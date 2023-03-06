function [fig, limits, objs] = draw_setup(alpha)
% Draw table setup. Objects are structs with rectangle pos and color

exp = 2; % 0 for original experiment; 1 for scooping; 2 for simplified scooping

switch exp
    case 0 

        objs{1}.symbol = 'R'; % reach
        objs{2}.symbol = 'S'; % scoop
        objs{3}.symbol = 'T'; % transport
        objs{4}.symbol = 'C1'; % collision objs
        objs{5}.symbol = 'C2';
        objs{6}.symbol = 'C3';
        objs{7}.symbol = 'O'; % openning
        
        
        objs{1}.pos = [-4 -6 8 2];
        objs{2}.pos = [2 -4 2 8];
        objs{3}.pos = [2 4 2 2];
        objs{4}.pos = [-5 -6 1 2];
        objs{5}.pos = [4 -6 1 2];
        objs{6}.pos = [-5 -7 10 1];
        objs{7}.pos = [2 -4 2 8];
        
        
        objs{1}.color = [.5 .5 .5]; % dark grey
        objs{2}.color = [.8 .5 .5]; % salmon
        objs{3}.color = [.3 .8 .3]; % green
        objs{4}.color = [1. .8 .3]; % yellow
        objs{5}.color = [1. .8 .3]; % yellow
        objs{6}.color = [1. .8 .3]; % yellow
        % objs{7}.color = [.8 .8 .8]; % light grey
        objs{7}.color = [.8 .5 .5]; % salmon

    case 1

        objs{1}.symbol = 'R'; % reach
        objs{2}.symbol = 'S'; % scoop
        objs{3}.symbol = 'T'; % transport
        objs{4}.symbol = 'C1'; % collision objs
%         objs{5}.symbol = 'C2';
%         objs{6}.symbol = 'C3';
%         objs{7}.symbol = 'O'; % openning
        
        
        objs{1}.pos = [-8 -7 16 3];
        objs{2}.pos = [2 -4 4 10];
        objs{3}.pos = [2 6 4 2];
        objs{4}.pos = [-8 -8 16 1];
%         objs{5}.pos = [4 -6 1 2];
%         objs{6}.pos = [-5 -7 10 1];
%         objs{7}.pos = [2 -4 2 8];
        
        
        objs{4}.color = [.5 .5 .5]; % dark grey
        objs{2}.color = [.8 .5 .5]; % salmon
        objs{3}.color = [.3 .8 .3]; % green
        objs{1}.color = [1. .8 .3]; % yellow
%         objs{5}.color = [1. .8 .3]; % yellow
%         objs{6}.color = [1. .8 .3]; % yellow
%         objs{7}.color = [.8 .5 .5]; % salmon    

    case 2

        objs{1}.symbol = 'R'; % reach
        objs{2}.symbol = 'S'; % scoop
        objs{3}.symbol = 'T'; % transport
%         objs{4}.symbol = 'C1'; % collision objs

        objs{1}.pos = [-100 -100 200 96]; %[-8 -8 16 4];
        objs{2}.pos = [2 -8 4 14];
        objs{3}.pos = [2 6 4 2];
%         objs{4}.pos = [-8 -8 16 1];
        
%         objs{4}.color = [.5 .5 .5]; % dark grey
        objs{2}.color = [.8 .5 .5]; % salmon
        objs{3}.color = [.3 .8 .3]; % green
        objs{1}.color = [1. .8 .3]; % yellow

fig = figure('Color',[1 1 1]);
limits = [-8 8 -8 8];
axis(limits)
% axis("equal")
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.25, 0.55, 0.2646 0.4358]);
set(gca,'XTickLabel',[],'YTickLabel',[])
% xlabel('$x_1$','Interpreter','LaTex','FontSize',20);
% ylabel('$x_2$','Interpreter','LaTex','FontSize',20);
xlabel('x1');
ylabel('x2');
grid off

for i=1:length(objs)
    rectangle('Position', objs{i}.pos, 'FaceColor', [objs{i}.color alpha], 'EdgeColor', [objs{i}.color alpha]); hold on;
end

end

