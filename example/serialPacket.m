clc, clear, close all;
addpath('../.')

s = kSerial(115200, 'clear');
s.setRecvThreshold(0);
s.setRecordBufferSize(32*1024);
s.setRecordExpandSize(1024);
s.setCustomizeDataSize(0);
s.setPacketObserverWeighting(0.6);
s.setPacketObserverTimeunit(0.001);
s.setPacketObserverTimeindex(1:2);
s.open();

kcmd = kCommand(s);
kcmd.set_rate(200);
kcmd.set_kserial_mode();
while s.ks.lens < 2000
    [packetInfo, packetData, packetLens] = s.packetRecv('record');
    if packetLens > 0
        [freq, tims] = s.packetObserver();
        yglsb = packetData(3:5, end);
        yalsb = packetData(6:8, end);
        ymlsb = packetData(9:11, end);
        ytlsb = packetData(12, end);
        yg = yglsb / 16.4 * pi / 180;   % rad/s
        ya = yalsb / 8192 * 9.81;       % m/s^2
        ym = ymlsb / 6.6;               % uT
        yt = ytlsb / 132.48 + 25;       % degC
        fprintf('[%03d]', packetLens);
        fprintf('[%02i:%02i:%02i]', tims(2), tims(3), fix(tims(4) / 10));
        fprintf('[%4dHz]', freq);
        fprintf(' ');
        fprintf('[G] %7.3f %7.3f %7.3f ', yg);
        fprintf('[A] %7.3f %7.3f %7.3f ', ya);
        fprintf('[M] %7.2f %7.2f %7.2f ', ym);
        fprintf('[T] %.2f', yt);
        fprintf('\n');
    end
end
kcmd.set_normal_mode();
s.close();

% {
% check packet
[rate, lost, dc, type] = s.getPacketLostRate();
if lost == 0
    fprintf('\n---- [%05.2f%%] No packet loss ( %i / %i ) ----\n', rate * 100, lost, s.ks.lens);
else
    fprintf('\n---- [%05.2f%%] Packet loss ( %i / %i ) ----\n', rate * 100, lost, s.ks.lens);
end
% plot(1 : s.ks.lens - 1, dc)
%}
%{
filename = s.save2mat('log/rawdata', sv);
%}
