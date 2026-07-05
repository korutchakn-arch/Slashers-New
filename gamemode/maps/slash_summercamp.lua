-- Utopia Games - Slashers
--
-- @Author: Garrus2142
-- @Date:   2017-08-09 13:41:40
-- @Last Modified by:   Garrus2142
-- @Last Modified time: 2017-08-09 13:41:40

local GM = GM or GAMEMODE

GM.MAP.Name = "Summercamp"
GM.MAP.EscapeDuration = 90
GM.MAP.StartMusic = "slashers_start_game_jason.wav"
GM.MAP.ChaseMusic = "slashers/ambient/chase_jason.wav"
GM.MAP.Goal = {
	Generator = {
		{type="sls_generator", pos=Vector( 	1678.174683, 5552.737305, 215.173004	 ), ang=Angle(	-0.483, 6.740, -0.121	),spw=false ,},
		{type="sls_generator", pos=Vector( 	-2755.215576, -1942.527344, 27.788239	 ), ang=Angle(	3.708, -36.244, -0.005	),spw=false,},
		{type="sls_generator", pos=Vector( 	6499.022461, -1667.111450, 11.305360	 ), ang=Angle(	0.297, 41.523, 0.176	),spw=false,},
	},

	Jerrican = {
		{type="sls_jerrican", pos=Vector( 	986.629150, 1900.260864, 275.224335	 ), ang=Angle(	-31.284, 3.741, -0.192	), spw = false,},
		{type="sls_jerrican", pos=Vector( 	132.203217, 1687.506958, 275.231934	 ), ang=Angle(	-0.148, -179.006, -0.115	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	-198.006714, 3428.893799, 275.202301	 ), ang=Angle(	0.577, -0.022, -0.115	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	1155.607666, 1691.713379, 275.225677	 ), ang=Angle(	0.472, -0.027, -0.093	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	835.292908, 3425.746338, 275.231995	 ), ang=Angle(	0.445, -0.027, -0.088	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	3954.628174, 3936.639893, 265.443634	 ), ang=Angle(	-0.236, -0.044, 0.401	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	1055.940552, 5541.725098, 275.162415	 ), ang=Angle(	0.066, 44.324, 0.000	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	-2709.210693, -1529.358643, 73.433403	 ), ang=Angle(	0.797, 0.000, -0.088	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	829.121765, 355.968048, 79.252518	 ), ang=Angle(	-0.352, 0.027, -0.071	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	-194.238800, 354.712860, 79.294006	 ), ang=Angle(	-0.170, 0.027, -0.033	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	-870.087891, -610.642456, 79.196129	 ), ang=Angle(	0.604, -0.022, -0.121	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	131.326981, -1380.994995, 79.235001	 ), ang=Angle(	0.434, -0.027, -0.082	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	1152.339355, -1376.056885, 79.235016	 ), ang=Angle(	0.428, -0.027, -0.082	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	-780.021362, -929.935791, 19.447821	 ), ang=Angle(	1.807, 56.799, 0.324	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	8045.914551, -1821.616089, 32.290798	 ), ang=Angle(	0.593, -39.265, 0.000	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	5475.315918, 3365.187500, 223.280289	 ), ang=Angle(	-0.747, 7.454, -0.005	),spw = false,},
		{type="sls_jerrican", pos=Vector( 	-792.936462, 5763.221191, 263.126678	 ), ang=Angle(	82.183, -179.995,169.547	),spw = false,},
	},

	Radio = {
		{type="sls_radio", pos=Vector( 	1226.423584, 5450.633301, 304.424774	 ), ang=Angle(	-0.137, -43.237, 0.044	),spw = false,},
		{type="sls_radio", pos=Vector( 	7130.218262, -1156.360596, 28.896412	 ), ang=Angle(	0.247, 14.738, -0.033	),spw = false,},
		{type="sls_radio", pos=Vector( 	4618.899902, -671.850220, 31.748055	 ), ang=Angle(	1.165, 101.294, 0.220	),spw = false,},
	}
}

