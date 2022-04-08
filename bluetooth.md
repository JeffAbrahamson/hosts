** [2022-04-08]

sudo systemctl status bluetooth
bluetoothctl scan on

  Discovery started
  [CHG] Controller 34:DE:1A:7D:5E:E6 Discovering: yes
  [NEW] Device 24:7F:20:DB:E2:87 LaBoxE281
  [NEW] Device 74:38:B7:48:E2:6F EOSR6_F1D065
  [NEW] Device 72:66:50:07:6C:0E LE-Bose Revolve SoundLink
  [NEW] Device 2C:41:A1:6D:2B:1C Bose Revolve SoundLink    <-- I want this.

	jeff@birdsong:~ $ bluetoothctl pair 2C:41:A1:6D:2B:1C
	Attempting to pair with 2C:41:A1:6D:2B:1C
	[CHG] Device 2C:41:A1:6D:2B:1C Connected: yes
	[CHG] Device 2C:41:A1:6D:2B:1C Paired: yes
	Pairing successful
	jeff@birdsong:~ $

    jeff@birdsong:~ $ bluetoothctl connect 2C:41:A1:6D:2B:1C
	Attempting to connect to 2C:41:A1:6D:2B:1C
	[CHG] Device 2C:41:A1:6D:2B:1C Connected: yes
	[CHG] Device 2C:41:A1:6D:2B:1C Paired: yes
	Connection successful
	jeff@birdsong:~ $

	jeff@birdsong:~ $ bluetoothctl trust 2C:41:A1:6D:2B:1C
	Changing 2C:41:A1:6D:2B:1C trust succeeded
	jeff@birdsong:~ $
