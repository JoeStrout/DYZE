toName = {}
toName[416] = "Zombie"
toName[417] = "Innkeeper"
toName[418] = "Builder"
toName[419] = "Blacksmith"
toName[420] = "Boy"
toName[421] = "Dancer"
toName[422] = "Farmer"
toName[423] = "Girl"
toName[424] = "Miner"
toName[425] = "OldLady"
toName[426] = "OldMan"
toName[427] = "VillagerFemale"
toName[430] = "FlameHole"
toName[443] = "CarPark"

get = function(index)
	if index == null or index < 416 or index > 450 then return null
	if not toName.hasIndex(index) then return null
	return toName[index]
end function

toIndex = {}
for kv in toName
	toIndex[kv.value] = kv.key
	globals[kv.value] = kv.key
end for

