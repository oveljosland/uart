/* requirements */
-- must support the UART protocol.
	-- 1 start bit.
	-- 8 data bits.
	-- 1 stop bit.
	-- no parity bits.
--x must support baud rate of at least 9600.
--x must be able to store at least one received byte.
--x must use 8x oversampling on the rx signal, and sample the middle of the
--x bit period to determine the value.
--x must indicate when data is received and ready to be used (data valid).
--x can do majority decision based on 5 samples in the middle of the bit period.
-- can have a 16 bit FIFO to store bytes, delete new data when full.
-- should support parity control (even, odd, none).
-- should be able to change baud rate when running.

/* TODO: everything */
