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

    KSCMD_R0_DEVICE_ID               = 0xD0;
    KSCMD_R0_DEVICE_BAUDRATE         = 0xD1;
    KSCMD_R0_DEVICE_RATE             = 0xD2;
    KSCMD_R0_DEVICE_MDOE             = 0xD3;
    KSCMD_R0_DEVICE_GET              = 0xE3;
	KSCMD_R2_TWI_SCAN_DEVICE         = 0xA1;
    KSCMD_R2_TWI_SCAN_REGISTER       = 0xA2;
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

    % id = kcmd.check_device()
    function varargout = check_device( kcmd )
        ri = kcmd.s.packetSendRecv([kcmd.KSCMD_R0_DEVICE_ID, 0x00], 'R0');
        id = dec2hex(ri(4)*256+ ri(3));
        varargout = { id };
    end

    % info = kcmd.get_info(cmd)
    function varargout = get_info( kcmd, cmd )
        [~, rd] = kcmd.s.packetSendRecv([kcmd.KSCMD_R0_DEVICE_GET, cmd], 'R0');
        varargout = { typecast(uint8(rd), 'int32') };
    end

    % id = kcmd.get_id()
    function varargout = get_id( kcmd )
        varargout = { dec2hex(kcmd.get_info(kcmd.KSCMD_R0_DEVICE_ID)) };
    end

    % baudrate = kcmd.get_baudrate()
    function varargout = get_baudrate( kcmd )
        varargout = { kcmd.get_info(kcmd.KSCMD_R0_DEVICE_BAUDRATE) };
    end

    % rate = kcmd.get_rate()
    function varargout = get_rate( kcmd )
        varargout = { kcmd.get_info(kcmd.KSCMD_R0_DEVICE_RATE) };
    end

    % mode = kcmd.get_mode()
    function varargout = get_mode( kcmd )
        varargout = { kcmd.get_info(kcmd.KSCMD_R0_DEVICE_MDOE) };
    end

    % kcmd.set_baudrate(baudrate)
    function set_baudrate( kcmd, baudrate )
        baudrate = typecast(int32(baudrate), 'uint8');
        kcmd.s.packetSendRecv([kcmd.KSCMD_R0_DEVICE_BAUDRATE, 4], baudrate, 'R0');
    end

    % kcmd.set_rate(rate)
    function set_rate( kcmd, rate )
        rate = typecast(int32(rate), 'uint8');
        kcmd.s.packetSendRecv([kcmd.KSCMD_R0_DEVICE_RATE, 4], rate, 'R0');
    end

    % kcmd.set_mode(mode)
    function set_mode( kcmd, mode )
        kcmd.s.packetSendRecv([kcmd.KSCMD_R0_DEVICE_MDOE, mode], 'R0');
    end

    % kcmd.set_normal_mode()
    function set_normal_mode( kcmd )
        kcmd.set_mode(0);
    end

    % kcmd.set_kserial_mode()
    function set_kserial_mode( kcmd )
        kcmd.set_mode(1);
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

        if (nargin == 3)
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
