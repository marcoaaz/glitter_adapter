function delay_slider(alignData, sliderWidth)

x = alignData.x; %spectra records a longer time
y = alignData.y;
x_laser1 = alignData.x_laser;
y_laser1 = alignData.y_laser;

% Create figure window and components
hFig = uifigure;
hFig.Name = 'My App';
ax = uiaxes(hFig, 'Position', [20 80 1250 300]);
hFig.Position = [100, 200, 1300, 400];

% Update value
sld = uislider(hFig, ...
    'ValueChangingFcn',@(sld, event) sliderMoving(event, ax, x_laser1));
sld.Position(1:3) = [50 50 1150];
sld.Limits = [-sliderWidth/4, sliderWidth/4];
sld.Value = 0; %default

hold(ax, "on")
plot(ax, x_laser1, y_laser1);
plot(ax, x, y);
hold(ax, "off")
ax.XLim = [0 seconds(sliderWidth)];
ax.Title.String = 'Laser log alignment';
ax.Title.FontWeight = 'normal';

end

% Create ValueChangedFcn callback
function sliderMoving(sld, ax, x_laser1)

    x_temp = x_laser1 + seconds(sld.Value);
    ax.Children(2, 1).XData = x_temp;
    
    assignin('base', 'sliderValue', sld.Value)

end