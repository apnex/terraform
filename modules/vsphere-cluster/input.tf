variable "cluster" {}

variable "aclusters" {
	default = [
		{
			name	= "cmp"
			nodes	= [
				"esx21.lab02.mel",
				"esx22.lab02.mel",
				"esx23.lab02.mel"
			],
			portgroups = {
				"pg-mgmt"	= 0,
				"pg-vmotion"	= 11,
				"pg-vsan" 	= 12
			}
		},
		{
			name	= "edge"
			nodes	= [
				"esx24.lab02.mel"
			],
			portgroups = {
				"pg-mgmt"	= 0,
				"pg-vmotion"	= 11,
				"pg-vsan" 	= 12
			}
		}
	]
}

variable "network_interfaces" {
	default = [
		"vmnic1"
	]
}
