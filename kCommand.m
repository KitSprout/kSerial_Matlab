% 
%       __            ____
%      / /__ _  __   / __/                      __  
%     / //_/(_)/ /_ / /  ___   ____ ___  __ __ / /_ 
%    / ,<  / // __/_\ \ / _ \ / __// _ \/ // // __/ 
%   /_/|_|/_/ \__//___// .__//_/   \___/\_,_/ \__/  
%                     /_/   github.com/KitSprout    
%  
%  @file    kCommand.m
%  @author  KitSprout
%  @brief   kserial protocol version v1.0
% 

classdef kCommand < handle

properties (SetAccess = private)
    s;

    KSCMD_R0_DEVICE_CHECK            = 0xD0;
	KSCMD_R2_TWI_SCAN_DEVICE         = 0xA1;
    KSCMD_R2_TWI_SCAN_REGISTER       = 0xA2;
    KSCMD_R3_DK_MODE                 = 0xAD;
    KSCMD_R3_DK_CONTINUOUS_READ      = 0xCC;
    KSCMD_R3_DK_STEP_MOTOR           = 0xEE;
    KSCMD_R3_DK_STEP_MOTOR_THRESHOLD = 0xEA;
end

methods

    function kcmd = kCommand( varargin )
        switch nargin
            case 1
                kcmd.s = varargin{1};
            otherwise
                error('input error!!');
        end
    end

    function delay( kcmd, second )
        kcmd.s.delay(second);
    end

    % id = kcmd.getid()
    function varargout = getid( kcmd )
        ri = kcmd.s.packetSendRecv([kcmd.KSCMD_R0_DEVICE_CHECK, 0x00], 'R0');
        id = dec2hex(ri(4)*256+ ri(3));
        varargout = { id };
    end

    % id = kcmd.set_mode(mode)
    function set_mode( kcmd, mode )
        kcmd.s.packetSendRecv([kcmd.KSCMD_R3_DK_MODE, mode], 'R3');
    end

    % id = kcmd.set_continuous_read()
    function set_continuous_read( kcmd )
        kcmd.s.packetSendRecv([kcmd.KSCMD_R3_DK_CONTINUOUS_READ, 0x00], 'R3');
    end

    % [rd, cnt] = kcmd.read(address, register, lenght)
    function varargout = read( kcmd, address, register, lenght, timeout )
        if (nargin < 5)
            timeout = 1000;
        end
        kcmd.s.packetSend(uint8([address*2+1, register]), lenght, 'R1');

        count = 0;
        ri = [];
        while isempty(ri) && count < timeout
            [ri, rd] = kcmd.s.packetRecv();
            count = count + 1;
        end

        if count >= timeout
            count = -1;
        end

        varargout = { rd, count };
    end

    % [wi, wb] = kcmd.write(address, register, data)
    function varargout = write( kcmd, address, register, data )
        [info, send] = kcmd.s.packetSend(uint8([address*2, register]), data, 'R1');
        varargout = { info, send };
    end

    % address = kcmd.scandevice()
    % address = kcmd.scandevice('printon')
    function varargout = scandevice( kcmd, varargin )
        [ri, rd] = kcmd.s.packetSendRecv([kcmd.KSCMD_R2_TWI_SCAN_DEVICE, 0], 0, 'R2');

        if (nargin == 2)
            if strcmp('printon', varargin{end})
                fprintf('\n');
                fprintf(' >> i2c device list (found %d device)\n\n', size(rd, 1));
                fprintf('    ');
                for i = 1 : size(rd, 1)
                    fprintf(' %02X', rd(i));
                end
                fprintf('\n\n');
            end
        end
        
        varargout = { rd, ri };
    end

    % reg = kcmd.scanregister(address)
    % reg = kcmd.scanregister(address, 'printon')
    function varargout = scanregister( kcmd, address, varargin )
        [ri, rd] = kcmd.s.packetSendRecv([kcmd.KSCMD_R2_TWI_SCAN_REGISTER, address*2], 0, 'R2');

        if (nargin == 2)
            if strcmp('printon', varargin{end})
                fprintf('\n');
                fprintf(' >> i2c device register (address %02X)\n\n', address);
                fprintf('      0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F\n');
                for i = 1 : 16 :256
                    fprintf(' %02X: %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X\n', ...
                    i-1, rd(i:i+16-1));
                end
                fprintf('\n');
            end
        end

        varargout = { rd, ri };
    end

end

methods (Access = private)

end

end
