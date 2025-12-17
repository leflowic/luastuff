USING "globals.sch"
USING "commands_network.sch"
USING "commands_debug.sch"
USING "commands_script.sch"
USING "script_player.sch"
USING "commands_lobby.sch"
USING "script_network.sch"
USING "net_prints.sch"
USING "script_maths.sch" 
USING "net_mission_info.sch"
USING "net_script_timers.sch"
USING "net_team_info.sch"
USING "Net_Script_Launcher.sch"
USING "commands_socialclub.sch"
USING "net_transition_sessions_private.sch"
USING "scriptsaves_procs.sch"
USING "commands_hud.sch"

USING "freemode_events_header_private.sch"

USING "net_stat_system.sch"
USING "net_gang_boss_common.sch"

#IF IS_DEBUG_BUILD
	USING "net_bots.sch"
#ENDIF

USING "net_simple_interior_common.sch"
USING "net_combined_models.sch"

#IF FEATURE_HEIST_ISLAND
USING "net_peds_vars.sch"
USING "net_club_music_vars.sch"
USING "warp_transition_globals.sch"
#ENDIF

#IF IS_DEBUG_BUILD
	BOOL bPrintEventQueue //= TRUE
	BOOL bSendTestScriptEvent
	INT iTestScriptEventType
	INT iTestScriptEventData
#ENDIF

// Needed for the Clear before corona vehicle data script event.
PROC RESET_CORONA_VEHICLE_WORLD_CHECK_DATA()
	
	STRUCT_CORONA_VEHICLE_WORLD_CHECK_DATA sTemp
	g_structCoronaVehicleWorldCheck = sTemp
	
ENDPROC

PROC RESET_BEFORE_CORONA_VEHICLE_DATA()
	
	IF NETWORK_DOES_NETWORK_ID_EXIST(g_TransitionSessionNonResetVars.niCoronaLastVehicle)
		SET_NETWORK_ID_ALWAYS_EXISTS_FOR_PLAYER(g_TransitionSessionNonResetVars.niCoronaLastVehicle, PLAYER_ID(), FALSE)
	ENDIF
	
	VEHICLE_SETUP_STRUCT_MP sTemp
	
	g_TransitionSessionNonResetVars.iSaveBeforeCoronaVehicleStage				= 0
	g_TransitionSessionNonResetVars.bSaveBeforeCoronaVehicle					= FALSE
	g_TransitionSessionNonResetVars.sLastVehAfterJobData						= sTemp
	g_TransitionSessionNonResetVars.bSavedLastVehBeforeJob						= FALSE
	g_TransitionSessionNonResetVars.bCreateLastVehBeforeCoronaForSameSession	= FALSE
	g_TransitionSessionNonResetVars.iCreateLastVehBeforeCoronaStage				= 0
	g_TransitionSessionNonResetVars.vLastVehicleBeforeCoronaSavePosition 		= <<0.0,0.0,0.0>>
	g_TransitionSessionNonResetVars.fLastVehicleBeforeCoronaSaveHeading			= 0.0
	g_TransitionSessionNonResetVars.niBeforeCoronaVeh							= NULL
	g_TransitionSessionNonResetVars.niCoronaLastVehicle							= NULL
	g_TransitionSessionNonResetVars.bIsPegasusVeh							= FALSE
	RESET_NET_TIMER(g_TransitionSessionNonResetVars.stMarkLastVehilceBeforeCoronaAsnoLongerNeededTimer)
	RESET_NET_TIMER(g_TransitionSessionNonResetVars.stSaveBeforeCoronaVehTimeout)
	
	CLEAR_BIT(g_TransitionSessionNonResetVars.iRestoreLastVehicleBitset, TRAN_SESS_NON_RESET_LAST_VEHICLE_NEED_PEGASUS_SPAWN)
	CLEAR_BIT(g_TransitionSessionNonResetVars.iRestoreLastVehicleBitset, TRAN_SESS_NON_RESET_LAST_VEHICLE_PEGASUS_SPAWN_SUCCESS)
	CLEAR_BIT(g_TransitionSessionNonResetVars.iRestoreLastVehicleBitset, TRAN_SESS_NON_RESET_LAST_VEHICLE_PEGASUS_SPAWN_FAIL)
	
	IF (g_TransitionSessionNonResetVars.sLastVehAfterJobData.VehicleSetup.eModel != DUMMY_MODEL_FOR_SCRIPT)
		SET_MODEL_AS_NO_LONGER_NEEDED(g_TransitionSessionNonResetVars.sLastVehAfterJobData.VehicleSetup.eModel)
	ENDIF
	
	RESET_CORONA_VEHICLE_WORLD_CHECK_DATA()
	
	PRINTLN("[WJK] - before corona vehicle - RESET_BEFORE_CORONA_VEHICLE_DATA been called.")
	
ENDPROC



//╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
//║																														║
//║		Handy functions for setting player flags (each bit represents a global player 0 - 31)			  				║
//║																										  				║
//╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝	
FUNC BOOL IS_PLAYER_LOCAL(PLAYER_INDEX aPlayer)

	IF aPlayer = PLAYER_ID()
		RETURN TRUE
	ENDIF

	RETURN FALSE
ENDFUNC

FUNC NETWORK_CLAN_DESC CHECK_PLAYER_CREW(PLAYER_INDEX aPlayer)

	IF IS_PLAYER_LOCAL(aPlayer)
		RETURN g_Private_PlayerCrewData[NATIVE_TO_INT(PLAYER_ID())]
	ENDIF
	
	
	g_GamerHandle = GET_GAMER_HANDLE_PLAYER(aPlayer)
	//NETWORK_CLAN_DESC retDesc
	
	NETWORK_CLAN_PLAYER_GET_DESC( g_TempClanDescription, 0, g_GamerHandle)
	
	RETURN g_TempClanDescription
ENDFUNC
		
// PURPOSE: returns an int with bits set to all the active players	
FUNC INT ALL_PLAYERS(BOOL bIncludeSendingPlayer = TRUE, BOOL includeSpectators = TRUE)
	INT iPlayerFlags
	INT iPlayer 
	REPEAT NUM_NETWORK_PLAYERS iPlayer
		PLAYER_INDEX playerId = INT_TO_PLAYERINDEX(iPlayer)
		IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
			#IF IS_DEBUG_BUILD 
			IF (PlayerId = PLAYER_ID())
				//NET_PRINT("ALL_PLAYERS() - sending to self, player = ") NET_PRINT_INT(iPlayer) NET_NL()
			ENDIF
			#ENDIF
		
			IF (PlayerId <> PLAYER_ID())
			OR (bIncludeSendingPlayer)
				//IF includeCheaters
					IF includeSpectators
						//NET_PRINT("ALL_PLAYERS() - sending to player = ") NET_PRINT_INT(iPlayer) NET_NL()
						SET_BIT( iPlayerFlags , iPlayer)
					ELSE
						IF NOT IS_PLAYER_SCTV(PlayerId)
							SET_BIT( iPlayerFlags , iPlayer)
						ENDIF
					ENDIF
//				ELSE
//					IF NOT NETWORK_PLAYER_INDEX_IS_CHEATER(playerId)
//						IF includeSpectators
//							//NET_PRINT("ALL_PLAYERS() - sending to player = ") NET_PRINT_INT(iPlayer) NET_NL()
//							SET_BIT( iPlayerFlags , iPlayer)
//						ELSE
//							IF NOT IS_PLAYER_SCTV(PlayerId)
//								SET_BIT( iPlayerFlags , iPlayer)
//							ENDIF
//						ENDIF
//					ENDIF
//				ENDIF
			ENDIF
			
		ENDIF
	ENDREPEAT

	#IF IS_DEBUG_BUILD
		NET_PRINT("           ALL_PLAYERS() - iPlayerFlags = ")
		PRINTLN(iPlayerFlags)
		NET_NL()
	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC

FUNC INT ALL_PLAYERS_IN_MY_TRANSITION_SESSION(BOOL bIncludeSendingPlayer = TRUE, BOOL includeSpectators = TRUE)
	INT iPlayerFlags
	INT iPlayer 
	GAMER_HANDLE playerHandle
	REPEAT NUM_NETWORK_PLAYERS iPlayer
		PLAYER_INDEX playerId = INT_TO_PLAYERINDEX(iPlayer)
		IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
			playerHandle = GET_GAMER_HANDLE_PLAYER(playerID)
			IF IS_THIS_GAMER_HANDLE_IN_MY_TRANSITION_SESSION(playerHandle)
				IF (PlayerId <> PLAYER_ID())
				OR (bIncludeSendingPlayer)
					IF includeSpectators
						SET_BIT( iPlayerFlags , iPlayer)
					ELSE
						IF NOT IS_PLAYER_SCTV(PlayerId)
							SET_BIT( iPlayerFlags , iPlayer)
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		ENDIF
	ENDREPEAT

	#IF IS_DEBUG_BUILD
		NET_PRINT("           ALL_PLAYERS_IN_MY_TRANSITION_SESSION() - iPlayerFlags = ")
		PRINTLN(iPlayerFlags)
		NET_NL()
	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC

FUNC INT SPECIFIC_PLAYER(PLAYER_INDEX PlayerID)
	INT iPlayerFlags
	IF NATIVE_TO_INT(PlayerID) != -1
		SET_BIT( iPlayerFlags , NATIVE_TO_INT(PlayerID))
	ENDIF
	
	#IF IS_DEBUG_BUILD
		NET_PRINT("           SPECIFIC_PLAYER() - PlayerID = ")
		NET_PRINT_INT(NATIVE_TO_INT(PlayerID))
		NET_PRINT(" iPlayerFlags = ")
		NET_PRINT_INT(iPlayerFlags)
		NET_PRINT("  [")
		IF (IS_NET_PLAYER_OK(PlayerID, FALSE))
			NET_PRINT(GET_PLAYER_NAME(PlayerID))
		ELSE
			NET_PRINT("NOTE: Net Player is NOT OK")
		ENDIF
		NET_PRINT("]")
		NET_NL()
	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC

// PURPOSE: returns an int with bits set to all the active players in a particular team
FUNC INT ALL_PLAYERS_IN_TEAM(INT iTeam, BOOL bIncludeSendingPlayer = TRUE)
	INT iPlayerFlags
	INT iPlayer 
	REPEAT NUM_NETWORK_PLAYERS iPlayer
		PLAYER_INDEX playerId = INT_TO_PLAYERINDEX(iPlayer)
		IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
			IF (GET_PLAYER_TEAM(PlayerId) = iTeam)		
				IF (PlayerId <> PLAYER_ID())
				OR (bIncludeSendingPlayer)
					SET_BIT( iPlayerFlags , iPlayer)
				ENDIF
			ENDIF
		ENDIF
	ENDREPEAT
	
	#IF IS_DEBUG_BUILD
		NET_PRINT("           ALL_PLAYERS_IN_TEAM() - iPlayerFlags = ")
		NET_PRINT_INT(iPlayerFlags)
		NET_NL()
	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC

// PURPOSE: returns an int with bits set to all the active players in range
FUNC INT ALL_PLAYERS_IN_RANGE(INT iRange, BOOL bIncludeSendingPlayer = TRUE)
	INT iPlayerFlags
	INT iPlayer 
	REPEAT NUM_NETWORK_PLAYERS iPlayer
		PLAYER_INDEX playerId = INT_TO_PLAYERINDEX(iPlayer)
		IF IS_NET_PLAYER_OK(playerId)
		AND IS_NET_PLAYER_OK(PLAYER_ID())
			IF (PlayerId <> PLAYER_ID())
			OR (bIncludeSendingPlayer)
				IF GET_DISTANCE_BETWEEN_COORDS(GET_ENTITY_COORDS(GET_PLAYER_PED(playerId)),GET_ENTITY_COORDS(GET_PLAYER_PED(PLAYER_ID()))) <= iRange
					SET_BIT( iPlayerFlags , iPlayer)
				ENDIF
			ENDIF
		ENDIF
	ENDREPEAT
	
	#IF IS_DEBUG_BUILD
		NET_PRINT("           ALL_PLAYERS_IN_RANGE - iPlayerFlags = ")
		NET_PRINT_INT(iPlayerFlags)
		NET_NL()
	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC

// PURPOSE: returns an int with bits set to all the active players in range
FUNC INT ALL_PLAYERS_IN_RANGE_OF_POINT(VECTOR vPoint, INT iRange, BOOL bIncludeSendingPlayer = TRUE)
	INT iPlayerFlags
	INT iPlayer 
	REPEAT NUM_NETWORK_PLAYERS iPlayer
		PLAYER_INDEX playerId = INT_TO_PLAYERINDEX(iPlayer)
		IF IS_NET_PLAYER_OK(playerId)
		AND IS_NET_PLAYER_OK(PLAYER_ID())
			IF (PlayerId <> PLAYER_ID())
			OR (bIncludeSendingPlayer)
				IF GET_DISTANCE_BETWEEN_COORDS(GET_ENTITY_COORDS(GET_PLAYER_PED(playerId)), vPoint) <= iRange
					SET_BIT( iPlayerFlags , iPlayer)
				ENDIF
			ENDIF
		ENDIF
	ENDREPEAT
	
	PRINTLN("           ALL_PLAYERS_IN_RANGE_OF_POINT - iRange = ", iRange, " iPlayerFlags = ", iPlayerFlags)
	
	RETURN(iPlayerFlags)
ENDFUNC

FUNC BOOL PLAYERS_IN_RANGE_IS_SPECTATOR_WRAPPER(PLAYER_INDEX playerID)
	IF PLAYER_ID() = playerID
//		#IF USE_TU_CHANGES
			RETURN IS_BIT_SET(MPSpecGlobals.iBitSet, GLOBAL_SPEC_BS_ACTIVE)
//		#ENDIF
//		
//		//Must not be changed. -BenR
//		#IF NOT USE_TU_CHANGES
//			RETURN IS_BIT_SET(MPSpecGlobals_OLD.iBitSet, GLOBAL_SPEC_BS_ACTIVE)
//		#ENDIF
	ENDIF
	IF IS_PLAYER_SCTV(playerID)
		RETURN(TRUE)
	ENDIF
	IF IS_BIT_SET(GlobalplayerBD[NATIVE_TO_INT(playerID)].iSpecInfoBitset, SPEC_INFO_BS_SPECTATOR_CAM_IS_RUNNING)
		RETURN(TRUE)
	ENDIF
	RETURN FALSE
ENDFUNC

// PURPOSE: returns an int with bits set to the active players near a point
FUNC INT PLAYERS_IN_RANGE_OF_POINT(VECTOR vCoords,INT iRange,BOOL bAllPlayers,BOOL bFriends = FALSE, BOOL bCrew = FALSE,BOOL bIncludeSendingPlayer = FALSE, BOOL bIncludeSpectators = FALSE, BOOL bOrganisation = FALSE, BOOL bSkipInVehiclePlayers = FALSE )
	INT iPlayerFlags
	INT iPlayer 
	//GAMER_HANDLE tempHandle 
	//NETWORK_CLAN_DESC myClan 
	//NETWORK_CLAN_DESC otherClan 
	IF bCrew
		g_ClanDescription = CHECK_PLAYER_CREW(PLAYER_ID()) 
	ENDIF
	
	#IF IS_DEBUG_BUILD
	VECTOR vTemp 
	#ENDIF
	REPEAT NUM_NETWORK_PLAYERS iPlayer
		PLAYER_INDEX playerId = INT_TO_PLAYERINDEX(iPlayer)
		IF IS_NET_PLAYER_OK(playerId)
			IF bIncludeSpectators 
			OR NOT PLAYERS_IN_RANGE_IS_SPECTATOR_WRAPPER(playerId)
				IF (PlayerId <> PLAYER_ID())
				OR (bIncludeSendingPlayer)
					#IF IS_DEBUG_BUILD
						vTemp = GET_ENTITY_COORDS(GET_PLAYER_PED(playerId))
						PRINTLN("PLAYERS_IN_RANGE_OF_POINT: NAME: ", GET_PLAYER_NAME(playerId)," current LOC: ",vTemp, " testing location: ",vCoords)
					#ENDIF
					IF GET_DISTANCE_BETWEEN_COORDS(GET_ENTITY_COORDS(GET_PLAYER_PED(playerId)),vCoords) <= iRange
						IF bSkipInVehiclePlayers
						AND IS_PED_IN_ANY_VEHICLE(GET_PLAYER_PED(playerId))
							PRINTLN("PLAYERS_IN_RANGE_OF_POINT- skipping in vehicle player ", GET_PLAYER_NAME(playerId))
						ELSE
							IF bAllPlayers
								SET_BIT( iPlayerFlags , iPlayer)
								PRINTLN("PLAYERS_IN_RANGE_OF_POINT- bAllPlayers- ", GET_PLAYER_NAME(playerId))
							ELSE
								g_GamerHandle = GET_GAMER_HANDLE_PLAYER(playerID) 
								IF IS_GAMER_HANDLE_VALID(g_GamerHandle) 
									IF bFriends
										PRINTLN("PLAYERS_IN_RANGE_OF_POINT- checking friend")
										 IF NETWORK_IS_FRIEND(g_GamerHandle) 
											SET_BIT(iPlayerFlags , NATIVE_TO_INT(PlayerID))
											PRINTLN("PLAYERS_IN_RANGE_OF_POINT- friend- ", GET_PLAYER_NAME(playerId))
										ENDIF
									ENDIF
									IF bCrew
									AND NOT IS_BIT_SET(iPlayerFlags , NATIVE_TO_INT(PlayerID))
										g_otherClanDescription = CHECK_PLAYER_CREW(PlayerId) 
										PRINTLN("PLAYERS_IN_RANGE_OF_POINT crew local ID = ", g_ClanDescription.Id," name = ",g_ClanDescription.ClanName," crew player = ",g_otherClanDescription.Id," name = ",g_otherClanDescription.ClanName)
										IF g_ClanDescription.Id = g_otherClanDescription.Id
											SET_BIT(iPlayerFlags , NATIVE_TO_INT(PlayerID))
											PRINTLN("PLAYERS_IN_RANGE_OF_POINT- crew- ", GET_PLAYER_NAME(playerId))
										ENDIF
									ENDIF
									IF bOrganisation
									AND NOT IS_BIT_SET(iPlayerFlags , NATIVE_TO_INT(PlayerID))
										PRINTLN("PLAYERS_IN_RANGE_OF_POINT- checking organisation")
										IF GlobalplayerBD_FM_3[NATIVE_TO_INT(PlayerId)].sMagnateGangBossData.GangBossID != INVALID_PLAYER_INDEX()
										AND GlobalplayerBD_FM_3[NATIVE_TO_INT(PlayerId)].sMagnateGangBossData.GangBossID = GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].sMagnateGangBossData.GangBossID
											SET_BIT(iPlayerFlags , NATIVE_TO_INT(PlayerID))
											PRINTLN("PLAYERS_IN_RANGE_OF_POINT- organisation- ", GET_PLAYER_NAME(playerId))
										ENDIF	
									ENDIF
								ELSE
									PRINTLN("PLAYERS_IN_RANGE_OF_POINT- invalid gamer handle- ", GET_PLAYER_NAME(playerId))
								ENDIF
							ENDIF
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		ENDIF
	ENDREPEAT
	#IF IS_DEBUG_BUILD
		PRINTLN(" PLAYERS_IN_RANGE_OF_POINT ",vCoords," - iPlayerFlags = ",iPlayerFlags)
	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC


// PURPOSE: returns an int with bits set to all the active players in a particular team
FUNC INT ALL_PLAYERS_IN_TEAM_IN_RANGE(INT iTeam,INT iRange, BOOL bIncludeSendingPlayer = TRUE)
	INT iPlayerFlags
	INT iPlayer 
	REPEAT NUM_NETWORK_PLAYERS iPlayer
		PLAYER_INDEX playerId = INT_TO_PLAYERINDEX(iPlayer)
		IF IS_NET_PLAYER_OK(playerId)
		AND IS_NET_PLAYER_OK(PLAYER_ID())
			IF (GET_PLAYER_TEAM(PlayerId) = iTeam)		
				IF (PlayerId <> PLAYER_ID())
				OR (bIncludeSendingPlayer)
					IF GET_DISTANCE_BETWEEN_COORDS(GET_ENTITY_COORDS(GET_PLAYER_PED(playerId)),GET_ENTITY_COORDS(GET_PLAYER_PED(PLAYER_ID()))) <= iRange
						SET_BIT( iPlayerFlags , iPlayer)
					ENDIF
				ENDIF
			ENDIF
		ENDIF
	ENDREPEAT
	
	#IF IS_DEBUG_BUILD
		NET_PRINT("           ALL_PLAYERS_IN_TEAM_IN_RANGE - iPlayerFlags = ")
		NET_PRINT_INT(iPlayerFlags)
		NET_NL()
	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC

// PURPOSE: returns an int with bits set to all the active players in particular teams
FUNC INT ALL_PLAYERS_IN_TEAMS(INT &iTeams[],BOOL bIncludeSendingPlayer = TRUE)
	INT iPlayerFlags
	INT iPlayer 
	INT i
	REPEAT NUM_NETWORK_PLAYERS iPlayer
		PLAYER_INDEX playerId = INT_TO_PLAYERINDEX(iPlayer)
		IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
		
			REPEAT COUNT_OF(iTeams) i
				IF NOT (iTeams[i] = -1)
					IF (GET_PLAYER_TEAM(PlayerID) = iTeams[i])
						IF (PlayerId <> PLAYER_ID())
						OR (bIncludeSendingPlayer)
							SET_BIT( iPlayerFlags , iPlayer)
						ENDIF		
					ENDIF
				ENDIF
			ENDREPEAT
	
		ENDIF
	ENDREPEAT
	
	#IF IS_DEBUG_BUILD
		NET_PRINT("           ALL_PLAYERS_IN_TEAMS() - iPlayerFlags = ")
		NET_PRINT_INT(iPlayerFlags)
		NET_NL()
	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC

// PURPOSE: returns an int with bits set to all the active cops
FUNC INT ALL_COPS(BOOL bIncludeSendingPlayer = TRUE)
	RETURN(ALL_PLAYERS_IN_TEAM(0, bIncludeSendingPlayer))	
ENDFUNC

// PURPOSE: returns an int with bits set to all the active criminals
FUNC INT ALL_CRIMINALS(BOOL bIncludeSendingPlayer = TRUE)
	INT iPlayerFlags
	INT iPlayer 
	REPEAT NUM_NETWORK_PLAYERS iPlayer
		PLAYER_INDEX playerId = INT_TO_PLAYERINDEX(iPlayer)
		IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
			IF (GET_PLAYER_TEAM(PlayerId) > 0)		
				IF (PlayerId <> PLAYER_ID())
				OR (bIncludeSendingPlayer)
					SET_BIT( iPlayerFlags , iPlayer)
				ENDIF
			ENDIF
		ENDIF
	ENDREPEAT
	
	#IF IS_DEBUG_BUILD
		NET_PRINT("           ALL_CRIMINALS() - iPlayerFlags = ")
		NET_PRINT_INT(iPlayerFlags)
		NET_NL()
	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC

FUNC INT ALL_PLAYERS_IN_VEHICLE(VEHICLE_INDEX vehID, BOOL bIncludeSendingPlayer = TRUE, BOOL bOnlyIncludePlayersOnMyTeam = FALSE, BOOL ConsiderEnteringAsInVehicle = FALSE)
	INT iPlayerFlags
	INT iPlayer 
	VEHICLE_INDEX playerVeh
	REPEAT NUM_NETWORK_PLAYERS iPlayer
		PLAYER_INDEX playerId = INT_TO_PLAYERINDEX(iPlayer)
		IF IS_NET_PLAYER_OK(playerId, TRUE, FALSE)
			IF IS_PED_IN_ANY_VEHICLE(GET_PLAYER_PED(playerID), ConsiderEnteringAsInVehicle)
				IF NOT IS_REMOTE_PLAYER_IN_NON_CLONED_VEHICLE(playerID)
					playerVeh = GET_VEHICLE_PED_IS_IN(GET_PLAYER_PED(playerID), ConsiderEnteringAsInVehicle)
					IF playerVeh = vehID	
						IF GET_PLAYER_TEAM(playerId) = GET_PLAYER_TEAM(PLAYER_ID())
						OR NOT bOnlyIncludePlayersOnMyTeam
							IF (PlayerId <> PLAYER_ID())
							OR (bIncludeSendingPlayer)
								SET_BIT( iPlayerFlags , iPlayer)
							ENDIF
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		ENDIF
	ENDREPEAT
	
//	#IF IS_DEBUG_BUILD
//		NET_PRINT("           ALL_PLAYERS_IN_VEHICLE() - iPlayerFlags = ")
//		NET_PRINT_INT(iPlayerFlags)
//		NET_NL()
//	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC

FUNC INT ALL_PLAYERS_NOT_IN_VEHICLE(VEHICLE_INDEX vehID, BOOL bIncludeSendingPlayer = TRUE, BOOL bOnlyIncludePlayersOnMyTeam = FALSE)
	INT iPlayerFlags
	INT iPlayer 

	REPEAT NUM_NETWORK_PLAYERS iPlayer
		PLAYER_INDEX playerId = INT_TO_PLAYERINDEX(iPlayer)
		IF IS_NET_PLAYER_OK(playerId, TRUE, FALSE)
			IF NOT IS_PED_IN_VEHICLE(GET_PLAYER_PED(playerID), vehID)
				IF GET_PLAYER_TEAM(playerId) = GET_PLAYER_TEAM(PLAYER_ID())
				OR NOT bOnlyIncludePlayersOnMyTeam
					IF (PlayerId <> PLAYER_ID())
					OR (bIncludeSendingPlayer)
						SET_BIT( iPlayerFlags , iPlayer)
					ENDIF
				ENDIF
			ENDIF
		ENDIF
	ENDREPEAT
	
	#IF IS_DEBUG_BUILD
		NET_PRINT("           ALL_PLAYERS_NOT_IN_VEHICLE() - iPlayerFlags = ")
		NET_PRINT_INT(iPlayerFlags)
		NET_NL()
	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC

FUNC INT ALL_PLAYERS_ON_SCRIPT_NOT_FREIND_OR_CREW(BOOL bIncludeSendingPlayer = TRUE)

	INT iPlayerFlags
	INT iParticipant
	//GAMER_HANDLE tempHandle 
	//NETWORK_CLAN_DESC myClan 
	//NETWORK_CLAN_DESC otherClan 

	g_ClanDescription = CHECK_PLAYER_CREW(PLAYER_ID()) 


	REPEAT NETWORK_GET_MAX_NUM_PARTICIPANTS() iParticipant
		IF NETWORK_IS_PARTICIPANT_ACTIVE(INT_TO_PARTICIPANTINDEX(iParticipant))
			PLAYER_INDEX PlayerId = NETWORK_GET_PLAYER_INDEX(INT_TO_PARTICIPANTINDEX(iParticipant))
			g_otherClanDescription = CHECK_PLAYER_CREW(PlayerId) 
			g_GamerHandle = GET_GAMER_HANDLE_PLAYER(playerID) 
			IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
				IF g_ClanDescription.Id != g_otherClanDescription.Id
					IF IS_GAMER_HANDLE_VALID(g_GamerHandle) 
						 IF NOT NETWORK_IS_FRIEND(g_GamerHandle) 
							IF (PlayerId <> PLAYER_ID())
							OR (bIncludeSendingPlayer)
								SET_BIT( iPlayerFlags , NATIVE_TO_INT(PlayerID))
							ENDIF
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		ENDIF
	ENDREPEAT	
	
	RETURN(iPlayerFlags)

ENDFUNC

FUNC INT ALL_FREINDS_OR_CREW_MEMBERS(BOOL bIncludeSendingPlayer = TRUE, BOOL bByPassParticipantCheck = FALSE)

	INT iPlayerFlags
	INT iParticipant

	g_ClanDescription = CHECK_PLAYER_CREW(PLAYER_ID())
	
	IF !bByPassParticipantCheck
		REPEAT NETWORK_GET_MAX_NUM_PARTICIPANTS() iParticipant
			IF NETWORK_IS_PARTICIPANT_ACTIVE(INT_TO_PARTICIPANTINDEX(iParticipant))
			
			
				PLAYER_INDEX PlayerId 	= NETWORK_GET_PLAYER_INDEX(INT_TO_PARTICIPANTINDEX(iParticipant))
				g_otherClanDescription 	= CHECK_PLAYER_CREW(PlayerId) 
				g_GamerHandle 			= GET_GAMER_HANDLE_PLAYER(playerID)
				
				IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
				AND IS_GAMER_HANDLE_VALID(g_GamerHandle)
					IF (g_ClanDescription.Id = g_otherClanDescription.Id AND g_otherClanDescription.Id != 0)
					OR NETWORK_IS_FRIEND(g_GamerHandle) 
						IF (PlayerId != PLAYER_ID())
						OR (bIncludeSendingPlayer)
							#IF IS_DEBUG_BUILD
							IF GET_COMMANDLINE_PARAM_EXISTS("sc_PrintAllPlayersDebug")
								PRINTLN("ALL_FREINDS_OR_CREW_MEMBERS - Adding participant ", iParticipant, " name: ", GET_PLAYER_NAME(PlayerId), " friends: ", NETWORK_IS_FRIEND(g_GamerHandle), " my clan ID: ", g_ClanDescription.Id, " their clan ID: ", g_otherClanDescription.Id)
							ENDIF
							#ENDIF
							
							SET_BIT( iPlayerFlags , NATIVE_TO_INT(PlayerID))
						ENDIF
					ENDIF
				ENDIF
				
			ENDIF
		ENDREPEAT	
	ELSE
	
		REPEAT NUM_NETWORK_PLAYERS iParticipant
			PLAYER_INDEX PlayerId 	= INT_TO_PLAYERINDEX(iParticipant)
			IF playerId != INVALID_PLAYER_INDEX()
				IF IS_NET_PLAYER_OK(playerId)
				AND IS_GAMER_HANDLE_VALID(g_GamerHandle)
					g_otherClanDescription 	= CHECK_PLAYER_CREW(PlayerId) 
					g_GamerHandle 			= GET_GAMER_HANDLE_PLAYER(playerID)
					IF (g_ClanDescription.Id = g_otherClanDescription.Id AND g_otherClanDescription.Id != 0)
					OR NETWORK_IS_FRIEND(g_GamerHandle) 
						IF (PlayerId != PLAYER_ID())
						OR (bIncludeSendingPlayer)
							#IF IS_DEBUG_BUILD
							IF GET_COMMANDLINE_PARAM_EXISTS("sc_PrintAllPlayersDebug")
								PRINTLN("ALL_FREINDS_OR_CREW_MEMBERS - Adding player ", iParticipant, " name: ", GET_PLAYER_NAME(PlayerId), " friends: ", NETWORK_IS_FRIEND(g_GamerHandle), " my clan ID: ", g_ClanDescription.Id, " their clan ID: ", g_otherClanDescription.Id)
							ENDIF
							#ENDIF
							SET_BIT( iPlayerFlags , NATIVE_TO_INT(PlayerID))
						ENDIF
					ENDIF
				ENDIF
			ENDIF	
		ENDREPEAT
		
	ENDIF	
	
	
	RETURN(iPlayerFlags)

ENDFUNC

FUNC INT ALL_PLAYERS_ON_SCRIPT( BOOL bIncludeSendingPlayer = TRUE)

	INT iPlayerFlags
	INT iParticipant
	REPEAT NETWORK_GET_MAX_NUM_PARTICIPANTS() iParticipant
		IF NETWORK_IS_PARTICIPANT_ACTIVE(INT_TO_PARTICIPANTINDEX(iParticipant))
			PLAYER_INDEX PlayerId = NETWORK_GET_PLAYER_INDEX(INT_TO_PARTICIPANTINDEX(iParticipant))
			IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
				IF (PlayerId <> PLAYER_ID())
				OR (bIncludeSendingPlayer)
					SET_BIT( iPlayerFlags , NATIVE_TO_INT(PlayerID))
				ENDIF
			ENDIF
		ENDIF
	ENDREPEAT	
	
	#IF IS_DEBUG_BUILD
		NET_PRINT("          ALL_PLAYERS_ON_SCRIPT() - iPlayerFlags = ")
		NET_PRINT_INT(iPlayerFlags)
		NET_NL()

	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC

FUNC INT ALL_PLAYERS_ON_SCRIPT_EXCEPT_THIS_PLAYER(PLAYER_INDEX player)
	INT iPlayerFlags
	INT iParticipant
	REPEAT NETWORK_GET_MAX_NUM_PARTICIPANTS() iParticipant
		IF NETWORK_IS_PARTICIPANT_ACTIVE(INT_TO_PARTICIPANTINDEX(iParticipant))
			PLAYER_INDEX PlayerId = NETWORK_GET_PLAYER_INDEX(INT_TO_PARTICIPANTINDEX(iParticipant))
			IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
				IF (PlayerId <> PLAYER_ID())
					IF PlayerId != player
						SET_BIT( iPlayerFlags , NATIVE_TO_INT(PlayerID))
					ENDIF
				ENDIF
			ENDIF
		ENDIF
	ENDREPEAT	
	
	#IF IS_DEBUG_BUILD
		NET_PRINT("          ALL_PLAYERS_ON_SCRIPT_EXCEPT_THIS_PLAYER() - iPlayerFlags = ")
		NET_PRINT_INT(iPlayerFlags)
		NET_NL()

	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC

//FUNC INT ALL_PLAYERS_IN_PARTY(BOOL bIncludeSendingPlayer = TRUE)
//	INT iPlayerFlags
//	INT iNumInParty
//	INT i
//	NETWORK_PARTY_DESC partyInfo
//	IF NETWORK_IS_IN_PARTY()
//		NET_PRINT("ALL_PLAYERS_IN_PARTY player in party") NET_NL()
//		iNumInParty = NETWORK_GET_PARTY_MEMBERS(partyInfo,SIZE_OF(partyInfo))
//		NET_PRINT_STRING_INT("ALL_PLAYERS_IN_PARTY iNumInParty : ", iNumInParty) NET_NL()
//		REPEAT iNumInParty i 
//			IF NETWORK_IS_GAMER_IN_MY_SESSION(partyInfo.MemberInfo[i].Handle)
//				NET_PRINT_STRING_INT("ALL_PLAYERS_IN_PARTY player in party is in session ", i) NET_NL()
//				PLAYER_INDEX PlayerId = NETWORK_GET_PLAYER_FROM_GAMER_HANDLE(partyInfo.MemberInfo[i].Handle)
//				IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
//					NET_PRINT_STRING_INT("ALL_PLAYERS_IN_PARTY player in party is ok ", i) NET_NL()
//					IF (PlayerId <> PLAYER_ID())
//					OR (bIncludeSendingPlayer)
//						NET_PRINT_STRING_INT("ALL_PLAYERS_IN_PARTY player is not local player", i) NET_NL()
//						SET_BIT( iPlayerFlags , NATIVE_TO_INT(PlayerID))
//					ENDIF	
//				ENDIF
//			ENDIF
//		ENDREPEAT
//	ENDIF
//	IF NETWORK_IS_IN_PLATFORM_PARTY()
//		NET_PRINT("ALL_PLAYERS_IN_PARTY player in PLATFORM party") NET_NL()
//		iNumInParty = NETWORK_GET_PARTY_MEMBERS(partyInfo,SIZE_OF(partyInfo))
//		NET_PRINT_STRING_INT("ALL_PLAYERS_IN_PARTY PLATFORM iNumInParty : ", iNumInParty) NET_NL()
//		REPEAT iNumInParty i 
//			IF NETWORK_IS_GAMER_IN_MY_SESSION(partyInfo.MemberInfo[i].Handle)
//				NET_PRINT_STRING_INT("ALL_PLAYERS_IN_PARTY player in PLATFORM party is in session ", i) NET_NL()
//				PLAYER_INDEX PlayerId = NETWORK_GET_PLAYER_FROM_GAMER_HANDLE(partyInfo.MemberInfo[i].Handle)
//				IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
//					NET_PRINT_STRING_INT("ALL_PLAYERS_IN_PARTY PLATFORM player in party is ok ", i) NET_NL()
//					IF (PlayerId <> PLAYER_ID())
//					OR (bIncludeSendingPlayer)
//						NET_PRINT_STRING_INT("ALL_PLAYERS_IN_PARTY PLATFORM player is not local player", i) NET_NL()
//						SET_BIT( iPlayerFlags , NATIVE_TO_INT(PlayerID))
//					ENDIF	
//				ENDIF
//			ENDIF
//		ENDREPEAT
//	ENDIF
//	
//	
//	#IF IS_DEBUG_BUILD
//		NET_PRINT("          ALL_PLAYERS_IN_PARTY() - iPlayerFlags = ")
//		NET_PRINT_INT(iPlayerFlags)
//		NET_NL()
//	#ENDIF
//	
//	RETURN(iPlayerFlags)
//ENDFUNC

FUNC INT SCRIPT_HOST()
	
	INT iPlayerFlags
	PARTICIPANT_INDEX tempPart
	tempPart = NETWORK_GET_HOST_OF_THIS_SCRIPT()
	IF NETWORK_IS_PARTICIPANT_ACTIVE(tempPart)
		PLAYER_INDEX PlayerId = NETWORK_GET_PLAYER_INDEX(tempPart)
		IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
			SET_BIT( iPlayerFlags , NATIVE_TO_INT(PlayerID))
		ENDIF
	ENDIF
	
	
	#IF IS_DEBUG_BUILD
		NET_PRINT("          SCRIPT_HOST() - iPlayerFlags = ")
		NET_PRINT_INT(iPlayerFlags)
		NET_NL()
	#ENDIF
	
	RETURN(iPlayerFlags)
ENDFUNC

FUNC INT ALL_GANG_MEMBERS(BOOL bCheckDead = TRUE, BOOL bIncludeLocalPlayer = TRUE)
	INT iPlayerFlags
	INT i
	
	PLAYER_INDEX piGangBoss
	
	IF GB_IS_PLAYER_BOSS_OF_A_GANG(PLAYER_ID())
		piGangBoss = PLAYER_ID()
	ELSE
		piGangBoss = GB_GET_LOCAL_PLAYER_GANG_BOSS()		
	ENDIF
	
	IF piGangBoss = PLAYER_ID()
	OR IS_NET_PLAYER_OK(piGangBoss, bCheckDead, TRUE)
		SET_BIT(iPlayerFlags, NATIVE_TO_INT(piGangBoss))
	ENDIF
	
	REPEAT NUM_NETWORK_PLAYERS i
		PLAYER_INDEX piPlayer = INT_TO_NATIVE(PLAYER_INDEX, i)
		
		IF piGangBoss != piPlayer
		AND GB_ARE_PLAYERS_IN_SAME_GANG(piPlayer, piGangBoss)
		AND IS_NET_PLAYER_OK(piPlayer, bCheckDead, TRUE)
			SET_BIT(iPlayerFlags, i)
		ENDIF
	ENDREPEAT
	
	IF NOT bIncludeLocalPlayer
		CLEAR_BIT(iPlayerFlags, NATIVE_TO_INT(PLAYER_ID()))
	ENDIF
	
	RETURN iPlayerFlags
ENDFUNC		

//╔═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
//║		EVENTS SYSTEM  - Using new code based events system - speak to Neil for more info								║
//╠═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
//║																														║
//║		note: the script events are declared in the NETWORK_SCRIPTED_EVENTS enum in commands_network.sch  				║
//║		  																												║
//║		  Each event needs 2 structures, 1 for sending and 1 for receiving.												║
//║			The receiving structure contains additional details (see below)												║
//║		  																												║
//╚═════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							GENERAL EVENT										║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════

STRUCT SCRIPT_EVENT_GENERAL_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details 
	GENERAL_EVENT_TYPE 			GeneralType
	INT							iGeneralEventID
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_REQUEST_CORONA_VEHICLE_WORLD_CHECK
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_REPLY_CORONA_VEHICLE_WORLD_CHECK
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iResponse
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_CORONA_VEHICLE_WORLD_CHECK_IS_NO_LONGER_REQUIRED
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

STRUCT STRUCT_SCRIPT_EVENT_CHECK_IF_ENTITY_IN_CORONA_AND_MOVE
	STRUCT_EVENT_COMMON_DETAILS	Details
	BOOL bForSubmersible
	BOOL bForYacht
ENDSTRUCT

STRUCT STRUCT_SCRIPT_EVENT_GB_DISABLE_GOON_MEMBERSHIP
	STRUCT_EVENT_COMMON_DETAILS Details 
	BOOL bEjectPlayer
ENDSTRUCT

// ═════════════════╡  FUNCTIONS  ╞═════════════════
//PURPOSE: Broadcast an event to players in the session, the bs_Players is a bitset of the players to send to. There are useful commands in net_events.sch for this. 
PROC BROADCAST_GENERAL_EVENT(GENERAL_EVENT_TYPE GeneralEventType, INT bs_Players)
	SCRIPT_EVENT_GENERAL_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_GENERAL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.GeneralType = GeneralEventType
	Event.iGeneralEventID = GET_RANDOM_INT_IN_RANGE(0, 9999)
	IF NOT (bs_Players = 0)
		IF NETWORK_IS_GAME_IN_PROGRESS()
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), bs_Players)
		ENDIF
	ELSE
		NET_PRINT("BROADCAST_GENERAL_EVENT - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC


PROC BROADCAST_SCRIPT_EVENT_CHECK_IF_ENTITY_IN_CORONA_AND_MOVE(PLAYER_INDEX playerId, BOOL bForsubmersible, BOOL bForYacht)
	
	STRUCT_SCRIPT_EVENT_CHECK_IF_ENTITY_IN_CORONA_AND_MOVE sEventStruct
	
	sEventStruct.Details.Type				=	SCRIPT_EVENT_CHECK_IF_ENTITY_IN_CORONA_AND_MOVE
	sEventStruct.Details.FromPlayerIndex	=	PLAYER_ID()
	sEventStruct.bForSubmersible 			=	bForsubmersible
	sEventStruct.bForYacht 					=	bForYacht
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, sEventStruct, SIZE_OF(sEventStruct), SPECIFIC_PLAYER(playerId))
	
	PRINTLN("[HOTPROPERTY] - [PACKAGE VISIBILITY] - broadcast SCRIPT_EVENT_CHECK_IF_ENTITY_IN_CORONA_AND_MOVE to ", GET_PLAYER_NAME(playerId))
	PRINTLN("[HOTPROPERTY] - [PACKAGE VISIBILITY] - sEventStruct.bForSubmersible = ", sEventStruct.bForSubmersible)
	PRINTLN("[HOTPROPERTY] - [PACKAGE VISIBILITY] - sEventStruct.bForYacht = ", sEventStruct.bForYacht)
	
ENDPROC

PROC PROCESS_SCRIPT_EVENT_CHECK_IF_ENTITY_IN_CORONA_AND_MOVE(INT paramEventID)
	
	STRUCT_SCRIPT_EVENT_CHECK_IF_ENTITY_IN_CORONA_AND_MOVE sEventStruct
	
	IF NOT (GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, paramEventID, sEventStruct, SIZE_OF(sEventStruct)))
		
		SCRIPT_ASSERT("[HOTPROPERTY] - [PACKAGE VISIBILITY] - PROCESS_SCRIPT_EVENT_CHECK_IF_ENTITY_IN_CORONA_AND_MOVE(): FAILED TO RETRIEVE EVENT DATA. Tell Keith and Will.")
		EXIT
		
	ELSE
	
		PRINTLN("[HOTPROPERTY] - [PACKAGE VISIBILITY] - Received PROCESS_SCRIPT_EVENT_CHECK_IF_ENTITY_IN_CORONA_AND_MOVE from player ", GET_PLAYER_NAME(sEventStruct.Details.FromPlayerIndex))
		
		MPGlobals.bCheckIfEntityIsInCorona = TRUE
		PRINTLN("[HOTPROPERTY] - [PACKAGE VISIBILITY] - MPGlobals.bCheckIfEntityIsInCorona = TRUE")
		
		IF sEventStruct.bForSubmersible
			MPGlobals.bMoveHotPropertyForSubmersible = TRUE
			PRINTLN("[HOTPROPERTY] - [PACKAGE VISIBILITY] - MPGlobals.bMoveHotPropertyForSubmersible = TRUE")
		ELIF sEventStruct.bForYacht
			MPGlobals.bMoveHotPropertyForYacht = TRUE
			PRINTLN("[HOTPROPERTY] - [PACKAGE VISIBILITY] - MPGlobals.bMoveHotPropertyForYacht = TRUE")
		ENDIF
		
	ENDIF
	
ENDPROC

#IF IS_DEBUG_BUILD
FUNC BOOL HAS_LOCAL_PLAYER_JUST_RECIEVED_GENERAL_EVENT(GENERAL_EVENT_TYPE EventToCheck)

	//process the events
	INT iCount
	STRUCT_EVENT_COMMON_DETAILS Details	
	SCRIPT_EVENT_GENERAL_EVENT Event
	
	REPEAT GET_NUMBER_OF_EVENTS(SCRIPT_EVENT_QUEUE_NETWORK) iCount
		IF (GET_EVENT_AT_INDEX(SCRIPT_EVENT_QUEUE_NETWORK, iCount) = EVENT_NETWORK_SCRIPT_EVENT)			
			IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iCount, Details, SIZE_OF(Details))
				IF (Details.Type = SCRIPT_EVENT_GENERAL)												
					IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iCount, Event, SIZE_OF(Event))
						IF (Event.GeneralType = EventToCheck)
							PRINTLN("HAS_LOCAL_PLAYER_JUST_RECIEVED_GENERAL_EVENT = TRUE - for EventToCheck ", ENUM_TO_INT(EventToCheck))
							RETURN TRUE
						ENDIF
					ENDIF
				ENDIF
			ENDIF
		ENDIF
	ENDREPEAT
	
	RETURN FALSE
		
ENDFUNC
#ENDIF

//╔═════════════════════════════════════════════════════════════════════════════╗
//║						TICKER MESSAGE EVENTS									║
//╚═════════════════════════════════════════════════════════════════════════════╝
//PURPOSE: data structure for the ticker message script event
#IF IS_DEBUG_BUILD
CONST_INT ciCHEAT_TICKER_PLANE		1
CONST_INT ciCHEAT_TICKER_HELI		2
CONST_INT ciCHEAT_TICKER_BOAT		3
CONST_INT ciCHEAT_TICKER_BIKE		4
CONST_INT ciCHEAT_TICKER_BICYCLE	5
#ENDIF

//PURPOSE: data structure for the ticker message script event
STRUCT SCRIPT_EVENT_DATA_TICKER_CUSTOM_MESSAGE
	STRUCT_EVENT_COMMON_DETAILS Details 
	TICKER_EVENTS TickerEvent
	INT dataInt
	INT TeamInt
	INT iSubType
	INT iRule
	INT iTeamToUse
	INT dataDisplayOption
	BOOL blockAudio
	INT iEntityNum
	//TEXT_LABEL_23 tlObjname // needed for ticker object names
	//TEXT_LABEL_23 tlObjNamePlural // needed for ticker object names plural
	PLAYER_INDEX playerID

ENDSTRUCT

//-- For playing drop-off/ goto objective complete postfx on specatators
STRUCT SCRIPT_EVENT_PLAY_POSTFX_OBJECTIVE_COMPLETE
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

STRUCT SCRIPT_EVENT_NETWORK_ROULETTE_MESSAGE
	STRUCT_EVENT_COMMON_DETAILS Details
	TIME_DATATYPE timeStamp
	INT iMessageType			// enum of message type
	INT iPlayerIndex			// which player this has come from (0 - 3 are players, 4 is dealer)
	INT iTableIndex				// which table this has come from
	INT iDataInt[3]
	FLOAT iDataFloat[3]
ENDSTRUCT

STRUCT SCRIPT_EVENT_NETWORK_ROULETTE_TABLE_LAYOUT
	STRUCT_EVENT_COMMON_DETAILS Details
	TIME_DATATYPE timeStamp
	INT iPlayerIndex			// which player this has come from (0 - 3 are players, 4 is dealer)
	INT iTableIndex				// which table this has come from
	INT iDataInt[20]
ENDSTRUCT

// ═════════════════╡  FUNCTIONS  ╞═════════════════

PROC BROADCAST_NETWORK_ROULETTE_MESSAGE(INT iMessageType, INT iPlayerIndex, INT &iDataInt[], FLOAT &iDataFloat[], INT iTableIndex = -1)
    INT i
	
	// fill data arrays
	IF COUNT_OF(iDataInt) <> 3
		SCRIPT_ASSERT("DATA INT CAN ONLY HAVE 3 ELEMENTS")
	ENDIF
	
	// fill data arrays
	IF COUNT_OF(iDataFloat) <> 3
		SCRIPT_ASSERT("DATA FLOAT CAN ONLY HAVE 3 ELEMENTS")
	ENDIF
	
    SCRIPT_EVENT_NETWORK_ROULETTE_MESSAGE Event
    Event.Details.Type              = SCRIPT_EVENT_NETWORK_ROULETTE_MSG //This is the new event
    Event.Details.FromPlayerIndex   = PLAYER_ID()
	
	Event.timeStamp = GET_NETWORK_TIME()
	Event.iMessageType = iMessageType // as int so i don't have to keep on messing about with this file as i add enums	
	Event.iTableIndex = iTableIndex 
	Event.iPlayerIndex = iPlayerIndex
	
	// send custom data
	REPEAT 3 i
		Event.iDataInt[i] = iDataInt[i]
	    Event.iDataFloat[i] = iDataFloat[i]    
	ENDREPEAT
	
	// we need to send to all players as a different script will be reading this
    INT iSendTo = ALL_PLAYERS(TRUE)
    IF NOT (iSendTo = 0)                
    	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iSendTo)
    ELSE
        PRINTLN("BROADCAST_ROULETTE_EVENT - iSendTo = 0 so not broadcasting")
    ENDIF      
ENDPROC

PROC BROADCAST_NETWORK_ROULETTE_TABLE_LAYOUT(INT iPlayerIndex, INT &iDataInt[], INT iTableIndex = -1)
    INT i
	
	// fill data arrays
	IF COUNT_OF(iDataInt) <> 20
		SCRIPT_ASSERT("DATA INT CAN ONLY HAVE 20 ELEMENTS")
	ENDIF
	
    SCRIPT_EVENT_NETWORK_ROULETTE_TABLE_LAYOUT Event

    Event.Details.Type              = SCRIPT_EVENT_NETWORK_ROULETTE_LAYOUT_MSG //This is the new event
    Event.Details.FromPlayerIndex   = PLAYER_ID()

	Event.timeStamp = GET_NETWORK_TIME()
	Event.iTableIndex = iTableIndex 
	Event.iPlayerIndex = iPlayerIndex
	
	// send custom data
	REPEAT 20 i
		Event.iDataInt[i] = iDataInt[i] 
	ENDREPEAT
	
	// we need to send to all players as a different script will be reading this
    INT iSendTo = ALL_PLAYERS(TRUE)
    IF NOT (iSendTo = 0)                
    	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iSendTo)
    ELSE
        PRINTLN("BROADCAST_ROULETTE_EVENT - iSendTo = 0 so not broadcasting")
    ENDIF      
ENDPROC

//PURPOST: Function for broadcasting a global ticker event
PROC BROADCAST_TICKER_EVENT(SCRIPT_EVENT_DATA_TICKER_MESSAGE TickerEventData, INT iPlayerFlags)

	NET_PRINT("BROADCAST_TICKER_EVENT - ")
	NET_NL()
	
	TickerEventData.Details.Type = SCRIPT_EVENT_TICKER_MESSAGE
	TickerEventData.Details.FromPlayerIndex = PLAYER_ID()
	NET_NL() NET_PRINT("BROADCAST_TICKER_EVENT - sender = ") NET_PRINT_INT(NATIVE_TO_INT(TickerEventData.Details.FromPlayerIndex)) NET_NL()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, TickerEventData, SIZE_OF(TickerEventData), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_TICKER_EVENT - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

// ═════════════════╡  FUNCTIONS  ╞═════════════════

#IF IS_DEBUG_BUILD
FUNC STRING GET_BEFORE_CORONA_VEHICLE_WORLD_CHECK_RESPONSE_NAME(INT iResponse)
	
	SWITCH iResponse
		CASE CORONA_VEHICLE_WORLD_CHECK_RESPONSE_NONE					RETURN "RESPONSE_NONE"
		CASE CORONA_VEHICLE_WORLD_CHECK_RESPONSE_KNOW_ABOUT_VEH			RETURN "RESPONSE_KNOW_ABOUT_VEH"
		CASE CORONA_VEHICLE_WORLD_CHECK_RESPONSE_DO_NOT_KNOW_ABOUT_VEH	RETURN "RESPONSE_DO_NOT_KNOW_ABOUT_VEH"
	ENDSWITCH
	
	RETURN "NOT_IN_SWITCH"
	
ENDFUNC
#ENDIF

PROC SET_PLAYERS_BEFORE_CORONA_VEH_DECORATOR(PLAYER_INDEX playerId, VEHICLE_INDEX vehIndex)
	
	TEXT_LABEL_63 tl63temp = "BeforeCorona"

	IF DECOR_IS_REGISTERED_AS_TYPE(tl63temp, DECOR_TYPE_INT)								
		PRINTLN("WJK] - before corona vehicle - SET_PLAYERS_BEFORE_CORONA_VEH_DECORATOR - [CORONA_VEH_WORLD_CHECK] - my corona world check decorator is registered as a decorator.")
		IF NOT DECOR_EXIST_ON(vehIndex, tl63temp)
			PRINTLN("[WJK] - before corona vehicle - SET_PLAYERS_BEFORE_CORONA_VEH_DECORATOR - [CORONA_VEH_WORLD_CHECK] - my corona world check decorator not on vehicle, adding.")
			DECOR_SET_INT(vehIndex, tl63temp, NATIVE_TO_INT(PlayerId))
		ENDIF
	ENDIF

ENDPROC

PROC CLEAR_PLAYERS_BEFORE_CORONA_VEH_DECORATOR(VEHICLE_INDEX vehIndex)
	
	TEXT_LABEL_63 tl63temp = "BeforeCorona"

	IF DECOR_IS_REGISTERED_AS_TYPE(tl63temp, DECOR_TYPE_INT)								
		PRINTLN("WJK] - before corona vehicle - CLEAR_PLAYERS_BEFORE_CORONA_VEH_DECORATOR - [CORONA_VEH_WORLD_CHECK] - my corona world check decorator is registered as a decorator.")
		IF DECOR_EXIST_ON(vehIndex, tl63temp)
			PRINTLN("[WJK] - before corona vehicle - CLEAR_PLAYERS_BEFORE_CORONA_VEH_DECORATOR - [CORONA_VEH_WORLD_CHECK] - my corona world check decorator on vehicle, removing.")
			DECOR_REMOVE(vehIndex, tl63temp)
		ENDIF
	ENDIF

ENDPROC

FUNC BOOL GET_PLAYERS_BEFORE_CORONA_VEH_DECORATOR_IS_SET(PLAYER_INDEX playerId, VEHICLE_INDEX vehIndex)
	
	TEXT_LABEL_63 tl63temp = "BeforeCorona"

	IF DECOR_IS_REGISTERED_AS_TYPE(tl63temp, DECOR_TYPE_INT)								
		PRINTLN("WJK] - before corona vehicle - GET_PLAYERS_BEFORE_CORONA_VEH_DECORATOR_IS_SET - [CORONA_VEH_WORLD_CHECK] - my corona world check decorator is registered as a decorator.")
		IF DECOR_EXIST_ON(vehIndex, tl63temp)
			PRINTLN("[WJK] - before corona vehicle - GET_PLAYERS_BEFORE_CORONA_VEH_DECORATOR_IS_SET - [CORONA_VEH_WORLD_CHECK] - my corona world check decorator on vehicle")
			INT iPlayer = DECOR_GET_INT(vehIndex, tl63temp)
			PRINTLN("[WJK] - before corona vehicle - GET_PLAYERS_BEFORE_CORONA_VEH_DECORATOR_IS_SET - [CORONA_VEH_WORLD_CHECK] - iPlayer = ",iPlayer)
			RETURN (iPlayer = NATIVE_TO_INT(playerId))
		ENDIF
	ENDIF
	
	RETURN FALSE

ENDFUNC

PROC BROADCAST_SCRIPT_EVENT_REQUEST_CORONA_VEHICLE_WORLD_CHECK()
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[WJK] - [CORONA_VEH_WORLD_CHECK] - BROADCAST_SCRIPT_EVENT_REQUEST_CORONA_VEHICLE_WORLD_CHECK has been called: ")
		DEBUG_PRINTCALLSTACK()
	#ENDIF
	
	SCRIPT_EVENT_DATA_REQUEST_CORONA_VEHICLE_WORLD_CHECK Event
	Event.Details.Type = SCRIPT_EVENT_REQUEST_CORONA_VEHICLE_WORLD_CHECK
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
	
ENDPROC

PROC BROADCAST_SCRIPT_EVENT_REPLY_CORONA_VEHICLE_WORLD_CHECK(PLAYER_INDEX playerToBroadcastTo, INT iResponse)
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[WJK] - [CORONA_VEH_WORLD_CHECK] - BROADCAST_SCRIPT_EVENT_REPLY_CORONA_VEHICLE_WORLD_CHECK has been called: response = ", GET_BEFORE_CORONA_VEHICLE_WORLD_CHECK_RESPONSE_NAME(iResponse))
		DEBUG_PRINTCALLSTACK()
	#ENDIF
	
	SCRIPT_EVENT_DATA_REPLY_CORONA_VEHICLE_WORLD_CHECK Event
	Event.Details.Type = SCRIPT_EVENT_REPLY_CORONA_VEHICLE_WORLD_CHECK
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iResponse = iResponse
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(playerToBroadcastTo))
	
ENDPROC

PROC BROADCAST_SCRIPT_EVENT_CORONA_VEHICLE_WORLD_CHECK_IS_NO_LONGER_REQUIRED(PLAYER_INDEX playerToBroadcastTo)
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[WJK] - [CORONA_VEH_WORLD_CHECK] - BROADCAST_SCRIPT_EVENT_CORONA_VEHICLE_WORLD_CHECK_IS_NO_LONGER_REQUIRED has been called: ")
		DEBUG_PRINTCALLSTACK()
	#ENDIF
	
	SCRIPT_EVENT_DATA_CORONA_VEHICLE_WORLD_CHECK_IS_NO_LONGER_REQUIRED Event
	Event.Details.Type = SCRIPT_EVENT_CORONA_VEHICLE_WORLD_CHECK_IS_NO_LONGER_REQUIRED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(playerToBroadcastTo))
	
ENDPROC

PROC PROCESS_SCRIPT_EVENT_CORONA_VEHICLE_WORLD_CHECK_IS_NO_LONGER_REQUIRED(INT iEventID)
	
	PRINTLN("[CORONA_VEH_WORLD_CHECK] - BROADCAST_SCRIPT_EVENT_CORONA_VEHICLE_WORLD_CHECK_IS_NO_LONGER_REQUIRED has been received.")
	
	SCRIPT_EVENT_DATA_CORONA_VEHICLE_WORLD_CHECK_IS_NO_LONGER_REQUIRED Event
	
	IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iEventID, Event, SIZE_OF(Event))
		PRINTLN("[CORONA_VEH_WORLD_CHECK] - BROADCAST_SCRIPT_EVENT_CORONA_VEHICLE_WORLD_CHECK_IS_NO_LONGER_REQUIRED calling RESET_BEFORE_CORONA_VEHICLE_DATA().")
		RESET_BEFORE_CORONA_VEHICLE_DATA()
	ENDIF
	
ENDPROC

PROC PROCESS_SCRIPT_EVENT_REQUEST_CORONA_VEHICLE_WORLD_CHECK(INT iEventID)
	
	SCRIPT_EVENT_DATA_REQUEST_CORONA_VEHICLE_WORLD_CHECK Event
	
	IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iEventID, Event, SIZE_OF(Event))
		
		IF IS_NET_PLAYER_OK(Event.Details.FromPlayerIndex, FALSE)
			g_TransitionSessionNonResetVars.viFoundCoronaVehId[NATIVE_TO_INT(Event.Details.FromPlayerIndex)] = DOES_VEHICLE_EXIST_WITH_DECORATOR("BeforeCorona")
			IF DOES_ENTITY_EXIST(g_TransitionSessionNonResetVars.viFoundCoronaVehId[NATIVE_TO_INT(Event.Details.FromPlayerIndex)])
				PRINTLN("[CORONA_VEH_WORLD_CHECK] - PROCESS_SCRIPT_EVENT_REQUEST_CORONA_VEHICLE_WORLD_CHECK - Entity exists")
				IF GET_PLAYERS_BEFORE_CORONA_VEH_DECORATOR_IS_SET(Event.Details.FromPlayerIndex,g_TransitionSessionNonResetVars.viFoundCoronaVehId[NATIVE_TO_INT(Event.Details.FromPlayerIndex)])
					PRINTLN("[CORONA_VEH_WORLD_CHECK] - PROCESS_SCRIPT_EVENT_REQUEST_CORONA_VEHICLE_WORLD_CHECK - Entity belongs to player ",GET_PLAYER_NAME(Event.Details.FromPlayerIndex))
					BROADCAST_SCRIPT_EVENT_REPLY_CORONA_VEHICLE_WORLD_CHECK(Event.Details.FromPlayerIndex, CORONA_VEHICLE_WORLD_CHECK_RESPONSE_KNOW_ABOUT_VEH)
				ELSE
					BROADCAST_SCRIPT_EVENT_REPLY_CORONA_VEHICLE_WORLD_CHECK(Event.Details.FromPlayerIndex, CORONA_VEHICLE_WORLD_CHECK_RESPONSE_DO_NOT_KNOW_ABOUT_VEH)
				ENDIF
			ELSE
				BROADCAST_SCRIPT_EVENT_REPLY_CORONA_VEHICLE_WORLD_CHECK(Event.Details.FromPlayerIndex, CORONA_VEHICLE_WORLD_CHECK_RESPONSE_DO_NOT_KNOW_ABOUT_VEH)
			ENDIF
		ELSE
			BROADCAST_SCRIPT_EVENT_REPLY_CORONA_VEHICLE_WORLD_CHECK(Event.Details.FromPlayerIndex, CORONA_VEHICLE_WORLD_CHECK_RESPONSE_DO_NOT_KNOW_ABOUT_VEH)
		ENDIF
		
		SET_BIT(g_TransitionSessionNonResetVars.iRemoveBeforeCoronaDecorator, NATIVE_TO_INT(Event.Details.FromPlayerIndex))
		
	ENDIF
	
ENDPROC

PROC PROCESS_SCRIPT_EVENT_REPLY_CORONA_VEHICLE_WORLD_CHECK(INT iEventID)
	
	SCRIPT_EVENT_DATA_REPLY_CORONA_VEHICLE_WORLD_CHECK Event
	
	IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iEventID, Event, SIZE_OF(Event))
		g_structCoronaVehicleWorldCheck.iCoronaVehWorldCheckReplyValue[NATIVE_TO_INT(Event.Details.FromPlayerIndex)] = event.iResponse
	ENDIF
	
ENDPROC

//PURPOST: Function for broadcasting a global ticker event
PROC BROADCAST_CUSTOM_TICKER_EVENT(SCRIPT_EVENT_DATA_TICKER_CUSTOM_MESSAGE TickerEventData,INT iPlayerFlags)

	NET_PRINT("BROADCAST_CUSTOM_TICKER_EVENT - ")
	
	TickerEventData.Details.Type = SCRIPT_EVENT_TICKER_MESSAGE_CUSTOM
	TickerEventData.Details.FromPlayerIndex = PLAYER_ID()
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, TickerEventData, SIZE_OF(TickerEventData), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CUSTOM_TICKER_EVENT - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC


//PURPOSE: Fill in the location for a mission
PROC FILL_IN_LOCATION_MISSION_DATA(MP_MISSION mission, INT iPlayerFlags, VECTOR &paramSecondaryCoords, VECTOR &paramPrimaryCoords )

	// KGM 22/8/11: The 'GET_...' functions are now obsolete replaced with a 'FILL_...' function that stores the potential mission start locations
	//				in a global vector array. Rowan's map spawn routines will use that data to generate a valid start location for a mission.
	// TEMP (until Rowan's routine is ready to be used pre-mission): Randomly choose one of the available start locations

	// The replacement functionality making use of Rowan's map spawn routines
	// Fill the global vector array with pootential mission start locations
	Fill_MP_Potential_Mission_Locations(mission)
	
	// KGM 22/8/11: TEMP: This will be replaced by a call to Rowan's function - for now, randomly choose a start vector and store it for both Crook and Cop start locations
	INT nRandomInt = 0
	IF (MPGlobals.g_sStartLocations.numLocations > 1)
		nRandomInt = GET_RANDOM_INT_IN_RANGE(0, MPGlobals.g_sStartLocations.numLocations)
	ENDIF
	
	paramPrimaryCoords		= MPGlobals.g_sStartLocations.missionLocations[nRandomInt]
	paramSecondaryCoords	= paramPrimaryCoords
	
	// KGM 22/8/11: TEMP: iPlayerFlags parameter is currently unused but may be required later, so I'll fake use it to avoid a compile error
	iPlayerFlags = iPlayerFlags
	
	//If we are not setting the cop or crim location for this mission then fill in some dummy info so it doesn't keep coming in here
	IF ARE_VECTORS_EQUAL(paramPrimaryCoords, <<0.0, 0.0, 0.0>>)
		paramPrimaryCoords = <<0.0, 0.0, 5.0>>
	ENDIF
	IF ARE_VECTORS_EQUAL(paramSecondaryCoords, <<0.0, 0.0, 0.0>>)
		paramSecondaryCoords = <<0.0, 0.0, 5.0>>
	ENDIF
	
	NET_PRINT_STRING_VECTOR("Primary Location for mission  : ", paramPrimaryCoords)		NET_NL()
	NET_PRINT_STRING_VECTOR("Secondary Location for mission: ", paramSecondaryCoords)	NET_NL()
ENDPROC


STRUCT SCRIPT_EVENT_DATA_FMMC_OBJECTIVE_COMPLETE
	STRUCT_EVENT_COMMON_DETAILS Details
	
	INT iObjectiveID
	INT iParticipant
	INT iEntityID
	INT iPriority
	INT iRevalidates
	INT iBitsetArrayPassed[10]
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_NETWORK_INDEX_FOR_LATER_RULE
	STRUCT_EVENT_COMMON_DETAILS Details
	
	NETWORK_INDEX NetIdForLaterObjective
	INT iLaterObjectiveType
	INT iLaterObjectiveEntityIndex

ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_NETWORK_INDEX

	STRUCT_EVENT_COMMON_DETAILS Details
	NETWORK_INDEX vehNetID
	
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_BMB_BOMB_DETAILS
	STRUCT_EVENT_COMMON_DETAILS Details	
	NETWORK_INDEX bombID
	INT radius
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_BMB_PICKUP_DETAILS
	STRUCT_EVENT_COMMON_DETAILS Details	
	INT chance1
	INT chance2
	VECTOR propPos
	BMB_POWERUP_TYPES pickupType
	INT i
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_BMB_PROP_DETAILS
	STRUCT_EVENT_COMMON_DETAILS Details	
	INT propIdx
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_OBJECTIVE_END_MESSAGE
	STRUCT_EVENT_COMMON_DETAILS Details
	
	INT iObjectiveID
	INT iPriority
	INT iteam
	BOOL bpass
	BOOL bFailMission
	INT iTimeStamp
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_PLAYER_KNOCKED_OUT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_PLAYER_SWITCHED_TEAMS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INT iNewTeam
	BOOL bShowShard
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_PLAYER_TEAM_SWITCH_REQUEST
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INT iNewTeam
	INT iVictimPart
	PLAYER_INDEX piKiller
	BOOL bSuicide
	BOOL bNoVictim
	INT iEventSessionKey
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_SERVER_AUTHORISED_TEAM_SWAP
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iKillerPart
	INT iKillerNewTeam
	INT iVictimPart
	INT iVictimNewTeam
	INT iEventSessionKey
	BOOL bSuicide
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_CLIENT_TEAM_SWAP_COMPLETE
	STRUCT_EVENT_COMMON_DETAILS Details
	
	INT iPartToClear
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_PLAYER_COMMITED_SUICIDE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_OBJECTIVE_MID_POINT
	STRUCT_EVENT_COMMON_DETAILS Details
	
	INT iTeam
	INT iObjective

ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_TEAM_HAS_FINISHED_CUTSCENE
	STRUCT_EVENT_COMMON_DETAILS Details
	
	INT iTeam
ENDSTRUCT

CONST_INT ciFMMC_MY_WEAPON_DATA_MAX_NUMBER_OF_WEAPON_ADDONS 10
STRUCT SCRIPT_EVENT_DATA_FMMC_MY_WEAPON_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bHasWeapon
	WEAPON_INFO sWeaponInfo
	INT iParticipant
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_TEAM_HAS_EARLY_CELEBRATION
	STRUCT_EVENT_COMMON_DETAILS Details
	
	INT iTeam
	INT iWinningPoints
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_CUTSCENE_SPAWN_PROGRESS
	STRUCT_EVENT_COMMON_DETAILS Details
	
	INT iCutscene
	INT iCutsceneCamShot

ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_BINBAG_REQUEST
	STRUCT_EVENT_COMMON_DETAILS Details
	
	INT iObj
	INT iPart
	BOOL bPuttingDown

ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_CONTAINER_INVESTIGATED
	STRUCT_EVENT_COMMON_DETAILS Details
	
	INT iObj
	INT iPart
	BOOL bTarget
	BOOL bInvestigationFinished
	BOOL bInvestigationInterrupted
	BOOL bShowCollectable

ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_VIP_MARKER
	STRUCT_EVENT_COMMON_DETAILS Details
	
	VECTOR vVIPMarkerPosition

ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_TRASH_DRIVE_ENABLE
	STRUCT_EVENT_COMMON_DETAILS Details
	
	INT iVeh
	INT iPart
	BOOL bEnable
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_PED_ID
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPedid
	INT iFrame
ENDSTRUCT



STRUCT EVENT_STRUCT_STREAM_END_MOCAP_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_DISTANCE_GAINED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INT iDistanceMeters
	INT iDistanceFeet
	BOOL bGainedDistance
ENDSTRUCT

FUNC INT GET_THIS_PLAYER_UNIQUE_EVENT_ID(PLAYER_INDEX PlayerID)
	PRINTLN("[TS][UniquePlayersHash] GET_THIS_PLAYER_UNIQUE_EVENT_ID = ", GET_PLAYER_NAME(PlayerID), " = GlobalplayerBD_FM_3[NATIVE_TO_INT(PlayerID)].iUniquePlayersHash")
	RETURN GlobalplayerBD_FM_3[NATIVE_TO_INT(PlayerID)].iUniquePlayersHash
ENDFUNC

FUNC BOOL IS_THIS_EVENT_UNIQUE_ID_OK(INT iUniquePlayersHash)
	IF iUniquePlayersHash != 0
		IF iUniquePlayersHash = GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].iUniquePlayersHash
		OR iUniquePlayersHash = g_iLastUniquePlayersHash
			RETURN TRUE
		ENDIF
	ENDIF
	PRINTLN("[TS][UniquePlayersHash] IS_THIS_EVENT_UNIQUE_ID_OK , no - iUniquePlayersHash = ", iUniquePlayersHash)
	ASSERTLN("[TS][UniquePlayersHash] IS_THIS_EVENT_UNIQUE_ID_OK , no - iUniquePlayersHash = ", iUniquePlayersHash)
	//SEND cheater telemetry
	RETURN FALSE
ENDFUNC

PROC GET_THIS_SESSION_UNIQUE_EVENT_IDS(INT& iUniqueSessionHash0, INT& iUniqueSessionHash1)
	iUniqueSessionHash0 = GlobalServerBD_FM_events.iUniqueSessionHash0
	iUniqueSessionHash1 = GlobalServerBD_FM_events.iUniqueSessionHash1
	PRINTLN("[TS][UniquePlayersHash] GET_THIS_SESSION_UNIQUE_EVENT_IDS - iUniqueSessionHash0= ", GlobalServerBD_FM_events.iUniqueSessionHash0)
	PRINTLN("[TS][UniquePlayersHash] GET_THIS_SESSION_UNIQUE_EVENT_IDS - iUniqueSessionHash1= ", GlobalServerBD_FM_events.iUniqueSessionHash1)
ENDPROC
FUNC BOOL IS_THIS_EVENT_SESSION_UNIQUE_ID_OK(INT iUniqueSessionHash0, INT iUniqueSessionHash1)
	IF iUniqueSessionHash0 != 0
	OR iUniqueSessionHash1 != 0
		IF iUniqueSessionHash0 = GlobalServerBD_FM_events.iUniqueSessionHash0
		OR iUniqueSessionHash0 = GlobalServerBD_FM_events.iUniqueSessionHash1
		OR iUniqueSessionHash1 = GlobalServerBD_FM_events.iUniqueSessionHash0
		OR iUniqueSessionHash1 = GlobalServerBD_FM_events.iUniqueSessionHash1
			RETURN TRUE
		ENDIF
	ENDIF
	PRINTLN("[TS][UniquePlayersHash] IS_THIS_EVENT_SESSION_UNIQUE_ID_OK , no - iUniqueSessionHash0 = ", iUniqueSessionHash0, " iUniqueSessionHash1 = ", iUniqueSessionHash1, 
			" GlobalServerBD_FM_events.iUniqueSessionHash0 = ", GlobalServerBD_FM_events.iUniqueSessionHash0, 
			" GlobalServerBD_FM_events.iUniqueSessionHash1 = ", GlobalServerBD_FM_events.iUniqueSessionHash1)
	ASSERTLN("[TS][UniquePlayersHash] IS_THIS_EVENT_SESSION_UNIQUE_ID_OK , no - iUniqueSessionHash0 = ", iUniqueSessionHash0, " iUniqueSessionHash1 = ", iUniqueSessionHash1)
	//SEND cheater telemetry
	RETURN FALSE
ENDFUNC

PROC BROADCAST_START_STREAMING_END_MOCAP_AFTER_APARTMENT_DROPOFF()
	
	EVENT_STRUCT_STREAM_END_MOCAP_DATA Event
	Event.Details.Type 				= SCRIPT_EVENT_FMMC_START_STREAMING_END_MOCAP
	Event.Details.FromPlayerIndex	= PLAYER_ID()
		
	INT iSendTo = ALL_PLAYERS(TRUE)
	IF NOT (iSendTo = 0)		
		
		#IF IS_DEBUG_BUILD
			PRINTLN("[RCC MISSION]  BROADCAST_START_STREAMING_END_MOCAP_AFTER_APARTMENT_DROPOFF - called...")
			PRINTLN("[RCC MISSION] 					From script: ", GET_THIS_SCRIPT_NAME())
		#ENDIF

		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iSendTo)
	ELSE
		PRINTLN("[RCC MISSION] BROADCAST_MOCAP_PLAYER_REQUEST - playerflags = 0 so not broadcasting") 
	ENDIF	
	
ENDPROC

PROC BROADCAST_FMMC_PED_GIVEN_GUNONRULE(INT iped)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_GIVEN_GUNONRULE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.ipedid = iped	
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_GIVEN_GUNONRULE---------------------------") NET_NL()
	NET_PRINT("Event.iPedID = ") NET_PRINT_INT(Event.ipedid ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_GIVEN_GUNONRULE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_COMBAT_STYLE_CHANGED(INT iped)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_COMBAT_STYLE_CHANGED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.ipedid = iped
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_COMBAT_STYLE_CHANGED---------------------------") NET_NL()
	NET_PRINT("Event.iPedID = ") NET_PRINT_INT(Event.ipedid ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_COMBAT_STYLE_CHANGED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_WAITING_AFTER_GOTO(INT iped)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_WAITING_AFTER_GOTO
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.ipedid = iped
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_WAITING_AFTER_GOTO---------------------------") NET_NL()
	NET_PRINT("Event.iPedID = ") NET_PRINT_INT(Event.ipedid ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send to all players
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_WAITING_AFTER_GOTO - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_DONE_WAITING_AFTER_GOTO(INT iped)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_DONE_WAITING_AFTER_GOTO
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.ipedid = iped
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_DONE_WAITING_AFTER_GOTO---------------------------") NET_NL()
	NET_PRINT("Event.iPedID = ") NET_PRINT_INT(Event.ipedid ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send to all players
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_DONE_WAITING_AFTER_GOTO - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_CLEAR_GOTO_WAITING_STATE(INT iped)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_CLEAR_GOTO_WAITING_STATE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.ipedid = iped
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_CLEAR_GOTO_WAITING_STATE---------------------------") NET_NL()
	NET_PRINT("Event.iPedID = ") NET_PRINT_INT(Event.ipedid ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send to all players
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_CLEAR_GOTO_WAITING_STATE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_DEFENSIVE_AREA_GOTO_CLEANED_UP(INT iped)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_DEFENSIVE_AREA_GOTO_CLEANED_UP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iped
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_DEFENSIVE_AREA_GOTO_CLEANED_UP---------------------------") NET_NL()
	NET_PRINT("Event.iPedID = ") NET_PRINT_INT(Event.ipedid ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send to all players, anyone could be the host!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_DEFENSIVE_AREA_GOTO_CLEANED_UP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_DIRTY_FLAG_SET(INT iped)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_DIRTY_FLAG_SET
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.ipedid = iped
	
	// "Script Event Spam detected" because a ped updates gotos and calls this function, if it's the same ped each time the assert will fire after a number of calls. Regardless of frame gaps. This is very possible for looping gotos.
	// Passing through this var will ensure that the data is different and we can avoid the assert. 
	Event.iFrame = GET_FRAME_COUNT()
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_DIRTY_FLAG_SET---------------------------") NET_NL()
	NET_PRINT("Event.ipedid = ") NET_PRINT_INT(Event.ipedid ) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // broadcast this to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_DIRTY_FLAG_SET - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PED_ANIM_STARTED
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPedid
	INT iAnimStarted //0 = special anim, 1 = breakout anim
	
ENDSTRUCT

PROC BROADCAST_FMMC_ANIM_STARTED(INT iped, BOOL bSpecialAnim = FALSE, BOOL bBreakoutAnim = FALSE)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ANIM_STARTED Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_ANIM_STARTED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.ipedid = iped
	
	IF bSpecialAnim
		SET_BIT(Event.iAnimStarted, 0)
	ENDIF
	
	IF bBreakoutAnim
		SET_BIT(Event.iAnimStarted, 1)
	ENDIF
	
	NET_PRINT("-----------------BROADCAST_FMMC_ANIM_STARTED---------------------------") NET_NL()
	NET_PRINT("Event.ipedid = ") NET_PRINT_INT(Event.ipedid ) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // broadcast this to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_ANIM_STARTED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_ANIM_STOPPED(INT iped, BOOL bSpecialAnim = FALSE, BOOL bBreakoutAnim = FALSE)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ANIM_STARTED Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_ANIM_STOPPED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.ipedid = iped
	
	IF bSpecialAnim
		SET_BIT(Event.iAnimStarted, 0)
	ENDIF
	
	IF bBreakoutAnim
		SET_BIT(Event.iAnimStarted, 1)
	ENDIF
	
	NET_PRINT("-----------------BROADCAST_FMMC_ANIM_STOPPED---------------------------") NET_NL()
	NET_PRINT("Event.ipedid = ") NET_PRINT_INT(Event.ipedid ) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // broadcast this to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_ANIM_STARTED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_SECONDARY_ANIM_CLEANUP
	STRUCT_EVENT_COMMON_DETAILS 	Details
	BOOL	bRunCleanup
	INT		iPedNumber
ENDSTRUCT

PROC BROADCAST_FMMC_SECONDARY_ANIM_CLEANUP_EVENT(INT iped, BOOL bSecondaryAnimActive)

	SCRIPT_EVENT_DATA_FMMC_SECONDARY_ANIM_CLEANUP Event
	
	Event.Details.Type 				= SCRIPT_EVENT_FMMC_SECONDARY_ANIM_CLEANUP
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bRunCleanup				= bSecondaryAnimActive
	Event.iPedNumber				= iped
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[RCC MISSION]  BROADCAST_FMMC_SECONDARY_ANIM_CLEANUP_EVENT - called...")
		PRINTLN("[RCC MISSION]  From script: ", GET_THIS_SCRIPT_NAME())
		PRINTLN("[RCC MISSION]  bRunCleanup: ", Event.bRunCleanup)
		PRINTLN("[RCC MISSION]  iPedNumber: ", Event.iPedNumber)
	#ENDIF

	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE))

ENDPROC

PROC BROADCAST_FMMC_TREVOR_BODHI_BREAKOUT_SYNCH_SCENE_ID(INT iSynchScene)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_TREVOR_BODHI_BREAKOUT_SYNCH_SCENE_ID
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedID = iSynchScene
	
	NET_PRINT("-----------------BROADCAST_FMMC_TREVOR_BODHI_BREAKOUT_SYNCH_SCENE_ID---------------------------") NET_NL()
	NET_PRINT("Event.iPedID (iSynchScene) = ") NET_PRINT_INT(Event.iPedID ) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // broadcast this to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_TREVOR_BODHI_BREAKOUT_SYNCH_SCENE_ID - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_GO_FOUNDRY_HOSTAGE_SYNCH_SCENE_ID(INT iSynchScene)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_GO_FOUNDRY_HOSTAGE_SYNCH_SCENE_ID
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedID = iSynchScene
	
	NET_PRINT("-----------------BROADCAST_FMMC_GO_FOUNDRY_HOSTAGE_SYNCH_SCENE_ID---------------------------") NET_NL()
	NET_PRINT("Event.iPedID (iSynchScene) = ") NET_PRINT_INT(Event.iPedID ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // broadcast this to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_GO_FOUNDRY_HOSTAGE_SYNCH_SCENE_ID - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_INVENTORY_CLEANUP(INT iPed)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_INVENTORY_CLEANUP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.ipedid = iped
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_INVENTORY_CLEANUP---------------------------") NET_NL()
	NET_PRINT("Event.ipedid = ") NET_PRINT_INT(Event.ipedid ) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // broadcast this to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_INVENTORY_CLEANUP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_REMOVE_PED_FROM_GROUP(INT iped)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_REMOVE_PED_FROM_GROUP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iped
	
	NET_PRINT("-----------------BROADCAST_FMMC_REMOVE_PED_FROM_GROUP---------------------------") NET_NL()
	NET_PRINT("Event.ipedid = ") NET_PRINT_INT(Event.ipedid ) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the ped owner 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_REMOVE_PED_FROM_GROUP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_SUCCESSFULLY_REMOVED_FROM_GROUP(INT iped, PLAYER_INDEX playerToBroadcastTo)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_SUCCESSFULLY_REMOVED_FROM_GROUP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iped
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_SUCCESSFULLY_REMOVED_FROM_GROUP---------------------------") NET_NL()
	NET_PRINT("Event.ipedid = ") NET_PRINT_INT(Event.ipedid) NET_NL()
	
	INT iPlayerFlags = SPECIFIC_PLAYER(playerToBroadcastTo)
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_SUCCESSFULLY_REMOVED_FROM_GROUP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_ADDED_TO_CHARM(INT iped)

	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_ADDED_TO_CHARM
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iped

	NET_PRINT("-----------------BROADCAST_FMMC_PED_ADDED_TO_CHARM---------------------------") NET_NL()
	NET_PRINT("Event.iPedid = ") NET_PRINT_INT(Event.ipedid ) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_ADDED_TO_CHARM - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF

ENDPROC

PROC BROADCAST_FMMC_PED_REMOVED_FROM_CHARM(INT iped)

	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_REMOVED_FROM_CHARM
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iped

	NET_PRINT("-----------------BROADCAST_FMMC_PED_REMOVED_FROM_CHARM---------------------------") NET_NL()
	NET_PRINT("Event.iPedid = ") NET_PRINT_INT(Event.ipedid ) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_REMOVED_FROM_CHARM - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF

ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PED_ADD_TO_CC
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPedid
	INT iTeam

ENDSTRUCT

PROC BROADCAST_FMMC_PED_ADDED_TO_CC(INT iped,INT iTeam)

	SCRIPT_EVENT_DATA_FMMC_PED_ADD_TO_CC Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_ADDED_TO_CC
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iped
	Event.iTeam = iTeam

	NET_PRINT("-----------------BROADCAST_FMMC_PED_ADDED_TO_CC---------------------------") NET_NL()
	NET_PRINT("Event.iPedid = ") NET_PRINT_INT(Event.ipedid ) NET_NL()
	NET_PRINT("Event.iTeam = ") NET_PRINT_INT(Event.iTeam ) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_ADDED_TO_CC - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF

ENDPROC


STRUCT SCRIPT_EVENT_DATA_FMMC_CC_NEW_PARTCONTROLLER
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCrowdNum
	INT iPartController

ENDSTRUCT

PROC BROADCAST_FMMC_CC_NEW_PARTCONTROLLER(INT iCrowdNum, INT iPartController)

	SCRIPT_EVENT_DATA_FMMC_CC_NEW_PARTCONTROLLER Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_CC_NEW_PARTCONTROLLER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iCrowdNum = iCrowdNum
	Event.iPartController = iPartController

	NET_PRINT("-----------------BROADCAST_FMMC_CC_NEW_PARTCONTROLLER---------------------------") NET_NL()
	NET_PRINT("Event.iCrowdNum = ") NET_PRINT_INT(Event.iCrowdNum ) NET_NL()
	NET_PRINT("Event.iPartController = ") NET_PRINT_INT(Event.iPartController ) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CC_NEW_PARTCONTROLLER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF

ENDPROC


STRUCT SCRIPT_EVENT_DATA_FMMC_CC_PED_BEATDOWN
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCrowdNum
ENDSTRUCT


PROC BROADCAST_FMMC_CC_PED_BEATDOWN(INT iCrowdNum)

	SCRIPT_EVENT_DATA_FMMC_CC_PED_BEATDOWN Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_CC_PED_BEATDOWN
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iCrowdNum = iCrowdNum
	
	NET_PRINT("-----------------BROADCAST_FMMC_CC_PED_BEATDOWN---------------------------") NET_NL()
	NET_PRINT("Event.iCrowdNum = ") NET_PRINT_INT(Event.iCrowdNum ) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CC_PED_BEATDOWN - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF

ENDPROC

PROC BROADCAST_FMMC_CC_PED_BEATDOWN_CLEAR(INT iCrowdNum)

	SCRIPT_EVENT_DATA_FMMC_CC_PED_BEATDOWN Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_CC_PED_BEATDOWN_CLEAR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iCrowdNum = iCrowdNum
	
	NET_PRINT("-----------------BROADCAST_FMMC_CC_PED_BEATDOWN_CLEAR---------------------------") NET_NL()
	NET_PRINT("Event.iCrowdNum = ") NET_PRINT_INT(Event.iCrowdNum ) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CC_PED_BEATDOWN_CLEAR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF

ENDPROC


STRUCT SCRIPT_EVENT_DATA_FMMC_BEATDOWN_HIT
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iChange
	
ENDSTRUCT


PROC BROADCAST_FMMC_CC_PED_BEATDOWN_HIT( INT iChange = -1 )

	SCRIPT_EVENT_DATA_FMMC_BEATDOWN_HIT Event
	Event.Details.Type 				= SCRIPT_EVENT_FMMC_CC_PED_BEATDOWN_HIT
	Event.Details.FromPlayerIndex	= PLAYER_ID()
	Event.iChange					= iChange
	
	NET_PRINT("-----------------BROADCAST_FMMC_CC_PED_BEATDOWN_HIT---------------------------") NET_NL()
	NET_PRINT("Event.iChange = ") NET_PRINT_INT( Event.iChange ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CC_PED_BEATDOWN_HIT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
		
ENDPROC


STRUCT SCRIPT_EVENT_DATA_FMMC_CC_FAIL
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iFailReason
	INT iPedCausedBy
	TIME_DATATYPE timeDelay
ENDSTRUCT


PROC BROADCAST_FMMC_CC_FAIL( INT iFailReason, INT iPedCausedBy, TIME_DATATYPE timeDelay )
	
	SCRIPT_EVENT_DATA_FMMC_CC_FAIL Event
	
	Event.Details.Type 				= SCRIPT_EVENT_FMMC_CC_FAIL
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iFailReason 				= iFailReason
	Event.iPedCausedBy				= iPedCausedBy
	Event.timeDelay					= timeDelay
	
	NET_PRINT("-----------------BROADCAST_FMMC_CC_FAIL---------------------------") NET_NL()
	NET_PRINT("Event.eFailReason = ") NET_PRINT_INT( Event.iFailReason ) NET_NL()
	NET_PRINT("Event.iPedCausedBy = ") NET_PRINT_INT( Event.iPedCausedBy ) NET_NL()
	NET_PRINT("Event.iDelay = ") NET_PRINT_INT( NATIVE_TO_INT( Event.timeDelay ) ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CC_FAIL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_HEIST_PLAYS
	STRUCT_EVENT_COMMON_DETAILS 	Details
	INT 	iNumHeistPlays
ENDSTRUCT
PROC BROADCAST_FMMC_HEIST_LEADER_PLAY_COUNT(INT iNumHeistPlays)

	PRINTLN("[RCC MISSION] BROADCAST_FMMC_HEIST_LEADER_PLAY_COUNT")
	
	SCRIPT_EVENT_DATA_FMMC_HEIST_PLAYS EventData
	
	eventData.Details.Type = SCRIPT_EVENT_FMMC_HEIST_LEADER_PLAY_COUNT
	eventData.Details.FromPlayerIndex = PLAYER_ID()
	eventData.iNumHeistPlays = iNumHeistPlays
	
	INT iPlayerFlags = ALL_PLAYERS() 
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, eventData, SIZE_OF(eventData), iPlayerFlags)	
		PRINTLN("[RCC MISSION] - MC_serverBD.iNumHeistPlays = ",eventData.iNumHeistPlays) 

	ELSE
		NET_PRINT("BROADCAST_FMMC_HEIST_PLAYS - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_SVM_PLAYS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iNumSVMPlays
ENDSTRUCT
PROC BROADCAST_FMMC_SVM_LEADER_PLAY_COUNT(INT iNumSVMPlays)
	PRINTLN("[RCC MISSION] BROADCAST_FMMC_SVM_LEADER_PLAY_COUNT")
	
	SCRIPT_EVENT_DATA_FMMC_SVM_PLAYS EventData
	
	eventData.Details.Type = SCRIPT_EVENT_FMMC_SVM_LEADER_PLAY_COUNT
	eventData.Details.FromPlayerIndex = PLAYER_ID()
	eventData.iNumSVMPlays = iNumSVMPlays
	
	INT iPlayerFlags = ALL_PLAYERS()
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, eventData, SIZE_OF(eventData), iPlayerFlags)
		PRINTLN("[RCC MISSION] - MC_serverBD.iNumSVMPlays = ", eventData.iNumSVMPlays)
	ELSE
		NET_PRINT("BROADCAST_FMMC_SVM_PLAYS - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_CASH_GRAB
	STRUCT_EVENT_COMMON_DETAILS 	Details
	INT 	iCashGrabbed
	INT 	iCurrentPile
	INT 	iobjIndex
	BOOL 	bIsBonusCash
	BOOL	bFinalCashPile
	BOOL	bDailyCashVault
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_CASH_GRAB_CASH_DROPPED
	STRUCT_EVENT_COMMON_DETAILS 	Details
	FLOAT	fScale
	INT 	iDropTime
	BOOL 	bHitInTheBag
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_TREVOR_COVER_CONVERSATION_TRIGGERED
	STRUCT_EVENT_COMMON_DETAILS 	Details
	INT		iPed
	INT		iRandomAnimation
	INT 	iConversationToPlay
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_JUST_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_CC_DIALOGUE_CLIENT_TO_HOST
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iConversationsBitField[2]
	INT iConversationPainFlags
	INT iConversationCriticalFlags
	INT iTimeStamp
ENDSTRUCT

PROC BROADCAST_FMMC_CC_DIALOGUE_CLIENT_TO_HOST( INT &iConversationsToPlayBitfield[2], INT iConversationPainFlags, INT iConversationCriticalFlags )
	
	SCRIPT_EVENT_DATA_FMMC_CC_DIALOGUE_CLIENT_TO_HOST Event
	
	Event.Details.Type 					= SCRIPT_EVENT_FMMC_CC_DIALOGUE_CLIENT_TO_HOST
	Event.Details.FromPlayerIndex 		= PLAYER_ID()
	Event.iConversationsBitField[0]		= iConversationsToPlayBitfield[0]
	Event.iConversationsBitField[1]		= iConversationsToPlayBitfield[1]
	Event.iConversationPainFlags		= iConversationPainFlags
	Event.iConversationCriticalFlags	= iConversationCriticalFlags
	Event.iTimeStamp = NATIVE_TO_INT(GET_NETWORK_TIME())
	
	NET_PRINT("-----------------BROADCAST_FMMC_CC_DIALOGUE_CLIENT_TO_HOST---------------------------") NET_NL()
	
	INT iPlayerFlags = SCRIPT_HOST() // just to the host
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CC_DIALOGUE_CLIENT_TO_HOST - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC


STRUCT SCRIPT_EVENT_DATA_FMMC_CC_DIALOGUE_HOST_TO_CLIENT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iConversationsBitField[2]
	INT iConversationPainAudioFlags
ENDSTRUCT


PROC BROADCAST_FMMC_CC_DIALOGUE_HOST_TO_CLIENTS( INT &iConversationsToPlayBitfield[2], INT iConversationsPainAudioFlags )
	
	SCRIPT_EVENT_DATA_FMMC_CC_DIALOGUE_HOST_TO_CLIENT Event
	INT i
	
	Event.Details.Type 					= SCRIPT_EVENT_FMMC_CC_DIALOGUE_HOST_TO_CLIENTS
	Event.Details.FromPlayerIndex 		= PLAYER_ID()
	REPEAT 2 i
		Event.iConversationsBitField[i]	= iConversationsToPlayBitfield[i]
	ENDREPEAT
	Event.iConversationPainAudioFlags	= iConversationsPainAudioFlags
	
	NET_PRINT("-----------------BROADCAST_FMMC_CC_DIALOGUE_HOST_TO_CLIENTS---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT(FALSE) // all but the host
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CC_DIALOGUE_HOST_TO_CLIENTS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC


PROC BROADCAST_FMMC_CC_AWARD( INT iTeam )
	
	STRUCT_EVENT_COMMON_DETAILS Event
	
	Event.Type 					= SCRIPT_EVENT_FMMC_CC_AWARD
	Event.FromPlayerIndex 		= PLAYER_ID()
	
	NET_PRINT("-----------------BROADCAST_FMMC_CC_AWARD---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_IN_TEAM( iTeam, TRUE )
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CC_AWARD - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC


STRUCT SCRIPT_EVENT_DATA_FMMC_CC_DEAD
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCrowdPed
ENDSTRUCT


PROC BROADCAST_FMMC_CC_DEAD( INT iCrowdPed )
	
	SCRIPT_EVENT_DATA_FMMC_CC_DEAD Event
	
	Event.Details.Type 					= SCRIPT_EVENT_FMMC_CC_DEAD
	Event.Details.FromPlayerIndex 		= PLAYER_ID()
	Event.iCrowdPed						= iCrowdPed
	
	NET_PRINT("-----------------BROADCAST_FMMC_CC_DEAD---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CC_DEAD - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_REQUEST_RESTRICTION_ROCKETS(BOOL bRequest = TRUE)
	
	SCRIPT_EVENT_DATA_FMMC_JUST_EVENT Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_REQUEST_RESTRICTION_ROCKETS
	
	IF bRequest
		Event.Details.FromPlayerIndex = PLAYER_ID()
		PRINTLN("[RestrictedAirspace] Broadcasting out to start requesting the weapon asset!")
	ELSE
		Event.Details.FromPlayerIndex = NULL
		PRINTLN("[RestrictedAirspace] Broadcasting out to release the weapon asset!")
	ENDIF
	
	NET_PRINT("-----------------BROADCAST_FMMC_REQUEST_RESTRICTION_ROCKETS---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_REQUEST_RESTRICTION_ROCKETS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC


STRUCT SCRIPT_EVENT_DATA_FMMC_OPEN_DOOR
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iDoor
	FLOAT fHeading

ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FMMC_SWAP_DOOR_FOR_DAMAGED_VERSION
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iRule

ENDSTRUCT

PROC BROADCAST_FMMC_OPEN_DOOR_EVENT(INT iDoor,FLOAT fStartHeading)
	
	SCRIPT_EVENT_DATA_FMMC_OPEN_DOOR Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_OPEN_DOOR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iDoor = iDoor
	Event.fHeading = fStartHeading
	
	NET_PRINT("-----------------BROADCAST_FMMC_OPEN_DOOR_EVENT---------------------------") NET_NL()
	NET_PRINT(" fStartHeading: ") NET_PRINT_FLOAT(fStartHeading) NET_NL()
	NET_PRINT(" DOOR: ") NET_PRINT_INT(iDoor) NET_NL()
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_REQUEST_RESTRICTION_ROCKETS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_APPLY_EXTRA_VEH_DAMAGE_FROM_COLLISION
	STRUCT_EVENT_COMMON_DETAILS Details
	FLOAT fSpeedFactor
ENDSTRUCT

PROC BROADCAST_FMMC_APPLY_EXTRA_VEH_DAMAGE_FROM_COLLISION(PLAYER_INDEX toPlayer, FLOAT fSpeedFactor)
	
	SCRIPT_EVENT_DATA_FMMC_APPLY_EXTRA_VEH_DAMAGE_FROM_COLLISION Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_APPLY_EXTRA_VEH_DAMAGE_FROM_COLLISION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.fSpeedFactor = fSpeedFactor
	
	NET_PRINT("-----------------BROADCAST_FMMC_APPLY_EXTRA_VEH_DAMAGE_FROM_COLLISION---------------------------") NET_NL()
	NET_PRINT(" fSpeedFactor: ") NET_PRINT_FLOAT(fSpeedFactor) NET_NL()
	
	INT iPlayerFlags = SPECIFIC_PLAYER(toPlayer)
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_APPLY_EXTRA_VEH_DAMAGE_FROM_COLLISION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_SMASHED_BY_TOUCH
	STRUCT_EVENT_COMMON_DETAILS Details
	FLOAT fSpeedFactor
	BOOL bDropItem
	BOOL bStealItem
ENDSTRUCT

PROC BROADCAST_FMMC_SMASHED_BY_TOUCH_EVENT(PLAYER_INDEX toPlayer,FLOAT fSpeedFactor,BOOL bDropItem,BOOL bStealItem)
	
	SCRIPT_EVENT_DATA_FMMC_SMASHED_BY_TOUCH Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_SMASHED_BY_TOUCH
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.fSpeedFactor = fSpeedFactor
	Event.bDropItem = bDropItem
	Event.bStealItem = bStealItem
	NET_PRINT("-----------------BROADCAST_FMMC_SMASHED_BY_TOUCH_EVENT---------------------------") NET_NL()
	NET_PRINT(" fSpeedFactor: ") NET_PRINT_FLOAT(fSpeedFactor) NET_NL()
	NET_PRINT(" bDropItem: ") NET_PRINT_BOOL(bDropItem) NET_NL()
	NET_PRINT(" bStealItem: ") NET_PRINT_BOOL(bStealItem) NET_NL()
	
	INT iPlayerFlags = SPECIFIC_PLAYER(toPlayer)
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_SMASHED_BY_TOUCH - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_STEAL_OBJECT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iObjectToDrop
	PLAYER_INDEX piToPlayer
ENDSTRUCT

PROC BROADCAST_FMMC_STEAL_OBJECT_EVENT(PLAYER_INDEX toPlayer,INT iObjectToDrop)
	
	SCRIPT_EVENT_DATA_FMMC_STEAL_OBJECT Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_STEAL_OBJECT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iObjectToDrop = iObjectToDrop
	Event.piToPlayer = toPlayer
	
	NET_PRINT("-----------------BROADCAST_FMMC_STEAL_OBJECT_EVENT---------------------------") NET_NL()
	NET_PRINT(" iObjectToDrop: ") NET_PRINT_INT(iObjectToDrop) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_STEAL_OBJECT_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

CONST_INT ciEVENT_DRILL_ASSET_REQUEST 0
CONST_INT ciEVENT_DRILL_ASSET_CLEANUP 1

STRUCT SCRIPT_EVENT_DATA_FMMC_DRILL_ASSET
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventType

ENDSTRUCT

PROC BROADCAST_SCRIPT_EVENT_FMMC_DRILL_ASSET(INT iEventType)
	
	SCRIPT_EVENT_DATA_FMMC_DRILL_ASSET Event
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.Details.Type = SCRIPT_EVENT_FMMC_DRILL_ASSET
	Event.iEventType = iEventType
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[RCC MISSION]  BROADCAST_SCRIPT_EVENT_FMMC_DRILL_ASSET - called...")
		PRINTLN("[RCC MISSION]  From script: ", GET_THIS_SCRIPT_NAME())
		PRINTLN("[RCC MISSION]  iEventType: ", iEventType)
	#ENDIF

	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE))

ENDPROC

CONST_INT ciEVENT_VAULT_DRILL_ASSET_REQUEST 		0
CONST_INT ciEVENT_VAULT_DRILL_ASSET_REQUEST_LASER 	1
CONST_INT ciEVENT_VAULT_DRILL_ASSET_CLEANUP 		2

STRUCT SCRIPT_EVENT_DATA_VAULT_DRILL_ASSET
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventType

ENDSTRUCT

PROC BROADCAST_SCRIPT_EVENT_FMMC_VAULT_DRILL_ASSET(INT iEventType)
	
	SCRIPT_EVENT_DATA_VAULT_DRILL_ASSET Event
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.Details.Type = SCRIPT_EVENT_VAULT_DRILL_ASSET_REQUEST_EVENT
	Event.iEventType = iEventType
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[RCC MISSION]  BROADCAST_SCRIPT_EVENT_FMMC_VAULT_DRILL_ASSET - called...")
		PRINTLN("[RCC MISSION]  From script: ", GET_THIS_SCRIPT_NAME())
		PRINTLN("[RCC MISSION]  iEventType: ", iEventType)
	#ENDIF

	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE))

ENDPROC


STRUCT SCRIPT_EVENT_DATA_FMMC_SHUNT_POWERUP
	STRUCT_EVENT_COMMON_DETAILS Details
	FLOAT fSpeedFactor
ENDSTRUCT

PROC BROADCAST_FMMC_SHUNT_POWERUP_EVENT(PLAYER_INDEX toPlayer,FLOAT fSpeedFactor)
	
	SCRIPT_EVENT_DATA_FMMC_SHUNT_POWERUP Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_SHUNT_POWERUP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.fSpeedFactor = fSpeedFactor
	NET_PRINT("-----------------BROADCAST_FMMC_SHUNT_POWERUP_EVENT---------------------------") NET_NL()
	NET_PRINT(" fSpeedFactor: ") NET_PRINT_FLOAT(fSpeedFactor) NET_NL()
	
	INT iPlayerFlags = SPECIFIC_PLAYER(toPlayer)
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_SHUNT_POWERUP_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

//Dont Cross The Line
STRUCT SCRIPT_EVENT_DATA_DCTL_TURN
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iDirection = -1
	FLOAT fPosition = -1.0
	INT iPart = -1
	INT iLastTurn = -1
ENDSTRUCT

PROC BROADCAST_DCTL_TURN(INT iDirection, FLOAT fPosition, INT iPart, INT iLastTurn)
	SCRIPT_EVENT_DATA_DCTL_TURN Event
	Event.Details.Type = SCRIPT_EVENT_DCTL_TURN
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iDirection = iDirection
	Event.fPosition = fPosition
	Event.iPart = iPart
	Event.iLastTurn = iLastTurn
	NET_PRINT("----------BROADCAST_DCTL_TURN----------") NET_NL()
	NET_PRINT("----------FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	NET_PRINT("----------iDirection = ") NET_PRINT_INT(iDirection) NET_NL()
	NET_PRINT("----------fPosition = ") NET_PRINT_FLOAT(fPosition) NET_NL()
	NET_PRINT("----------iPart = ") NET_PRINT_INT(iPart) NET_NL()
	NET_PRINT("----------iLastTurn = ") NET_PRINT_INT(iLastTurn) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT(FALSE) // send it to all players except sender!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DCTL_TURN - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DCTL_KILL
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iKillPart
ENDSTRUCT

PROC BROADCAST_DCTL_KILL(INT iKillPart)
	SCRIPT_EVENT_DATA_DCTL_KILL Event
	Event.Details.Type = SCRIPT_EVENT_DCTL_KILL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iKillPart = iKillPart
	NET_PRINT("----------BROADCAST_DCTL_KILL----------") NET_NL()
	NET_PRINT("----------FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	NET_PRINT("----------iKillPart = ") NET_PRINT_INT(iKillPart) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players except sender!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DCTL_KILL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DCTL_START
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iTime
ENDSTRUCT

PROC BROADCAST_DCTL_START(INT iTime)
	SCRIPT_EVENT_DATA_DCTL_START Event
	Event.Details.Type = SCRIPT_EVENT_DCTL_START
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTime = iTime
	NET_PRINT("----------BROADCAST_DCTL_START----------") NET_NL()
	NET_PRINT("----------FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	NET_PRINT("----------iTime = ") NET_PRINT_INT(iTime) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DCTL_START - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

//Casino Arcade Games

STRUCT SCRIPT_EVENT_DATA_CASINO_ARCADE_REQUEST_LEADERBOARD_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details 
	CASINO_ARCADE_GAME eGameType
ENDSTRUCT

PROC BROADCAST_CASINO_ARCADE_REQUEST_LEADERBOARD_EVENT(PLAYER_INDEX piPenthouseOwner, CASINO_ARCADE_GAME eGameType)
	
	SCRIPT_EVENT_DATA_CASINO_ARCADE_REQUEST_LEADERBOARD_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_CASINO_ARCADE_REQUEST_LEADERBOARD_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.eGameType = eGameType
	NET_PRINT("----------BROADCAST_CASINO_ARCADE_REQUEST_LEADERBOARD_EVENT----------") NET_NL()
	NET_PRINT("----------FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	NET_PRINT("----------piPenthouseOwner = ") NET_PRINT_INT(NATIVE_TO_INT(piPenthouseOwner)) NET_NL()
	NET_PRINT("----------eGameType = ") NET_PRINT_INT(ENUM_TO_INT(eGameType)) NET_NL()
	
	INT iPlayerFlags = SPECIFIC_PLAYER(piPenthouseOwner) //Penthouse Owner
	IF NOT (iPlayerFlags = 0)
	AND IS_NET_PLAYER_OK(piPenthouseOwner, FALSE)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CASINO_ARCADE_REQUEST_LEADERBOARD_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_CASINO_ARCADE_SEND_LEADERBOARD_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details 
	CASINO_ARCADE_GAME eGameType
	INT iInitials[ciCASINO_ARCADE_LEADERBOARD_POSITIONS]
	INT iScores[ciCASINO_ARCADE_LEADERBOARD_POSITIONS]
ENDSTRUCT

PROC BROADCAST_CASINO_ARCADE_SEND_LEADERBOARD_EVENT(PLAYER_INDEX piRequester, CASINO_ARCADE_GAME eGameType, INT &iInitials[ciCASINO_ARCADE_LEADERBOARD_POSITIONS], INT &iScores[ciCASINO_ARCADE_LEADERBOARD_POSITIONS])
	
	SCRIPT_EVENT_DATA_CASINO_ARCADE_SEND_LEADERBOARD_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_CASINO_ARCADE_SEND_LEADERBOARD_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.eGameType = eGameType
	NET_PRINT("----------BROADCAST_CASINO_ARCADE_SEND_LEADERBOARD_EVENT----------") NET_NL()
	NET_PRINT("----------FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	NET_PRINT("----------piRequester = ") NET_PRINT_INT(NATIVE_TO_INT(piRequester)) NET_NL()
	NET_PRINT("----------eGameType = ") NET_PRINT_INT(ENUM_TO_INT(eGameType)) NET_NL()
	INT i
	FOR i = 0 TO ciCASINO_ARCADE_LEADERBOARD_POSITIONS - 1
		Event.iInitials[i] = iInitials[i]
		Event.iScores[i] = iScores[i]
		NET_PRINT("----------iInitials[") NET_PRINT_INT(i) NET_PRINT("] = ") NET_PRINT_INT(iInitials[i]) NET_NL()
		NET_PRINT("----------iScores[") NET_PRINT_INT(i) NET_PRINT("] = ") NET_PRINT_INT(iScores[i]) NET_NL()
	ENDFOR

	INT iPlayerFlags = SPECIFIC_PLAYER(piRequester) //Player who requested the leaderboard
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CASINO_ARCADE_SEND_LEADERBOARD_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_CASINO_ARCADE_UPDATE_LEADERBOARD_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details 
	CASINO_ARCADE_GAME eGameType
	INT iLeaderboardIndex
	INT iInitials
	INT iScore
	BOOL bSaveData
ENDSTRUCT

PROC BROADCAST_CASINO_ARCADE_UPDATE_LEADERBOARD_EVENT(PLAYER_INDEX piPenthouseOwner, CASINO_ARCADE_GAME eGameType, INT iLeaderboardIndex, INT iInitials, INT iScore, BOOL bSaveData = FALSE)
	
	SCRIPT_EVENT_DATA_CASINO_ARCADE_UPDATE_LEADERBOARD_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_CASINO_ARCADE_UPDATE_LEADERBOARD_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.eGameType = eGameType
	Event.iLeaderboardIndex = iLeaderboardIndex
	Event.iInitials = iInitials
	Event.iScore = iScore
	Event.bSaveData = bSaveData
	NET_PRINT("----------BROADCAST_CASINO_ARCADE_UPDATE_LEADERBOARD_EVENT----------") NET_NL()
	NET_PRINT("----------FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	NET_PRINT("----------piPenthouseOwner = ") NET_PRINT_INT(NATIVE_TO_INT(piPenthouseOwner)) NET_NL()
	NET_PRINT("----------eGameType = ") NET_PRINT_INT(ENUM_TO_INT(eGameType)) NET_NL()
	NET_PRINT("----------iLeaderboardIndex = ") NET_PRINT_INT(iLeaderboardIndex) NET_NL()
	NET_PRINT("----------iInitials = ") NET_PRINT_INT(iInitials) NET_NL()
	NET_PRINT("----------iScore = ") NET_PRINT_INT(iScore) NET_NL()
	NET_PRINT("----------bSaveData = ") NET_PRINT_BOOL(bSaveData) NET_NL()
	
	INT iPlayerFlags = SPECIFIC_PLAYER(piPenthouseOwner) //Penthouse Owner
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CASINO_ARCADE_UPDATE_LEADERBOARD_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

//Grid Arcade Game

STRUCT SCRIPT_EVENT_DATA_SCGW_INITIALS_ENTERED
	STRUCT_EVENT_COMMON_DETAILS Details 
ENDSTRUCT

PROC BROADCAST_SCGW_INITIALS_ENTERED()
	SCRIPT_EVENT_DATA_SCGW_INITIALS_ENTERED Event
	Event.Details.Type = SCRIPT_EVENT_SCGW_INITIALS_ENTERED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	NET_PRINT("----------BROADCAST_SCGW_INITIALS_ENTERED----------") NET_NL()
	NET_PRINT("----------FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SCGW_MINIGAME_PICKUP_COLLECTED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_SCGW_MINIGAME_PICKUP_COLLECTED
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iPickupIndex
ENDSTRUCT

PROC BROADCAST_SCGW_MINIGAME_PICKUP_COLLECTED(INT iPickupIndex)
	SCRIPT_EVENT_DATA_SCGW_MINIGAME_PICKUP_COLLECTED Event
	Event.Details.Type = SCRIPT_EVENT_SCGW_MINIGAME_PICKUP_COLLECTED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPickupIndex = iPickupIndex
	NET_PRINT("----------BROADCAST_SCGW_MINIGAME_PICKUP_COLLECTED----------") NET_NL()
	NET_PRINT("----------FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	NET_PRINT("----------iPickupIndex = ") NET_PRINT_INT(iPickupIndex) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SCGW_MINIGAME_PICKUP_COLLECTED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_SCGW_MINIGAME_DAMAGED
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iParticipant
	BOOL bDead
	BOOL bHitByCar
ENDSTRUCT

PROC BROADCAST_SCRIPT_EVENT_SCGW_MINIGAME_DAMAGED(INT iParticipant, BOOL bDead, BOOL bHitByCar)
	
	SCRIPT_EVENT_DATA_SCGW_MINIGAME_DAMAGED Event
	Event.Details.Type = SCRIPT_EVENT_SCGW_MINIGAME_DAMAGED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iParticipant = iParticipant
	Event.bDead = bDead
	Event.bHitByCar = bHitByCar
	NET_PRINT("----------BROADCAST_SCRIPT_EVENT_SCGW_MINIGAME_DAMAGED----------") NET_NL()
	NET_PRINT("----------FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	NET_PRINT("----------iParticipant = ") NET_PRINT_INT(iParticipant) NET_NL()
	NET_PRINT("----------bDead = ") NET_PRINT_BOOL(bDead) NET_NL()
	NET_PRINT("----------bHitByCar = ") NET_PRINT_BOOL(bHitByCar) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SCRIPT_EVENT_SCGW_MINIGAME_DAMAGED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC


STRUCT SCRIPT_EVENT_DATA_SCGW_MINIGAME_SIDE_CLAIMED
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iGridIndex
	INT iSide
	INT iGang
ENDSTRUCT

PROC BROADCAST_SCGW_MINIGAME_SIDE_CLAIMED(INT iGridIndex, INT iSide, INT iGang)
	SCRIPT_EVENT_DATA_SCGW_MINIGAME_SIDE_CLAIMED Event
	Event.Details.Type = SCRIPT_EVENT_SCGW_MINIGAME_SIDE_CLAIMED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iGridIndex = iGridIndex
	Event.iSide = iSide
	Event.iGang = iGang
	NET_PRINT("----------BROADCAST_SCGW_MINIGAME_SIDE_CLAIMED----------") NET_NL()
	NET_PRINT("----------FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	NET_PRINT("----------iGridIndex = ") NET_PRINT_INT(iGridIndex) NET_NL()
	NET_PRINT("----------iSide = ") NET_PRINT_INT(iSide) NET_NL()
	NET_PRINT("----------iGang = ") NET_PRINT_INT(iGang) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SCGW_MINIGAME_SIDE_CLAIMED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_SCGW_MINIGAME_REQUEST_CARS
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iPosition
	INT iGang
ENDSTRUCT

PROC BROADCAST_SCGW_MINIGAME_REQUEST_CARS(INT iPosition, INT iGang)
	SCRIPT_EVENT_DATA_SCGW_MINIGAME_REQUEST_CARS Event
	Event.Details.Type = SCRIPT_EVENT_SCGW_MINIGAME_REQUEST_CARS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPosition = iPosition
	Event.iGang = iGang
	NET_PRINT("----------BROADCAST_SCGW_MINIGAME_REQUEST_CARS----------") NET_NL()
	NET_PRINT("----------FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	NET_PRINT("----------iPosition = ") NET_PRINT_INT(iPosition) NET_NL()
	NET_PRINT("----------iGang = ") NET_PRINT_INT(iGang) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SCGW_MINIGAME_REQUEST_CARS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_TLG_INITIALS_ENTERED
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iInitials
ENDSTRUCT

PROC BROADCAST_TLG_INITIALS_ENTERED(INT iInitials)
	SCRIPT_EVENT_DATA_TLG_INITIALS_ENTERED Event
	Event.Details.Type = SCRIPT_EVENT_TLG_INITIALS_ENTERED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iInitials = iInitials
	NET_PRINT("----------[LEADERBOARD] [BROADCAST_TLG_INITIALS_ENTERED]----------") NET_NL()
	NET_PRINT("----------[LEADERBOARD] [BROADCAST_TLG_INITIALS_ENTERED] FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_TLG_INITIALS_ENTERED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC


STRUCT SCRIPT_EVENT_DATA_CMHDZ_INITIALS_ENTERED
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iInitials
ENDSTRUCT

PROC BROADCAST_CMHDZ_INITIALS_ENTERED(INT iInitials)
	SCRIPT_EVENT_DATA_CMHDZ_INITIALS_ENTERED Event
	Event.Details.Type = SCRIPT_EVENT_CMHDZ_INITIALS_ENTERED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iInitials = iInitials
	NET_PRINT("----------[LEADERBOARD] [BROADCAST_TLG_INITIALS_ENTERED]----------") NET_NL()
	NET_PRINT("----------[LEADERBOARD] [BROADCAST_TLG_INITIALS_ENTERED] FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CMHDZ_INITIALS_ENTERED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

//NEW

STRUCT SCRIPT_EVENT_DATA_FMMC_PICKED_UP_POWERPLAY_PICKUP
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vPlayerCoords
	INT iPickupType
	INT iTeam
	
	INT iMissionEquipmentModelSetting = -1
ENDSTRUCT

PROC BROADCAST_FMMC_PICKED_UP_POWERPLAY_PICKUP(VECTOR vPlayerCoords, INT iPickupType, INT iTeam, INT iMissionEquipmentModelSetting = -1)
	
	SCRIPT_EVENT_DATA_FMMC_PICKED_UP_POWERPLAY_PICKUP Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PICKED_UP_POWERPLAY_PICKUP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vPlayerCoords = vPlayerCoords
	Event.iPickupType = iPickupType
	Event.iTeam = iTeam
	Event.iMissionEquipmentModelSetting = iMissionEquipmentModelSetting
	
	NET_PRINT("----------BROADCAST_FMMC_PICKED_UP_POWERPLAY_PICKUP----------") NET_NL()
	NET_PRINT("----------FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	NET_PRINT("----------vPlayerCoords = ") NET_PRINT_VECTOR(vPlayerCoords) NET_NL()
	NET_PRINT("----------iPickupType = ") NET_PRINT_INT(iPickupType) NET_NL()
	NET_PRINT("----------iTeam = ") NET_PRINT_INT(iTeam) NET_NL()
	NET_PRINT("----------iMissionEquipmentModelSetting = ") NET_PRINT_INT(iMissionEquipmentModelSetting) NET_NL()
	
	INT iPlayerFlags
	IF iPickupType = ciCUSTOM_PICKUP_TYPE__RANDOM
		iPlayerFlags = SPECIFIC_PLAYER(PLAYER_ID()) // send it to me only
		NET_PRINT("BROADCAST_FMMC_PICKED_UP_POWERPLAY_POWERUP - playerflags = me only (Random Pickup)") NET_NL()
	ELSE
		iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	ENDIF
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PICKED_UP_POWERPLAY_POWERUP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_POWERPLAY_PICKUP_ENDED
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vPlayerCoords
	INT iPickupType
	INT iTeam
	INT iReason
	INT iPart
ENDSTRUCT

PROC BROADCAST_FMMC_POWERPLAY_PICKUP_ENDED(INT iPickupType, INT iTeam, INT iReason, INT iPart = -1)
	
	SCRIPT_EVENT_DATA_FMMC_POWERPLAY_PICKUP_ENDED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_POWERPLAY_PICKUP_ENDED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPickupType = iPickupType
	Event.iTeam = iTeam
	Event.iReason = iReason
	Event.iPart = iPart
	
	NET_PRINT("----------BROADCAST_FMMC_POWERPLAY_PICKUP_ENDED----------") NET_NL()
	NET_PRINT("----------FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(PLAYER_ID())) NET_NL()
	NET_PRINT("----------iPickupType = ") NET_PRINT_INT(iPickupType) NET_NL()
	NET_PRINT("----------iTeam = ") NET_PRINT_INT(iTeam) NET_NL()
	NET_PRINT("----------iReason = ") NET_PRINT_INT(iReason) NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PICKED_UP_POWERPLAY_POWERUP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//END NEW

STRUCT SCRIPT_EVENT_DATA_FMMC_PICKED_UP_LIVES_PICKUP
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
ENDSTRUCT

PROC BROADCAST_FMMC_PICKED_UP_LIVES_PICKUP(INT iTeam)
	SCRIPT_EVENT_DATA_FMMC_PICKED_UP_LIVES_PICKUP Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PICKED_UP_LIVES_PICKUP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	
	NET_PRINT("-----------------BROADCAST_FMMC_PICKED_UP_LIVES_PICKUP---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PICKED_UP_LIVES_PICKUP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF

ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PICKED_UP_POWERPLAY_POWERUP
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vPlayerCoords
ENDSTRUCT

PROC BROADCAST_FMMC_PICKED_UP_POWERPLAY_POWERUP(VECTOR vPlayerCoords)
	
	SCRIPT_EVENT_DATA_FMMC_PICKED_UP_POWERPLAY_POWERUP Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PICKED_UP_POWERPLAY_POWERUP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vPlayerCoords = vPlayerCoords
	
	NET_PRINT("-----------------BROADCAST_FMMC_PICKED_UP_POWERPLAY_POWERUP---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PICKED_UP_POWERPLAY_POWERUP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PP_PICKUP_PLAY_ANNOUNCER
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPowerupType
	INT iTeam
ENDSTRUCT

PROC BROADCAST_PP_PICKUP_PLAY_ANNOUNCER(INT iPowerupType, INT iTeam)

	IF iPowerupType = ciCUSTOM_PICKUP_TYPE__BULLET_TIME
	OR iPowerupType = ciCUSTOM_PICKUP_TYPE__SLOW_DOWN
		SET_AUDIO_FLAG("AllowScriptedSpeechInSlowMo", TRUE)
	ENDIF
	
	SCRIPT_EVENT_DATA_FMMC_PP_PICKUP_PLAY_ANNOUNCER Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PP_PICKUP_PLAY_ANNOUNCER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPowerupType = iPowerupType
	Event.iTeam = iTeam
	
	NET_PRINT("-----------------BROADCAST_PP_PICKUP_PLAY_ANNOUNCER---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PICKED_UP_POWERPLAY_POWERUP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_CANT_DECREMENT_SCORE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iKillingPart
ENDSTRUCT

PROC BROADCAST_FMMC_CANT_DECREMENT_SCORE(INT iKillingPart)
	
	SCRIPT_EVENT_DATA_FMMC_CANT_DECREMENT_SCORE Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_CANT_DECREMENT_SCORE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iKillingPart = iKillingPart

	NET_PRINT("-----------------BROADCAST_FMMC_CANT_DECREMENT_SCORE---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CANT_DECREMENT_SCORE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_SHOW_REZ_SHARD
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPartResurrected
	INT iResurrector
ENDSTRUCT

PROC BROADCAST_FMMC_SHOW_REZ_SHARD(INT iPartResurrected, INT iResurrector)
	
	SCRIPT_EVENT_DATA_FMMC_SHOW_REZ_SHARD Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_SHOW_REZ_SHARD
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPartResurrected = iPartResurrected
	Event.iResurrector = iResurrector

	NET_PRINT("-----------------BROADCAST_FMMC_SHOW_REZ_SHARD---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_SHOW_REZ_SHARD - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC


STRUCT SCRIPT_EVENT_DATA_FMMC_SHOW_REZ_TICKER
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPart
ENDSTRUCT

PROC BROADCAST_FMMC_SHOW_REZ_TICKER(INT iPart)
	
	SCRIPT_EVENT_DATA_FMMC_SHOW_REZ_TICKER Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_SHOW_REZ_TICKER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPart = iPart

	NET_PRINT("-----------------BROADCAST_FMMC_SHOW_REZ_TICKER---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_SHOW_REZ_TICKER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_TEAM_CHECKPOINT_PASSED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INT iPart
	INT iCurrentLoc
	INT iCurrentLap
ENDSTRUCT

PROC BROADCAST_FMMC_TEAM_CHECKPOINT_PASSED(INT iTeam, INT iPart, INT iCurrentLoc, INT iLap)
	SCRIPT_EVENT_DATA_FMMC_TEAM_CHECKPOINT_PASSED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_TEAM_CHECKPOINT_PASSED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPart = iPart
	Event.iTeam = iTeam
	Event.iCurrentLoc = iCurrentLoc
	Event.iCurrentLap = iLap
	NET_PRINT("-----------------BROADCAST_FMMC_TEAM_CHECKPOINT_PASSED---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_TEAM_CHECKPOINT_PASSED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_VEHICLE_WEAPON_SOUND
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INt iSound
	VECTOR vCoords
ENDSTRUCT

PROC BROADCAST_FMMC_VEHICLE_WEAPON_SOUND(INT iTeam, INT iSound, VECTOR vCoords)
	
	SCRIPT_EVENT_DATA_FMMC_VEHICLE_WEAPON_SOUND Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_VEHICLE_WEAPON_SOUND
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	Event.iSound = iSound
	Event.vCoords = vCoords
	
	NET_PRINT("-----------------BROADCAST_FMMC_VEHICLE_WEAPON_SOUND---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_VEHICLE_WEAPON_SOUND - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PICKED_UP_VEHICLE_WEAPON
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vPlayerCoords
	INT iPickupType
	INT iTeam
	INT iPickupID
ENDSTRUCT

PROC BROADCAST_FMMC_PICKED_UP_VEHICLE_WEAPON(VECTOR vPlayerCoords, INT iPickupType, INT iTeam, INT iPickupID)
	
	SCRIPT_EVENT_DATA_FMMC_PICKED_UP_VEHICLE_WEAPON Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PICKED_UP_VEHICLE_WEAPON
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vPlayerCoords = vPlayerCoords
	Event.iPickupType = iPickupType
	Event.iTeam = iTeam
	Event.iPickupID = iPickupID
	
	NET_PRINT("-----------------BROADCAST_FMMC_PICKED_UP_VEHICLE_WEAPON---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PICKED_UP_VEHICLE_WEAPON - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_ACTIVATE_VEHICLE_WEAPON
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPickupType
	INT iTeam
ENDSTRUCT

PROC BROADCAST_FMMC_ACTIVATE_VEHICLE_WEAPON(INT iPickupType, INT iTeam)
	SCRIPT_EVENT_DATA_FMMC_ACTIVATE_VEHICLE_WEAPON Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_ACTIVATE_VEHICLE_WEAPON
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPickupType = iPickupType
	Event.iTeam = iTeam
	
	NET_PRINT("-----------------BROADCAST_FMMC_ACTIVATE_VEHICLE_WEAPON---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_ACTIVATE_VEHICLE_WEAPON - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_EXTRA_LIFE_PICKUP
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam = -1
ENDSTRUCT

PROC BROADCAST_FMMC_REQUEST_EXTRA_LIFE_FROM_PICKUP(INT iTeam)
	SCRIPT_EVENT_DATA_FMMC_EXTRA_LIFE_PICKUP Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_ACTIVATE_VEHICLE_WEAPON
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	
	NET_PRINT("-----------------BROADCAST_FMMC_REQUEST_EXTRA_LIFE_FROM_PICKUP---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_REQUEST_EXTRA_LIFE_FROM_PICKUP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_DETONATE_PROP
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iProp
ENDSTRUCT

PROC BROADCAST_FMMC_DETONATE_PROP(INT iProp)
	SCRIPT_EVENT_DATA_FMMC_DETONATE_PROP Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_DETONATE_PROP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iProp = iProp
		
	NET_PRINT("-----------------BROADCAST_FMMC_DETONATE_PROP---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_DETONATE_PROP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_CLAIM_PROP
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventProp
	INT iEventTeam
	INT iEventPart
	TIME_DATATYPE iEventTime
ENDSTRUCT

PROC BROADCAST_FMMC_CLAIM_PROP(INT iProp, INT iTeam, INT iPart, TIME_DATATYPE iTime)
	SCRIPT_EVENT_DATA_FMMC_CLAIM_PROP Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_CLAIM_PROP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iEventProp = iProp
	Event.iEventTeam = iTeam
	Event.iEventPart = iPart
	Event.iEventTime = iTime
		
	NET_PRINT("-----------------BROADCAST_FMMC_CLAIM_PROP---------------------------") NET_NL()
	PRINTLN("[BROADCAST_FMMC_CLAIM_PROP] - iProp: ", iProp)
	PRINTLN("[BROADCAST_FMMC_CLAIM_PROP] - iTeam: ", iTeam)
	PRINTLN("[BROADCAST_FMMC_CLAIM_PROP] - iPart: ", iPart)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_DETONATE_PROP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_TARGET_PROP_SHOT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventProp
	INT iEventTeam
	INT iEventPart
	TIME_DATATYPE iEventTime
ENDSTRUCT

PROC BROADCAST_FMMC_TARGET_PROP_SHOT(INT iProp, INT iTeam, INT iPart, TIME_DATATYPE iTime)
	SCRIPT_EVENT_DATA_FMMC_TARGET_PROP_SHOT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_TARGET_PROP_SHOT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iEventProp = iProp
	Event.iEventTeam = iTeam
	Event.iEventPart = iPart
	Event.iEventTime = iTime
	
	NET_PRINT("-----------------BROADCAST_FMMC_TARGET_PROP_SHOT---------------------------") NET_NL()
	PRINTLN("[BROADCAST_FMMC_CLAIM_PROP] - iProp: ", iProp)
	PRINTLN("[BROADCAST_FMMC_CLAIM_PROP] - iTeam: ", iTeam)
	PRINTLN("[BROADCAST_FMMC_CLAIM_PROP] - iPart: ", iPart)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // Send it to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_DETONATE_PROP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_TOGGLE_PROP_CLAIMING
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventTeam
	INT iEventPart
	BOOL bEventAllowPropClaiming
	BOOL bEventAll
ENDSTRUCT

PROC BROADCAST_FMMC_TOGGLE_PROP_CLAIMING(BOOL bAllowPropClaiming, INT iTeam = -1, INT iPart = -1, BOOL bAffectAll = FALSE)
	SCRIPT_EVENT_DATA_FMMC_TOGGLE_PROP_CLAIMING Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_TOGGLE_PROP_CLAIMING
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iEventTeam = iTeam
	Event.iEventPart = iPart
	Event.bEventAllowPropClaiming = bAllowPropClaiming
	Event.bEventAll	= bAffectAll
		
	NET_PRINT("-----------------BROADCAST_FMMC_TOGGLE_PROP_CLAIMING---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_DETONATE_PROP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_REQUEST_RIGHTFUL_PROP_COLOUR_FROM_HOST
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventPart
	INT iEventProp
	INT iEventPropState
	INT iEventPropColour	
ENDSTRUCT

PROC BROADCAST_FMMC_REQUEST_RIGHTFUL_PROP_COLOUR_FROM_HOST(INT iPart, INT iProp, INT iPropState, INT iPropColour)
	SCRIPT_EVENT_DATA_FMMC_REQUEST_RIGHTFUL_PROP_COLOUR_FROM_HOST Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_REQUEST_RIGHTFUL_PROP_COLOUR_FROM_HOST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iEventPart = iPart
	Event.iEventProp = iProp
	Event.iEventPropState = iPropState
	Event.iEventPropColour = iPropColour
		
	NET_PRINT("-----------------BROADCAST_FMMC_REQUEST_RIGHTFUL_COLOUR_FROM_HOST---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_DETONATE_PROP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_RECEIVE_RIGHTFUL_PROP_COLOUR_FROM_HOST
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventPart
	INT iEventProp
	INT iEventPropState
	INT iEventPropColour	
ENDSTRUCT

PROC BROADCAST_FMMC_RECEIVE_RIGHTFUL_PROP_COLOUR_FROM_HOST(INT iPart, INT iProp, INT iPropState)
	SCRIPT_EVENT_DATA_FMMC_RECEIVE_RIGHTFUL_PROP_COLOUR_FROM_HOST Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_RECEIVE_RIGHTFUL_PROP_COLOUR_FROM_HOST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iEventPart = iPart
	Event.iEventProp = iProp
	Event.iEventPropState = iPropState
		
	NET_PRINT("-----------------BROADCAST_FMMC_RECEIVE_RIGHTFUL_COLOUR_FROM_HOST---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_DETONATE_PROP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_CONDEMNED_DIED
	STRUCT_EVENT_COMMON_DETAILS Details
	
	VECTOR vPos
ENDSTRUCT

PROC BROADCAST_FMMC_CONDEMNED_DIED(VECTOR vPos)
	SCRIPT_EVENT_DATA_FMMC_CONDEMNED_DIED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_CONDEMNED_DIED
	Event.Details.FromPlayerIndex = PLAYER_ID()
		
	Event.vPos = vPos
		
	NET_PRINT("-----------------BROADCAST_FMMC_CONDEMNED_DIED---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CONDEMNED_DIED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

#IF IS_DEBUG_BUILD
STRUCT SCRIPT_EVENT_DATA_FMMC_PAUSE_ALL_TIMERS
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bPauseToggle
ENDSTRUCT

PROC BROADCAST_FMMC_PAUSE_ALL_TIMERS(BOOL bPauseToggle)
	SCRIPT_EVENT_DATA_FMMC_PAUSE_ALL_TIMERS Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PAUSE_ALL_TIMERS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bPauseToggle = bPauseToggle	
	
	NET_PRINT("-----------------BROADCAST_FMMC_PAUSE_ALL_TIMERS---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PAUSE_ALL_TIMERS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_EDIT_ALL_TIMERS
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bIncrement
ENDSTRUCT

PROC BROADCAST_FMMC_EDIT_ALL_TIMERS(BOOL bIncrement)
	SCRIPT_EVENT_DATA_FMMC_EDIT_ALL_TIMERS Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_EDIT_ALL_TIMERS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bIncrement = bIncrement	
	
	NET_PRINT("-----------------BROADCAST_FMMC_EDIT_ALL_TIMERS---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_EDIT_ALL_TIMERS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC
#ENDIF

STRUCT SCRIPT_EVENT_DATA_FMMC_DECREMENT_REMAINING_TIME
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INT iAmountToDecrement
	BOOL bTeamOnly
	INT iParticipantIndex
	BOOL bStealingPoints
	BOOL bDestroyed
ENDSTRUCT
PROC BROADCAST_FMMC_DECREMENT_REMAINING_TIME(INT iTeam, INT iAmountToDecrement, BOOL bTeamOnly = FALSE, INT iParticipantIndex = -1, BOOL bStealingPoints = FALSE, BOOL bDestroyed = FALSE)
	SCRIPT_EVENT_DATA_FMMC_DECREMENT_REMAINING_TIME Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_DECREMENT_REMAINING_TIME
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	Event.iAmountToDecrement = iAmountToDecrement
	Event.bTeamOnly = bTeamOnly
	Event.iParticipantIndex = iParticipantIndex
	Event.bStealingPoints = bStealingPoints
	Event.bDestroyed = bDestroyed
	
	NET_PRINT("-----------------BROADCAST_FMMC_DECREMENT_REMAINING_TIME---------------------------") NET_NL()
	PRINTLN("-----------------Event.iTeam: ",Event.iTeam,"---------------------------")
	PRINTLN("-----------------Event.iAmountToDecrement: ",Event.iAmountToDecrement,"---------------------------")
	PRINTLN("-----------------Event.bTeamOnly: ",Event.bTeamOnly,"---------------------------")
	PRINTLN("-----------------Event.iParticipantIndex: ",Event.iParticipantIndex,"---------------------------")
	PRINTLN("-----------------Event.bStealingPoints: ",Event.bStealingPoints,"---------------------------")
	PRINTLN("-----------------Event.bDestroyed: ",Event.bDestroyed,"---------------------------")
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_DECREMENT_REMAINING_TIME - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_INCREMENT_REMAINING_TIME
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INT iAmountToIncrement
	BOOL bTeamOnly
	INT iParticipantIndex
	BOOL bStealingPoints
	INT iPlayerIndexVictim
ENDSTRUCT
PROC BROADCAST_FMMC_INCREMENT_REMAINING_TIME(INT iTeam, INT iAmountToIncrement, BOOL bTeamOnly, INT iParticipantIndex, BOOL bStealingPoints = FALSE, INT iPlayerIndexVictim = -1)
	SCRIPT_EVENT_DATA_FMMC_INCREMENT_REMAINING_TIME Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_INCREMENT_REMAINING_TIME
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	Event.iAmountToIncrement = iAmountToIncrement
	Event.bTeamOnly = bTeamOnly
	Event.iParticipantIndex = iParticipantIndex
	Event.bStealingPoints = bStealingPoints
	Event.iPlayerIndexVictim = iPlayerIndexVictim
	
	NET_PRINT("-----------------BROADCAST_FMMC_INCREMENT_REMAINING_TIME---------------------------") NET_NL()
	PRINTLN("-----------------Event.iTeam: ",Event.iTeam,"---------------------------")
	PRINTLN("-----------------Event.iAmountToIncrement: ",Event.iAmountToIncrement,"---------------------------")
	PRINTLN("-----------------Event.bTeamOnly: ",Event.bTeamOnly,"---------------------------")
	PRINTLN("-----------------Event.iParticipantIndex: ",Event.iParticipantIndex,"---------------------------")
	PRINTLN("-----------------Event.bStealingPoints: ",Event.bStealingPoints,"---------------------------")
	PRINTLN("-----------------Event.iPlayerIndexVictim: ",Event.iPlayerIndexVictim,"---------------------------")
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_INCREMENT_REMAINING_TIME - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_START_PRE_COUNTDOWN_STOP
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT
PROC BROADCAST_FMMC_START_PRE_COUNTDOWN_STOP()
	SCRIPT_EVENT_DATA_FMMC_START_PRE_COUNTDOWN_STOP Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_START_PRE_COUNTDOWN_STOP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	NET_PRINT("-----------------BROADCAST_FMMC_START_PRE_COUNTDOWN_STOP---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_START_PRE_COUNTDOWN_STOP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_CLEAR_HAS_BEEN_ON_SMALLEST_TEAM
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT
PROC BROADCAST_FMMC_CLEAR_HAS_BEEN_ON_SMALLEST_TEAM()
	SCRIPT_EVENT_DATA_FMMC_CLEAR_HAS_BEEN_ON_SMALLEST_TEAM Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_CLEAR_HAS_BEEN_ON_SMALLEST_TEAM
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	NET_PRINT("-----------------BROADCAST_FMMC_CLEAR_HAS_BEEN_ON_SMALLEST_TEAM---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CLEAR_HAS_BEEN_ON_SMALLEST_TEAM - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_LOCATE_ALERT_SOUND
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT
PROC BROADCAST_FMMC_LOCATE_ALERT_SOUND()
	SCRIPT_EVENT_DATA_FMMC_LOCATE_ALERT_SOUND Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_LOCATE_ALERT_SOUND
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	NET_PRINT("-----------------BROADCAST_FMMC_LOCATE_ALERT_SOUND---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_LOCATE_ALERT_SOUND - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PROP_DESTROYED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iProp
ENDSTRUCT

PROC BROADCAST_FMMC_PROP_DESTROYED(INT iProp)
	SCRIPT_EVENT_DATA_FMMC_PROP_DESTROYED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PROP_DESTROYED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iProp = iProp
	
	NET_PRINT("-----------------BROADCAST_FMMC_PROP_DESTROYED---------------------------") NET_NL()
	PRINTLN("-----------------Event.iProp: ",iProp,"---------------------------")
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_PROP_DESTROYED - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_RESET_ALL_PROPS
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_FMMC_RESET_ALL_PROPS()
	SCRIPT_EVENT_DATA_FMMC_RESET_ALL_PROPS Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_RESET_ALL_PROPS
	Event.Details.FromPlayerIndex = PLAYER_ID()
		
	NET_PRINT("-----------------BROADCAST_FMMC_RESET_ALL_PROPS---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_DETONATE_PROP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_RESET_INDIVIDUAL_PROP
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventProp
ENDSTRUCT

PROC BROADCAST_FMMC_RESET_INDIVIDUAL_PROP(INT iProp)
	SCRIPT_EVENT_DATA_FMMC_RESET_INDIVIDUAL_PROP Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_RESET_INDIVIDUAL_PROP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iEventProp = iProp
	
	NET_PRINT("-----------------BROADCAST_FMMC_RESET_INDIVIDUAL_PROP---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_DETONATE_PROP - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PROP_CLAIMED_SUCCESSFULLY_BY_PART
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventPart
ENDSTRUCT

PROC BROADCAST_FMMC_PROP_CLAIMED_SUCCESSFULLY_BY_PART(INT iPart)
	SCRIPT_EVENT_DATA_FMMC_PROP_CLAIMED_SUCCESSFULLY_BY_PART Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PROP_CLAIMED_SUCCESSFULLY_BY_PART
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iEventPart = iPart
	
	NET_PRINT("-----------------BROADCAST_FMMC_PROP_CLAIMED_SUCCESSFULLY_BY_PART---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_DETONATE_PROP - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC
STRUCT SCRIPT_EVENT_DATA_FMMC_PROP_TURF_WARS_TEAM_LEADING_CHANGED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventTeam
	INT iEventTeamOld
ENDSTRUCT

PROC BROADCAST_FMMC_PROP_TURF_WARS_TEAM_LEADING_CHANGED(INT iEventTeam, INT iEventTeamOld)
	SCRIPT_EVENT_DATA_FMMC_PROP_TURF_WARS_TEAM_LEADING_CHANGED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_TURF_WARS_TEAM_LEADING_CHANGED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iEventTeam = iEventTeam
	Event.iEventTeamOld = iEventTeamOld
	
	NET_PRINT("-----------------BROADCAST_FMMC_PROP_TURF_WARS_TEAM_LEADING_CHANGED---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_DETONATE_PROP - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PROP_CONTESTED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventProp
	INT iEventPart
	BOOL bEventTeamContesting[FMMC_MAX_TEAMS]
ENDSTRUCT

PROC BROADCAST_FMMC_PROP_CONTESTED(INT iProp, BOOL &bTeamContesting[], INT iPart)
	SCRIPT_EVENT_DATA_FMMC_PROP_CONTESTED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PROP_CONTESTED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iEventProp = iProp
	Event.iEventPart = iPart
	
	INT i = 0
	FOR i = 0 TO FMMC_MAX_TEAMS-1
		Event.bEventTeamContesting[i] = bTeamContesting[i]
	ENDFOR
	
	NET_PRINT("-----------------BROADCAST_FMMC_PROP_CONTESTED---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_DETONATE_PROP - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PROP_CLAIMED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventPart
	INT iEventProp
ENDSTRUCT

PROC BROADCAST_FMMC_PROP_CLAIMED(INT iPart, INT iProp)
	SCRIPT_EVENT_DATA_FMMC_PROP_CLAIMED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PROP_CLAIMED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iEventPart = iPart
	Event.iEventProp = iProp
	
	NET_PRINT("-----------------BROADCAST_FMMC_PROP_CLAIMED---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_DETONATE_PROP - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PLAY_PULSE_SFX
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_FMMC_PLAY_PULSE_SFX()
	SCRIPT_EVENT_DATA_FMMC_PLAY_PULSE_SFX Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PLAY_PULSE_SFX
	Event.Details.FromPlayerIndex = PLAYER_ID()
		
	NET_PRINT("-----------------BROADCAST_FMMC_PLAY_PULSE_SFX---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PLAY_PULSE_SFX - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_HARD_TARGET_NEW_TARGET_SHARD
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iNewTargets[FMMC_MAX_TEAMS]
	INT iTeamsActive
	INT iOnlyThisPart
ENDSTRUCT

PROC BROADCAST_FMMC_HARD_TARGET_NEW_TARGET_SHARD(INT &iNewTargets[], INT iTeamsActive, INT iOnlyThisPart = -1)
	SCRIPT_EVENT_DATA_FMMC_HARD_TARGET_NEW_TARGET_SHARD Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_HARD_TARGET_NEW_TARGET_SHARD
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT i = 0
	FOR i = 0 TO FMMC_MAX_TEAMS-1
		Event.iNewTargets[i] = iNewTargets[i]		
	ENDFOR
	
	Event.iTeamsActive = iTeamsActive
	Event.iOnlyThisPart = iOnlyThisPart
	
	NET_PRINT("-----------------BROADCAST_FMMC_HARD_TARGET_NEW_TARGET_SHARD---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_HARD_TARGET_NEW_TARGET_SHARD - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_BOMBUSHKA_NEW_ROUND_SHARD
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iScoreTeam1
	INT iScoreTeam2
ENDSTRUCT

PROC BROADCAST_FMMC_BOMBUSHKA_NEW_ROUND_SHARD(INT iScoreTeam1, INT iScoreTeam2)
	SCRIPT_EVENT_DATA_FMMC_BOMBUSHKA_NEW_ROUND_SHARD Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_BOMBUSHKA_NEW_ROUND_SHARD
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iScoreTeam1 = iScoreTeam1
	Event.iScoreTeam2 = iScoreTeam2
	
	NET_PRINT("-----------------BROADCAST_FMMC_BOMBUSHKA_NEW_ROUND_SHARD---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_BOMBUSHKA_NEW_ROUND_SHARD - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

CONST_INT SHOWDOWNDMG_STANDARD	0
CONST_INT SHOWDOWNDMG_EXPLOSION	1
CONST_INT SHOWDOWNDMG_DRAIN		2

STRUCT SCRIPT_EVENT_DATA_FMMC_SHOWDOWN_DAMAGE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iVictimPart
	INT iAttackerPart
	INT iDmgType
	
	INT iDamageFrame
ENDSTRUCT

PROC BROADCAST_FMMC_SHOWDOWN_DAMAGE(INT iVictimPart, INT iAttackerPart, INT iDmgType)
	SCRIPT_EVENT_DATA_FMMC_SHOWDOWN_DAMAGE Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_SHOWDOWN_DAMAGE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iVictimPart = iVictimPart
	Event.iAttackerPart = iAttackerPart
	Event.iDmgType = iDmgType
	Event.iDamageFrame = GET_FRAME_COUNT()
	
	PRINTLN("[SHOWDOWN] Sending Showdown damage event! Victim is part ", iVictimPart, " attacker is part ", iAttackerPart, " damage type is ", iDmgType)
	NET_PRINT("-----------------BROADCAST_FMMC_SHOWDOWN_DAMAGE---------------------------") NET_NL()
	
	INT iPlayerFlags
	
	IF iVictimPart = -1
		iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	ELSE
		PLAYER_INDEX PlayerId = NETWORK_GET_PLAYER_INDEX(INT_TO_PARTICIPANTINDEX(iAttackerPart))
		SET_BIT(iPlayerFlags, NATIVE_TO_INT(PlayerID))
		SET_BIT(iPlayerFlags, NATIVE_TO_INT(PLAYER_ID()))
	ENDIF
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_SHOWDOWN_DAMAGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_SHOWDOWN_ELIMINATION
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iVictimPart
	INT iAttackerPart
ENDSTRUCT

PROC BROADCAST_FMMC_SHOWDOWN_ELIMINATION(INT iVictimPart, INT iAttackerPart)
	SCRIPT_EVENT_DATA_FMMC_SHOWDOWN_ELIMINATION Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_SHOWDOWN_ELIMINATION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iVictimPart = iVictimPart
	Event.iAttackerPart = iAttackerPart
	
	PRINTLN("[SHOWDOWN} Sending Showdown elimination event! Victim is part ", iVictimPart, " attacker is part ", iAttackerPart)
	NET_PRINT("-----------------BROADCAST_FMMC_SHOWDOWN_ELIMINATION---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_SHOWDOWN_ELIMINATION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_CCTV_REACHED_DESTINATION
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCCTVIndex
ENDSTRUCT

PROC BROADCAST_FMMC_CCTV_REACHED_DESTINATION(INT iCCTVIndex)
	SCRIPT_EVENT_DATA_FMMC_CCTV_REACHED_DESTINATION Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_CCTV_REACHED_DESTINATION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iCCTVIndex = iCCTVIndex
	
	NET_PRINT("-----------------BROADCAST_FMMC_CCTV_REACHED_DESTINATION---------------------------") NET_NL()
	PRINTLN("[CCTV][CAM ", iCCTVIndex, "] BROADCAST_FMMC_CCTV_REACHED_DESTINATION")
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CCTV_REACHED_DESTINATION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_METAL_DETECTOR
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iZone
	INT iDetectedPart
	VECTOR vDetectionPos
	BOOL bExtremeWeapon
ENDSTRUCT

PROC BROADCAST_FMMC_METAL_DETECTOR_ALERTED(INT iZone, INT iDetectedPart, VECTOR vDetectionPos, BOOL bExtremeWeapon)
	SCRIPT_EVENT_DATA_FMMC_METAL_DETECTOR Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_METAL_DETECTOR_ALERTED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iZone = iZone
	Event.iDetectedPart = iDetectedPart
	Event.vDetectionPos = vDetectionPos
	Event.bExtremeWeapon = bExtremeWeapon
	
	NET_PRINT("-----------------BROADCAST_FMMC_METAL_DETECTOR_ALERTED---------------------------") NET_NL()
	PRINTLN("[MetalDetector] iZone: ", iZone, " || iDetectedPart: ", iDetectedPart, " || vDetectionPos: ", vDetectionPos, " || bExtremeWeapon: ", bExtremeWeapon)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_METAL_DETECTOR_ALERTED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC


STRUCT SCRIPT_EVENT_DATA_FMMC_PHONE_EMP_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bActivateEMP
	BOOL bDeactivateEMP
ENDSTRUCT

PROC BROADCAST_FMMC_PHONE_EMP_EVENT(BOOL bActivateEMP, BOOL bDeactivateEMP)
	SCRIPT_EVENT_DATA_FMMC_PHONE_EMP_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PHONE_EMP_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.bActivateEMP = bActivateEMP
	Event.bDeactivateEMP = bDeactivateEMP
	
	NET_PRINT("-----------------BROADCAST_FMMC_PHONE_EMP_EVENT---------------------------") NET_NL()
	PRINTLN("[PhoneEMP] bActivateEMP: ", bActivateEMP, " || bDeactivateEMP: ", bDeactivateEMP)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PHONE_EMP_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_INTERACT_WITH_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iObj
	INT iInteractWithParticipant
	
	BOOL bDeletePersistentProps
	BOOL bExplodePersistentProps
	
	INT iEndObjectiveASAP_Rule = -1
	INT iEndObjectiveASAP_Team = -1
		
	BOOL bPlantedLeftSideBomb
	BOOL bPlantedRightSideBomb
	
	INT iBombPlanterIndex = -1
	
	NETWORK_INDEX niPropBag
	BOOL bSwapInPropBagLocally
	BOOL bSwapOutPropBagLocally
ENDSTRUCT
PROC BROADCAST_FMMC_INTERACT_WITH_EVENT(INT iObj, BOOL bDeletePersistentProps = FALSE, BOOL bExplodePersistentProps = FALSE, BOOL bPlantedLeftSideBomb = FALSE, BOOL bPlantedRightSideBomb = FALSE, INT iBombPlanterIndex = -1, NETWORK_INDEX niPropBag = NULL, BOOL bSwapInPropBagLocally = FALSE,	BOOL bSwapOutPropBagLocally = FALSE, INT iEndObjectiveASAP_Rule = -1, INT iEndObjectiveASAP_Team = -1)
	SCRIPT_EVENT_DATA_FMMC_INTERACT_WITH_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_INTERACT_WITH_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iObj = iObj
	Event.iInteractWithParticipant = PARTICIPANT_ID_TO_INT()
	
	Event.bDeletePersistentProps = bDeletePersistentProps
	Event.bExplodePersistentProps = bExplodePersistentProps
	
	Event.iEndObjectiveASAP_Team = iEndObjectiveASAP_Team
	Event.iEndObjectiveASAP_Rule = iEndObjectiveASAP_Rule
	
	Event.bPlantedLeftSideBomb = bPlantedLeftSideBomb
	Event.bPlantedRightSideBomb = bPlantedRightSideBomb
	
	Event.iBombPlanterIndex = iBombPlanterIndex
	
	Event.niPropBag = niPropBag
	Event.bSwapInPropBagLocally = bSwapInPropBagLocally
	Event.bSwapOutPropBagLocally = bSwapOutPropBagLocally
	
	NET_PRINT("-----------------BROADCAST_FMMC_INTERACT_WITH_EVENT---------------------------") NET_NL()
	PRINTLN("[InteractWith] iObj: ", iObj, " || bExplodePersistentProps: ", bExplodePersistentProps, " || bPlantedLeftSideBomb: ", bPlantedLeftSideBomb, " || bPlantedRightSideBomb: ", bPlantedRightSideBomb, " || iBombPlanterIndex: ", iBombPlanterIndex, " || iEndObjectiveASAP_Team: ", iEndObjectiveASAP_Team, " || iEndObjectiveASAP_Rule: ", iEndObjectiveASAP_Rule)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("[InteractWith] BROADCAST_FMMC_INTERACT_WITH_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_UPDATE_DOOR_LINKED_OBJS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iDoorHasLinkedEntityBS
ENDSTRUCT
PROC BROADCAST_FMMC_UPDATE_DOOR_LINKED_OBJS_EVENT(INT iDoorHasLinkedEntityBS)
	SCRIPT_EVENT_DATA_FMMC_UPDATE_DOOR_LINKED_OBJS Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_UPDATE_DOOR_LINKED_ENTITIES
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iDoorHasLinkedEntityBS = iDoorHasLinkedEntityBS
	
	NET_PRINT("-----------------BROADCAST_FMMC_UPDATE_DOOR_LINKED_OBJS_EVENT---------------------------") NET_NL()
	PRINTLN("[MCDoors] BROADCAST_FMMC_UPDATE_DOOR_LINKED_OBJS_EVENT | iDoorHasLinkedEntityBS: ", iDoorHasLinkedEntityBS)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("[MCDoors] BROADCAST_FMMC_UPDATE_DOOR_LINKED_OBJS_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_ZONE_TIMER
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iZone
	BOOL bStartTimer
	BOOL bStopTimer
	BOOL bSkipTimer
	BOOL bHideTimer
	BOOL bMarkTimerAsComplete
ENDSTRUCT
PROC BROADCAST_FMMC_ZONE_TIMER_EVENT(INT iZone, BOOL bStartTimer = FALSE, BOOL bStopTimer = FALSE, BOOL bSkipTimer = FALSE, BOOL bHideTimer = FALSE, BOOL bMarkTimerAsComplete = FALSE)
	SCRIPT_EVENT_DATA_FMMC_ZONE_TIMER Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_ZONE_TIMER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iZone = iZone
	Event.bStartTimer = bStartTimer
	Event.bStopTimer = bStopTimer
	Event.bSkipTimer = bSkipTimer
	Event.bHideTimer = bHideTimer
	Event.bMarkTimerAsComplete = bMarkTimerAsComplete
	
	NET_PRINT("-----------------BROADCAST_FMMC_ZONE_TIMER_EVENT---------------------------") NET_NL()
	PRINTLN("[ZONETIMER] iZone: ", iZone, " || bStartTimer: ", bStartTimer, " || bStopTimer: ", bStopTimer, " || bSkipTimer: ", bSkipTimer, " || bHideTimer: ", bHideTimer, " || bMarkTimerAsComplete: ", bMarkTimerAsComplete)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("[ZONETIMER] BROADCAST_FMMC_ZONE_TIMER_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_POISON_GAS
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bTriggerGas
ENDSTRUCT
PROC BROADCAST_FMMC_POISON_GAS_EVENT(BOOL bTriggerGas)
	SCRIPT_EVENT_DATA_FMMC_POISON_GAS Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_POISON_GAS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.bTriggerGas = bTriggerGas
	
	NET_PRINT("-----------------BROADCAST_FMMC_POISON_GAS_EVENT---------------------------") NET_NL()
	PRINTLN("[PGAS] bTriggerGas: ", bTriggerGas)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("[PGAS] BROADCAST_FMMC_POISON_GAS_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_DIRECTIONAL_DOOR_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iDoor
	BOOL bUnlock
	BOOL bRelock
	FLOAT fAutomaticDistance
ENDSTRUCT
PROC BROADCAST_FMMC_DIRECTIONAL_DOOR_EVENT(INT iDoor, BOOL bUnlock = FALSE, BOOL bRelock = FALSE, FLOAT fAutomaticDistance = -1.0)
	SCRIPT_EVENT_DATA_FMMC_DIRECTIONAL_DOOR_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_DIRECTIONAL_DOOR_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iDoor = iDoor
	Event.bUnlock = bUnlock
	Event.bRelock = bRelock
	Event.fAutomaticDistance = fAutomaticDistance
	
	NET_PRINT("-----------------BROADCAST_FMMC_DIRECTIONAL_DOOR_EVENT---------------------------") NET_NL()
	PRINTLN("[DirDoorLock] iDoor: ", iDoor, " | bUnlock: ", bUnlock, " | bRelock: ", bRelock, " | fAutomaticDistance: ", fAutomaticDistance)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("[DirDoorLock] BROADCAST_FMMC_DIRECTIONAL_DOOR_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_TRIGGER_AGGRO_FOR_TEAM_LEGACY
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
ENDSTRUCT
PROC BROADCAST_FMMC_TRIGGER_AGGRO_FOR_TEAM_LEGACY(INT iTeam) // used in og mc.
	SCRIPT_EVENT_DATA_FMMC_TRIGGER_AGGRO_FOR_TEAM_LEGACY Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_TRIGGER_AGGRO_FOR_TEAM_LEGACY
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iTeam = iTeam
	
	NET_PRINT("-----------------BROADCAST_FMMC_TRIGGER_AGGRO_FOR_TEAM_LEGACY---------------------------") NET_NL()
	PRINTLN("iTeam: ", iTeam)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_TRIGGER_AGGRO_FOR_TEAM_LEGACY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_BLOCK_WANTED_CONE_RESPONSE_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bSetBlockWantedConeResponse
	BOOL bClearBlockWantedConeResponse
	BOOL bSeenIllegal
	INT iVeh
ENDSTRUCT

PROC BROADCAST_FMMC_BLOCK_WANTED_CONE_RESPONSE_EVENT(BOOL bSetBlockWantedConeResponse, BOOL bClearBlockWantedConeResponse, INT iVeh, BOOL bSeenIllegal)
	SCRIPT_EVENT_DATA_FMMC_BLOCK_WANTED_CONE_RESPONSE_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_BLOCK_WANTED_CONE_RESPONSE_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.bSetBlockWantedConeResponse = bSetBlockWantedConeResponse
	Event.bClearBlockWantedConeResponse = bClearBlockWantedConeResponse
	Event.iVeh = iVeh
	Event.bSeenIllegal = bSeenIllegal
	
	NET_PRINT("-----------------BROADCAST_FMMC_BLOCK_WANTED_CONE_RESPONSE_EVENT---------------------------") NET_NL()
	PRINTLN("[BlockWantedConeResponse] bSetBlockWantedConeResponse: ", bSetBlockWantedConeResponse, " bClearBlockWantedConeResponse: ", bClearBlockWantedConeResponse," iVeh: ", iVeh, " bSeenIllegal: ", bSeenIllegal)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_BLOCK_WANTED_CONE_RESPONSE_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

CONST_INT ciUPDATE_DOOR_OFF_RULE_METHOD__KEYCARD		0
CONST_INT ciUPDATE_DOOR_OFF_RULE_METHOD__HACKING		1
CONST_INT ciUPDATE_DOOR_OFF_RULE_METHOD__THERMITE		2
CONST_INT ciUPDATE_DOOR_OFF_RULE_METHOD__OBJ_DESTROYED	3
CONST_INT ciUPDATE_DOOR_OFF_RULE_METHOD__HOLDING_BUTTON	4
CONST_INT ciUPDATE_DOOR_OFF_RULE_METHOD__TIMED_OPENING	5

STRUCT SCRIPT_EVENT_DATA_FMMC_UPDATE_DOOR_OFF_RULE_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bSetUpdateDoorOffRule
	INT iDoor
	INT iMethodUsed = ciUPDATE_DOOR_OFF_RULE_METHOD__KEYCARD
ENDSTRUCT

PROC BROADCAST_FMMC_UPDATE_DOOR_OFF_RULE_EVENT(BOOL bSetUpdateDoorOffRule, INT iDoor, INT iMethodUsed)
	SCRIPT_EVENT_DATA_FMMC_UPDATE_DOOR_OFF_RULE_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_UPDATE_DOOR_OFF_RULE_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.bSetUpdateDoorOffRule = bSetUpdateDoorOffRule
	Event.iDoor = iDoor
	Event.iMethodUsed = iMethodUsed
	
	NET_PRINT("-----------------BROADCAST_FMMC_UPDATE_DOOR_OFF_RULE_EVENT---------------------------") NET_NL()
	PRINTLN("[UpdateDoorOffRule] bSetUpdateDoorOffRule: ", bSetUpdateDoorOffRule, " iDoor: ", iDoor, " iMethodUsed: ", iMethodUsed)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_UPDATE_DOOR_OFF_RULE_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_UPDATE_MINIGAME_OFF_RULE_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bSetHackCompleteOffRule
	INT iObj
ENDSTRUCT

PROC BROADCAST_FMMC_UPDATE_MINIGAME_OFF_RULE_EVENT(BOOL bSetHackCompleteOffRule, INT iObj)
	SCRIPT_EVENT_DATA_FMMC_UPDATE_MINIGAME_OFF_RULE_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_UPDATE_MINIGAME_OFF_RULE_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.bSetHackCompleteOffRule = bSetHackCompleteOffRule
	Event.iObj = iObj
	
	NET_PRINT("-----------------BROADCAST_FMMC_UPDATE_MINIGAME_OFF_RULE_EVENT---------------------------") NET_NL()
	PRINTLN("[UpdateMinigameOffRule] bSetHackCompleteOffRule: ", bSetHackCompleteOffRule, " iObj: ", iObj)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_UPDATE_MINIGAME_OFF_RULE_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_COP_DECOY_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT  iPed
	BOOL bStartedDecoy
	BOOL bDecoyExpired
	BOOL bDecoyShouldFlee
ENDSTRUCT

PROC BROADCAST_FMMC_COP_DECOY_EVENT(INT iPed, BOOL bStartedDecoy, BOOL bDecoyExpired, BOOL bDecoyShouldFlee)
	SCRIPT_EVENT_DATA_FMMC_COP_DECOY_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_COP_DECOY_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iPed = iPed
	Event.bStartedDecoy = bStartedDecoy
	Event.bDecoyExpired = bDecoyExpired
	Event.bDecoyShouldFlee = bDecoyShouldFlee
	
	NET_PRINT("-----------------BROADCAST_FMMC_COP_DECOY_EVENT---------------------------") NET_NL()
	PRINTLN("[CopDecoy][DistractionAbility] iPed: ", iPed, " bStartedDecoy: ", bStartedDecoy, " bDecoyExpired: ", bDecoyExpired, " bDecoyShouldFlee: ", bDecoyShouldFlee)
	DEBUG_PRINTCALLSTACK()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_COP_DECOY_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_COP_BEHAVIOUR_OVERRIDE_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT  iPed
	BOOL bForceCopOverride
ENDSTRUCT

PROC BROADCAST_FMMC_COP_BEHAVIOUR_OVERRIDE_EVENT(INT iPed, BOOL bForceCopOverride)
	SCRIPT_EVENT_DATA_FMMC_COP_BEHAVIOUR_OVERRIDE_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_COP_BEHAVIOUR_OVERRIDE_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iPed = iPed
	Event.bForceCopOverride = bForceCopOverride
	
	NET_PRINT("-----------------BROADCAST_FMMC_COP_BEHAVIOUR_OVERRIDE_EVENT---------------------------") NET_NL()
	PRINTLN("[CopOverride] iPed: ", iPed, " bForceCopOverride: ", bForceCopOverride)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_COP_BEHAVIOUR_OVERRIDE_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC


STRUCT SCRIPT_EVENT_DATA_VAULT_DRILL_EFFECT_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT 			iOrderedParticipant 
	INT 			iCentreObjectIndex
	NETWORK_INDEX 	niDevice
	BOOL 			bRunning
	BOOL 			bLaser
	FLOAT 			fDistanceForward
	FLOAT 			fPower

ENDSTRUCT



PROC BROADCAST_VAULT_DRILL_EFFECT_EVENT(INT iOrderedParticipant, INT iCentreObjectIn = -1, NETWORK_INDEX niDev = NULL, BOOL bRunning = TRUE, BOOL bLaser = TRUE)
	SCRIPT_EVENT_DATA_VAULT_DRILL_EFFECT_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_VAULT_DRILL_EFFECT_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iOrderedParticipant = iOrderedParticipant
	
	IF niDev != NULL
		Event.niDevice = niDev
		PRINTLN("[VAULT_DRILL_PTFX] - SET: Event.niDevice")
	ENDIF
	
	Event.iCentreObjectIndex	=	iCentreObjectIn 
	Event.bRunning 				= 	bRunning
	Event.bLaser   				= 	bLaser
	
	NET_PRINT("-----------------BROADCAST_VAULT_DRILL_EFFECT_EVENT---------------------------") NET_NL()
	PRINTLN("[VAULT_DRILL_PTFX] iOrderedParticipant: ", iOrderedParticipant, " bRunning: ", bRunning, " bLaser: ", bLaser)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_VAULT_DRILL_EFFECT_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC


STRUCT SCRIPT_EVENT_DATA_VAULT_DRILL_PROGRESS
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iObj
	INT iProgress
	INT iDiscs
ENDSTRUCT


PROC BROADCAST_SCRIPT_EVENT_FMMC_VAULT_DRILL_PROGRESS(INT iObj, INT iProgress, INT iDiscs)
	
	SCRIPT_EVENT_DATA_VAULT_DRILL_PROGRESS Event
	
	Event.Details.Type = SCRIPT_EVENT_VAULT_DRILL_PROGRESS_EVENT
	Event.iObj 			= iObj
	Event.iProgress 	= iProgress
	Event.iDiscs 		= iDiscs
	
	#IF IS_DEBUG_BUILD
		NET_PRINT("-----------------BROADCAST_SCRIPT_EVENT_FMMC_VAULT_DRILL_PROGRESS---------------------------") NET_NL()
		PRINTLN("[VAULT_DRILL_PROGRESS] iObj: ", iObj, " iProgress: ", iProgress, " iDiscs: ", iDiscs)
	#ENDIF
	
	INT iPlayerFlags 	= ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_VAULT_DRILL_EFFECT_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC



STRUCT SCRIPT_EVENT_DATA_FMMC_THERMITE_EFFECT_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iOrderedParticipant 
	INT iObj
	NETWORK_INDEX niObj
	VECTOR vDripOffset
	VECTOR vSparkOffset 
	BOOL bStartThermite
	BOOL bStartSparkDieOff
	BOOL bStartProcessing
	BOOL bBreakKeypadObj
	BOOL bClearProcessing
	BOOL bReduceChargeAmount
ENDSTRUCT

PROC BROADCAST_FMMC_THERMITE_EFFECT_EVENT(INT iOrderedParticipant, INT iObj, NETWORK_INDEX niObj, VECTOR vDripOffset, VECTOR vSparkOffset, BOOL bStartThermite, BOOL bStartSparkDieOff, BOOL bStartProcessing, BOOL bBreakKeypadObj, BOOL bClearProcessing, BOOL bReduceChargeAmount = FALSE)
	SCRIPT_EVENT_DATA_FMMC_THERMITE_EFFECT_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_THERMITE_EFFECT_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iOrderedParticipant = iOrderedParticipant
	Event.iObj = iObj
	Event.niObj = niObj
	Event.vDripOffset = vDripOffset
	Event.vSparkOffset = vSparkOffset
	Event.bStartThermite = bStartThermite
	Event.bStartSparkDieOff = bStartSparkDieOff
	Event.bStartProcessing = bStartProcessing
	Event.bBreakKeypadObj = bBreakKeypadObj
	Event.bClearProcessing = bClearProcessing
	Event.bReduceChargeAmount = bReduceChargeAmount
	
	NET_PRINT("-----------------BROADCAST_FMMC_THERMITE_EFFECT_EVENT---------------------------") NET_NL()
	PRINTLN("[THERMITE] iOrderedParticipant: ", iOrderedParticipant, " iObj: ", iObj, " bStartThermite: ", bStartThermite, " bStartSparkDieOff: ", bStartSparkDieOff, " bStartProcessing: ", bStartProcessing, " bBreakKeypadObj: ", bBreakKeypadObj, " bClearProcessing: ", bClearProcessing, " bReduceChargeAmount: ", bReduceChargeAmount)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_THERMITE_EFFECT_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_ACTIVATE_ELEVATOR
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iElevator
ENDSTRUCT

PROC BROADCAST_FMMC_ACTIVATE_ELEVATOR(INT iElevator)
	SCRIPT_EVENT_DATA_FMMC_ACTIVATE_ELEVATOR Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_ACTIVATE_ELEVATOR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iElevator = iElevator
	
	NET_PRINT("-----------------BROADCAST_FMMC_ACTIVATE_ELEVATOR-----------------") NET_NL()
	PRINTLN("[JS][ELEVATORS] iElevator: ", iElevator)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_ACTIVATE_ELEVATOR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_CALL_ELEVATOR
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iElevator
ENDSTRUCT

PROC BROADCAST_FMMC_CALL_ELEVATOR(INT iElevator)
	SCRIPT_EVENT_DATA_FMMC_CALL_ELEVATOR Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_CALL_ELEVATOR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iElevator = iElevator
	
	NET_PRINT("-----------------BROADCAST_FMMC_CALL_ELEVATOR-----------------") NET_NL()
	PRINTLN("[JS][ELEVATORS] iElevator: ", iElevator)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_CALL_ELEVATOR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DM_PASS_THE_BOMB_TAGGED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iParticipantToTag = -1
	INT iTaggerParticipant = -1
	BOOL bPassedOver = FALSE
ENDSTRUCT

PROC BROADCAST_DM_PASS_THE_BOMB_TAGGED(INT iParticipantToTag, INT iTaggerParticipant, BOOL bPassedOver)
	SCRIPT_EVENT_DATA_DM_PASS_THE_BOMB_TAGGED Event
	Event.Details.Type = SCRIPT_EVENT_DM_PASS_THE_BOMB_TAGGED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iParticipantToTag = iParticipantToTag
	Event.iTaggerParticipant = iTaggerParticipant
	Event.bPassedOver = bPassedOver
	
	PRINTLN("[PASSTHEBOMB][PTBMAJOR] Sending Pass The Bomb damage event! Participant ", iParticipantToTag, " was hit by bomb carrier participant ", iTaggerParticipant, " | bPassedOver: ", bPassedOver)
	DEBUG_PRINTCALLSTACK()
	
	NET_PRINT("-----------------BROADCAST_DM_PASS_THE_BOMB_TAGGED---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DM_PASS_THE_BOMB_TAGGED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DM_PLAYER_BLIP

	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL ShowBlip

ENDSTRUCT

PROC BROADCAST_DM_FORCE_PLAYER_BLIP(BOOL bShowBlip)

	SCRIPT_EVENT_DATA_DM_PLAYER_BLIP Event
	Event.Details.Type = SCRIPT_EVENT_DM_PLAYER_BLIP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.ShowBlip = bShowBlip
	
	PRINTLN("[DM_BLIP_EVENT] Sending Deathmatch Force Player Blip event! Player ", NETWORK_PLAYER_ID_TO_INT(), ", bShowBlip: ", bShowBlip)
	DEBUG_PRINTCALLSTACK()
	
	NET_PRINT("-----------------BROADCAST_DM_FORCE_PLAYER_BLIP-----------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DM_BLIP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DM_GIVE_TEAM_LIVES

	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INT iExtraLives

ENDSTRUCT

PROC BROADCAST_DM_GIVE_TEAM_LIVES(INT iTeam, INT iExtraLives)

	SCRIPT_EVENT_DATA_DM_GIVE_TEAM_LIVES Event
	Event.Details.Type = SCRIPT_EVENT_DM_GIVE_TEAM_LIVES
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	Event.iExtraLives = iExtraLives
	
	PRINTLN("[DM_ONKILL_EVENT] Sending Deathmatch Give Team Lives event! Team: ", iTeam, ", Lives: ", iExtraLives)
	DEBUG_PRINTCALLSTACK()
	
	NET_PRINT("-----------------BROADCAST_DM_GIVE_TEAM_LIVES-----------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DM_GIVE_TEAM_LIVES - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DM_PLAYER_OUT_OF_BOUNDS

	STRUCT_EVENT_COMMON_DETAILS Details

ENDSTRUCT

PROC BROADCAST_DM_PLAYER_OUT_OF_BOUNDS()
	
	SCRIPT_EVENT_DATA_DM_PLAYER_OUT_OF_BOUNDS Event
	Event.Details.Type = SCRIPT_EVENT_DM_PLAYER_OUT_OF_BOUNDS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	PRINTLN("[DM_BOUNDS] Sending Deathmatch Player Out Of Bounds event! Player: ", NATIVE_TO_INT(PLAYER_ID()))
	DEBUG_PRINTCALLSTACK()
	
	NET_PRINT("--------------BROADCAST_DM_PLAYER_OUT_OF_BOUNDS---------------") NET_NL()
	
	INT iPlayerFlags = SPECIFIC_PLAYER(PLAYER_ID())
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DM_PLAYER_OUT_OF_BOUNDS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

// KING OF THE HILL // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
CONST_INT ciKOTH_FLASH_REASON__ENTER_AREA		0
CONST_INT ciKOTH_FLASH_REASON__LEAVE_AREA		1
CONST_INT ciKOTH_FLASH_REASON__TEAM_ASSIGNED	2
CONST_INT ciKOTH_FLASH_REASON__CONTESTED		3

STRUCT SCRIPT_EVENT_DATA_KOTH_FLASH_AREA
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iAreaToFlash = -1
	INT iFlashAlpha = 100
	INT iTimeStamp
	
	INT iReasonToFlash = ciKOTH_FLASH_REASON__ENTER_AREA
	INT iNewTeam = -1
	INT iOldTeam = -1
	
ENDSTRUCT
PROC BROADCAST_KOTH_FLASH_AREA(INT iAreaToFlash, INT iFlashAlpha = 100, INT iReasonToFlash = ciKOTH_FLASH_REASON__ENTER_AREA, INT iNewTeam = -1, INT iOldTeam = -1)
	SCRIPT_EVENT_DATA_KOTH_FLASH_AREA Event
	Event.Details.Type = SCRIPT_EVENT_KOTH_FLASH_AREA
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iAreaToFlash = iAreaToFlash
	Event.iFlashAlpha = iFlashAlpha
	Event.iReasonToFlash = iReasonToFlash
	
	Event.iNewTeam = iNewTeam
	Event.iOldTeam = iOldTeam
	
	IF NETWORK_IS_ACTIVITY_SESSION()
		Event.iTimeStamp = NATIVE_TO_INT(GET_NETWORK_TIME())
	ENDIF
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	PRINTLN("[KOTH] BROADCAST_KOTH_FLASH_AREA - Broadcasting to flash area ", iAreaToFlash, " with alpha ", iFlashAlpha, " for reason ", iReasonToFlash)
ENDPROC

STRUCT SCRIPT_EVENT_DATA_KOTH_SET_CAPTURE_DIR
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iHill
	FLOAT fCaptureDir
	
	INT iTimestamp
ENDSTRUCT
PROC BROADCAST_KOTH_SET_CAPTURE_DIR(INT iHill, FLOAT fCaptureDir)

	SCRIPT_EVENT_DATA_KOTH_SET_CAPTURE_DIR Event
	Event.Details.Type = SCRIPT_EVENT_KOTH_SET_CAPTURE_DIR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iHill = iHill
	Event.fCaptureDir = fCaptureDir
	
	IF NETWORK_IS_ACTIVITY_SESSION()
		Event.iTimestamp = NATIVE_TO_INT(GET_NETWORK_TIME())
	ENDIF
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	PRINTLN("[KOTH] BROADCAST_KOTH_SET_CAPTURE_DIR - Broadcasting to set capture dir to ", fCaptureDir, " for Hill ", iHill)
ENDPROC

STRUCT SCRIPT_EVENT_DATA_KOTH_GIVE_SCORE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iScoreArea
	INT iScoreToGive
	BOOL bVisualsOnly
	INT iTimestamp
	
	VECTOR vOverrideNumberPos
ENDSTRUCT

PROC BROADCAST_KOTH_GIVE_SCORE(INT iScoreArea, VECTOR vOverrideNumberPos, INT iScoreToGive = 0, BOOL bVisualsOnly = FALSE)	
	SCRIPT_EVENT_DATA_KOTH_GIVE_SCORE Event
	Event.Details.Type = SCRIPT_EVENT_KOTH_GIVE_SCORE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iScoreArea = iScoreArea
	Event.iScoreToGive = iScoreToGive
	Event.bVisualsOnly = bVisualsOnly
	Event.vOverrideNumberPos = vOverrideNumberPos
	
	IF NETWORK_IS_ACTIVITY_SESSION()
		Event.iTimestamp = NATIVE_TO_INT(GET_NETWORK_TIME())
	ENDIF
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	PRINTLN("[KOTH] BROADCAST_KOTH_GIVE_SCORE - Broadcasting to give score from area ", iScoreArea)
ENDPROC

STRUCT SCRIPT_EVENT_DATA_KOTH_PLAYER_GOT_A_KILL
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iKillerParticipant = -1
	INT iVictimParticipant = -1
	VECTOR vVictimCoords
ENDSTRUCT
PROC BROADCAST_KOTH_PLAYER_GOT_A_KILL(INT iKillerParticipant, INT iVictimParticipant, VECTOR vVictimCoords)
	SCRIPT_EVENT_DATA_KOTH_PLAYER_GOT_A_KILL Event
	Event.Details.Type = SCRIPT_EVENT_KOTH_PLAYER_GOT_A_KILL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iKillerParticipant = iKillerParticipant
	Event.iVictimParticipant = iVictimParticipant
	Event.vVictimCoords = vVictimCoords
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	PRINTLN("[KOTH] SCRIPT_EVENT_DATA_KOTH_PLAYER_GOT_A_KILL - Broadcasting that participant ", iKillerParticipant, " killed participant ", iVictimParticipant, " | vVictimCoords: ", Event.vVictimCoords)
ENDPROC

STRUCT SCRIPT_EVENT_DATA_KOTH_PLAYER_EXPLODED_A_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iKillerParticipant
	VECTOR vVehicleCoords
ENDSTRUCT
PROC BROADCAST_KOTH_PLAYER_EXPLODED_A_VEHICLE(VECTOR vVehicleCoords)
	SCRIPT_EVENT_DATA_KOTH_PLAYER_EXPLODED_A_VEHICLE Event
	Event.Details.Type = SCRIPT_EVENT_KOTH_PLAYER_EXPLODED_AN_UNATTENDED_VEHICLE_HILL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iKillerParticipant = PARTICIPANT_ID_TO_INT()
	Event.vVehicleCoords = vVehicleCoords
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	PRINTLN("[KOTH] SCRIPT_EVENT_DATA_KOTH_PLAYER_EXPLODED_A_VEHICLE - Broadcasting!")
ENDPROC

// // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // // 

// Mission Yacht //

STRUCT SCRIPT_EVENT_DATA_FMMC_MOVE_FMMC_YACHT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iDriverPart
ENDSTRUCT

PROC BROADCAST_FMMC_MOVE_FMMC_YACHT(INT iDriver)
	SCRIPT_EVENT_DATA_FMMC_MOVE_FMMC_YACHT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_MOVE_FMMC_YACHT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iDriverPart = iDriver
	
	NET_PRINT("-----------------BROADCAST_FMMC_MOVE_FMMC_YACHT---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_MOVE_FMMC_YACHT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC


STRUCT SCRIPT_EVENT_DATA_FMMC_SHARD_BOMBUSHKA_MINI_ROUND_END_EARLY
	STRUCT_EVENT_COMMON_DETAILS Details
	
	INT iTeam
ENDSTRUCT

PROC BROADCAST_FMMC_SHARD_BOMBUSHKA_MINI_ROUND_END_EARLY(INT iTeam)
	SCRIPT_EVENT_DATA_FMMC_SHARD_BOMBUSHKA_MINI_ROUND_END_EARLY Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_SHARD_BOMBUSHKA_MINI_ROUND_END_EARLY
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iTeam = iTeam
	
	NET_PRINT("-----------------BROADCAST_FMMC_SHARD_BOMBUSHKA_MINI_ROUND_END_EARLY---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_SHARD_BOMBUSHKA_MINI_ROUND_END_EARLY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_COLLECTED_WEAPON
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vPos
ENDSTRUCT

PROC BROADCAST_FMMC_COLLECTED_WEAPON(VECTOR vPos)
	SCRIPT_EVENT_DATA_FMMC_COLLECTED_WEAPON Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_COLLECTED_WEAPON
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vPos = vPos
	
	NET_PRINT("-----------------BROADCAST_FMMC_COLLECTED_WEAPON---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_COLLECTED_WEAPON - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_RESPAWNED_WEAPON
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventPart
	INT iEventWeapon
ENDSTRUCT

PROC BROADCAST_FMMC_RESPAWNED_WEAPON(INT iPart, INT iWeapon)
	SCRIPT_EVENT_DATA_FMMC_RESPAWNED_WEAPON Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_RESPAWNED_WEAPON
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iEventPart = iPart
	Event.iEventWeapon = iWeapon
	
	NET_PRINT("-----------------BROADCAST_FMMC_RESPAWNED_WEAPON---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_RESPAWNED_WEAPON - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_POWER_UP_STOLEN
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX piPlayerStolenFrom
	PLAYER_INDEX piPlayerStolenBy
	INT iPowerUpStolen
ENDSTRUCT

PROC BROADCAST_FMMC_POWER_UP_STOLEN(PLAYER_INDEX piPlayerStolenFrom, PLAYER_INDEX piPlayerStolenBy, INT iPowerUpStolen)

	SCRIPT_EVENT_DATA_FMMC_POWER_UP_STOLEN Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_POWER_UP_STOLEN
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.piPlayerStolenFrom = piPlayerStolenFrom
	Event.piPlayerStolenBy = piPlayerStolenBy
	Event.iPowerUpStolen = iPowerUpStolen
	
	NET_PRINT("-----------------BROADCAST_FMMC_POWER_UP_STOLEN---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_POWER_UP_STOLEN - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_REMOTE_VEHICLE_SWAP
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerIndex
ENDSTRUCT

PROC BROADCAST_FMMC_REMOTE_VEHICLE_SWAP(PLAYER_INDEX playerIndex)

	SCRIPT_EVENT_DATA_FMMC_REMOTE_VEHICLE_SWAP Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_REMOTE_VEHICLE_SWAP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.playerIndex = playerIndex
	
	NET_PRINT("-----------------BROADCAST_FMMC_REMOTE_VEHICLE_SWAP---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_REMOTE_VEHICLE_SWAP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_OVERTIME_SCORED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INT iPriority
	INT iScore
ENDSTRUCT

PROC BROADCAST_FMMC_OVERTIME_SCORED(INT iTeam, INT iPriority, INT iScore)

	SCRIPT_EVENT_DATA_FMMC_OVERTIME_SCORED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_OVERTIME_SCORED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	Event.iPriority = iPriority
	Event.iScore = iScore
	
	NET_PRINT("-----------------BROADCAST_FMMC_OVERTIME_SCORED---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OVERTIME_SCORED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_OVERTIME_REMOVE_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	NETWORK_INDEX netVehicleToDelete
ENDSTRUCT

PROC BROADCAST_FMMC_OVERTIME_REMOVE_VEHICLE(NETWORK_INDEX netVehicleToDelete)

	SCRIPT_EVENT_DATA_FMMC_OVERTIME_REMOVE_VEHICLE Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_OVERTIME_REMOVE_VEHICLE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.netVehicleToDelete = netVehicleToDelete
	
	NET_PRINT("-----------------BROADCAST_FMMC_REMOVE_VEHICLE---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_REMOVE_VEHICLE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_AIRSHOOTOUT_SCORED
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL team0
	BOOL team1
	INT iRound
ENDSTRUCT

PROC BROADCAST_FMMC_AIRSHOOTOUT_SCORED(BOOL team0, BOOL team1, INT iRound)

	SCRIPT_EVENT_DATA_FMMC_AIRSHOOTOUT_SCORED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_AIRSHOOTOUT_SCORED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.team0 = team0
	Event.team1 = team1
	Event.iRound = iRound
	
	NET_PRINT("-----------------BROADCAST_FMMC_AIRSHOOTOUT_SCORED---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_AIRSHOOTOUT_SCORED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

//// BOMB FOOTBALL EVENTS ////
STRUCT SCRIPT_EVENT_DATA_FMMC_BMBFB_EXPLODE_BALL
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iScoringTeam
	INT iBallToExplode
	BOOL bIsGoal
ENDSTRUCT

PROC BROADCAST_FMMC_BMBFB_EXPLODE_BALL(INT i, INT iScoringTeam, BOOL bIsGoal = FALSE)
	SCRIPT_EVENT_DATA_FMMC_BMBFB_EXPLODE_BALL Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_BMBFB_EXPLODE_BALL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iScoringTeam = iScoringTeam
	Event.iBallToExplode = i
	Event.bIsGoal = bIsGoal
	
	NET_PRINT("-----------------BROADCAST_FMMC_BMFB_EXPLODE_BALL---------------------------") NET_NL()
	PRINTLN("[BMBFB]", "[BMB", Event.iBallToExplode, "] BROADCAST_FMMC_BMBFB_EXPLODE_BALL - Sending Explode Ball event! Exploding ball: ", Event.iBallToExplode, " || iScoringTeam is: ", iScoringTeam, " || Is goal? ", Event.bIsGoal)
	
	INT iPlayerFlags
	iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_BMFB_EXPLODE_BALL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_BMBFB_GOAL
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iScoringTeam
	INT iGoalIndex
	
	INT iBallInGoal
ENDSTRUCT

PROC BROADCAST_FMMC_BMBFB_GOAL(INT iScoringTeam, INT iGoalIndex, INT iBallIndex)
	SCRIPT_EVENT_DATA_FMMC_BMBFB_GOAL Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_BMBFB_GOAL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iScoringTeam = iScoringTeam
	Event.iGoalIndex = iGoalIndex
	Event.iBallInGoal = iBallIndex
	
	NET_PRINT("-----------------BROADCAST_FMMC_BMFB_GOAL---------------------------") NET_NL()
	PRINTLN("[BMBFB][BMBFB MAJOR]", "[BMB", iBallIndex, "] BROADCAST_FMMC_BMBFB_GOAL - Sending Goal event for ball ", iBallIndex, "! iScoringTeam is: ", iScoringTeam)
	
	INT iPlayerFlags
	iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_BMFB_GOAL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//// END OF BOMB FOOTBALL EVENTS ////

//ARENA TRAPS//

STRUCT SCRIPT_EVENT_DATA_FMMC_ARENA_ACTIVATED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTrapIndex
	INT iActivationType
	
	INT iTriggerTime
	FLOAT fSustainMultiplier = 1.0
ENDSTRUCT

FUNC STRING GET_STRING_FOR_TRAP_ACTIVATION_TYPE(INT iTrapDeactivationType)
	SWITCH iTrapDeactivationType
		CASE ciTRAPACTIVATIONTYPE_PRESSUREPAD RETURN "ciTRAPACTIVATIONTYPE_PRESSUREPAD"
		CASE ciTRAPACTIVATIONTYPE_TOUCHED RETURN "ciTRAPACTIVATIONTYPE_TOUCHED"
		CASE ciTRAPACTIVATIONTYPE_TRAPCAM RETURN "ciTRAPACTIVATIONTYPE_TRAPCAM"
		CASE ciTRAPACTIVATIONTYPE_SUSTAINTIMER RETURN "ciTRAPACTIVATIONTYPE_SUSTAINTIMER"
		
		CASE ciTRAPACTIVATIONTYPE_ARMING RETURN "ciTRAPACTIVATIONTYPE_ARMING"
	ENDSWITCH
	
	RETURN "INVALID"
ENDFUNC

PROC BROADCAST_FMMC_ARENA_TRAP_ACTIVATED(INT iTrapToActivate, INT iTrapActivationType, FLOAT fSustainMultiplier = 1.0)
	
	IF NOT NETWORK_IS_ACTIVITY_SESSION()
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_FMMC_ARENA_ACTIVATED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_ARENA_TRAP_ACTIVATED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iTrapIndex = iTrapToActivate
	Event.iActivationType = iTrapActivationType
	
	Event.iTriggerTime = NATIVE_TO_INT(GET_NETWORK_TIME())
	Event.fSustainMultiplier = fSustainMultiplier
	
	NET_PRINT("-----------------BROADCAST_FMMC_ARENA_TRAP_ACTIVATED---------------------------") NET_NL()
	PRINTLN("[ARENATRAPS]", "[TRAP ", iTrapToActivate, "]", " Sending Trap Activation event! iTrapToActivate is: ", iTrapToActivate, " | fSustainMultiplier is ", fSustainMultiplier, " | Activation Type is: ", GET_STRING_FOR_TRAP_ACTIVATION_TYPE(iTrapActivationType))
	
	INT iPlayerFlags
	iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_ARENA_TRAP_ACTIVATED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_FMMC_ARENA_TRAP_DEACTIVATED(INT iTrapToDeactivate, INT iTrapDeactivationType)
	
	IF NOT NETWORK_IS_ACTIVITY_SESSION()
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_FMMC_ARENA_ACTIVATED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_ARENA_TRAP_DEACTIVATED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iTrapIndex = iTrapToDeactivate
	Event.iActivationType = iTrapDeactivationType
	
	Event.iTriggerTime = NATIVE_TO_INT(GET_NETWORK_TIME())
	
	NET_PRINT("-----------------BROADCAST_FMMC_ARENA_TRAP_DEACTIVATED---------------------------") NET_NL()
	PRINTLN("[ARENATRAPS]", "[TRAP ", iTrapToDeactivate, "]", " Sending Trap Deactivation event! iTrapToDeactivate is: ", iTrapToDeactivate, " | Deactivation Type is: ", GET_STRING_FOR_TRAP_ACTIVATION_TYPE(iTrapDeactivationType))
	
	INT iPlayerFlags
	iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_ARENA_TRAP_DEACTIVATED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//ARENA TRAPS//
PROC PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_ACTIVATED(INT iEventID, FMMC_ARENA_TRAPS_HOST_INFO &sTrapInfo_Host, FMMC_ARENA_TRAPS_LOCAL_INFO &sTrapInfo_Local)
	SCRIPT_EVENT_DATA_FMMC_ARENA_ACTIVATED EventData
	
	IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iEventID, EventData, SIZE_OF(EventData))
		IF EventData.Details.Type = SCRIPT_EVENT_FMMC_ARENA_TRAP_ACTIVATED			
		
			IF EventData.iTrapIndex < 0
			OR EventData.iTrapIndex >= FMMC_MAX_NUM_DYNOPROPS
				PRINTLN("[ARENATRAPS][TRAP ", EventData.iTrapIndex, " PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_ACTIVATED - Pressurepad has an invalid trap index! Trap index is: ", EventData.iTrapIndex)
				EXIT
			ENDIF
			
			IF EventData.iActivationType = ciTRAPACTIVATIONTYPE_ARMING
				IF NETWORK_IS_HOST_OF_THIS_SCRIPT()
					SET_BIT(sTrapInfo_Host.iArenaTraps_TrapArmedBS, EventData.iTrapIndex)
					PRINTLN("[ARENATRAPS][TRAP ", EventData.iTrapIndex, "] PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_ACTIVATED - Setting iArenaTraps_TrapArmedBS for this trap")
				ENDIF
				
				EXIT
			ELSE
				CLEAR_BIT(sTrapInfo_Host.iArenaTraps_TrapArmedBS, EventData.iTrapIndex)
				PRINTLN("[ARENATRAPS][TRAP ", EventData.iTrapIndex, "] PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_ACTIVATED - Clearing iArenaTraps_TrapArmedBS for this trap")
			ENDIF
			
			sTrapInfo_Local.iPartActivatedBy = -1
			
			IF EventData.Details.FromPlayerIndex != INVALID_PLAYER_INDEX()
				IF NETWORK_IS_PARTICIPANT_ACTIVE(NETWORK_GET_PARTICIPANT_INDEX(EventData.Details.FromPlayerIndex))
					sTrapInfo_Local.iPartActivatedBy = NATIVE_TO_INT(NETWORK_GET_PARTICIPANT_INDEX(EventData.Details.FromPlayerIndex))
					PRINTLN("[ARENATRAPS][TRAP ", EventData.iTrapIndex, "] PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_ACTIVATED - Assigning iPartActivatedBy...")
				ELSE
					PRINTLN("[ARENATRAPS][TRAP ", EventData.iTrapIndex, "] PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_ACTIVATED - Part not active...")
				ENDIF
			ELSE
				PRINTLN("[ARENATRAPS][TRAP ", EventData.iTrapIndex, "] PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_ACTIVATED - Sender Invalid.")
			ENDIF
			PRINTLN("[ARENATRAPS][TRAP ", EventData.iTrapIndex, "] PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_ACTIVATED - EventData.iTrapIndex: ", EventData.iTrapIndex, " sTrapInfo_Local.iPartActivatedBy: ", sTrapInfo_Local.iPartActivatedBy)
					
			sTrapInfo_Local.fTrapSustainMultiplier[EventData.iTrapIndex] = EventData.fSustainMultiplier
			RESET_NET_TIMER(sTrapInfo_Local.stTrapProximityActivationTimers[EventData.iTrapIndex])
			
			IF NETWORK_IS_HOST_OF_THIS_SCRIPT()
				SWITCH EventData.iActivationType
					CASE ciTRAPACTIVATIONTYPE_PRESSUREPAD
						SET_BIT(sTrapInfo_Host.iArenaTraps_TrapPadPressedBS, EventData.iTrapIndex)
						PRINTLN("[ARENATRAPS]", "[TRAP ", EventData.iTrapIndex, "] ", GET_STRING_FOR_TRAP_ACTIVATION_TYPE(EventData.iActivationType), " Pressurepad has been pressed for trap: ", EventData.iTrapIndex, " || Sustain multiplier: ", EventData.fSustainMultiplier)
					BREAK
					CASE ciTRAPACTIVATIONTYPE_TOUCHED
						SET_BIT(sTrapInfo_Host.iArenaTraps_TrapActivatedByTouchBS, EventData.iTrapIndex)
						PRINTLN("[ARENATRAPS]", "[TRAP ", EventData.iTrapIndex, "] ", GET_STRING_FOR_TRAP_ACTIVATION_TYPE(EventData.iActivationType), " Trap has been activated by touch: ", EventData.iTrapIndex, " || Sustain multiplier: ", EventData.fSustainMultiplier)
					BREAK
					CASE ciTRAPACTIVATIONTYPE_TRAPCAM
						SET_BIT(sTrapInfo_Host.iArenaTraps_TrapCamActivatedBS, EventData.iTrapIndex)
						PRINTLN("[ARENATRAPS]", "[TRAP ", EventData.iTrapIndex, "] ", GET_STRING_FOR_TRAP_ACTIVATION_TYPE(EventData.iActivationType), " TrapCam has activated trap: ", EventData.iTrapIndex, " || Sustain multiplier: ", EventData.fSustainMultiplier)
					BREAK
					
					CASE ciTRAPACTIVATIONTYPE_SUSTAINTIMER
						SET_BIT(sTrapInfo_Host.iArenaTraps_TrapPadPressedBS, EventData.iTrapIndex)
						SET_BIT(sTrapInfo_Host.iArenaTraps_TrapActivatedByTouchBS, EventData.iTrapIndex)
						SET_BIT(sTrapInfo_Host.iArenaTraps_TrapCamActivatedBS, EventData.iTrapIndex)
						PRINTLN("[ARENATRAPS]", "[TRAP ", EventData.iTrapIndex, "] ", GET_STRING_FOR_TRAP_ACTIVATION_TYPE(EventData.iActivationType), " Dummy activation of trap: ", EventData.iTrapIndex, " || Sustain multiplier: ", EventData.fSustainMultiplier)
					BREAK
				ENDSWITCH
				
				REINIT_NET_TIMER(sTrapInfo_Host.stTrapSustainTimer[EventData.iTrapIndex])
				//PRINTLN("[ARENATRAPS]", "[TRAP ", EventData.iTrapIndex, "]", " Resetting sustain timer for trap: ", EventData.iTrapIndex)
			ENDIF
		ENDIF
	ENDIF
ENDPROC

PROC PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_DEACTIVATED(INT iEventID, FMMC_ARENA_TRAPS_HOST_INFO &sTrapInfo_Host, FMMC_ARENA_TRAPS_LOCAL_INFO &sTrapInfo_Local)

	UNUSED_PARAMETER(sTrapInfo_Local)
	
	SCRIPT_EVENT_DATA_FMMC_ARENA_ACTIVATED EventData
	
	IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iEventID, EventData, SIZE_OF(EventData))
		IF EventData.Details.Type = SCRIPT_EVENT_FMMC_ARENA_TRAP_DEACTIVATED
			
			IF EventData.iTrapIndex < 0
			OR EventData.iTrapIndex >= FMMC_MAX_NUM_DYNOPROPS
				PRINTLN("[ARENATRAPS] PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_DEACTIVATED - Pressurepad has an invalid trap index! Trap index is: ", EventData.iTrapIndex)
				EXIT
			ENDIF
			
			sTrapInfo_Local.iPartActivatedBy = -1		
			PRINTLN("[ARENATRAPS] PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_DEACTIVATED - EventData.iTrapIndex: ", EventData.iTrapIndex, " sTrapInfo_Local.iPartActivatedBy: ", sTrapInfo_Local.iPartActivatedBy)		
			
			IF EventData.Details.FromPlayerIndex != INVALID_PLAYER_INDEX()
				IF NETWORK_IS_PARTICIPANT_ACTIVE(NETWORK_GET_PARTICIPANT_INDEX(EventData.Details.FromPlayerIndex))
					INT iPartDeactivated = NATIVE_TO_INT(NETWORK_GET_PARTICIPANT_INDEX(EventData.Details.FromPlayerIndex))
					PRINTLN("[ARENATRAPS] PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_DEACTIVATED - iPartDeactivated: ", iPartDeactivated)
				ELSE
					PRINTLN("[ARENATRAPS] PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_DEACTIVATED - Part not active...")
				ENDIF
			ELSE
				PRINTLN("[ARENATRAPS] PROCESS_SCRIPT_EVENT_FMMC_ARENA_TRAP_DEACTIVATED - Invalid Sender")
			ENDIF
			
			IF NETWORK_IS_HOST_OF_THIS_SCRIPT()
				SWITCH EventData.iActivationType
					CASE ciTRAPACTIVATIONTYPE_PRESSUREPAD
						CLEAR_BIT(sTrapInfo_Host.iArenaTraps_TrapPadPressedBS, EventData.iTrapIndex)
						PRINTLN("[ARENATRAPS]", "[TRAP ", EventData.iTrapIndex, "] ", GET_STRING_FOR_TRAP_ACTIVATION_TYPE(EventData.iActivationType), " Pressurepad released for trap: ", EventData.iTrapIndex)
					BREAK
					CASE ciTRAPACTIVATIONTYPE_TOUCHED
						CLEAR_BIT(sTrapInfo_Host.iArenaTraps_TrapActivatedByTouchBS, EventData.iTrapIndex)
						PRINTLN("[ARENATRAPS]", "[TRAP ", EventData.iTrapIndex, "] ", GET_STRING_FOR_TRAP_ACTIVATION_TYPE(EventData.iActivationType), " Trap no longer activated by touch: ", EventData.iTrapIndex)
					BREAK
					CASE ciTRAPACTIVATIONTYPE_TRAPCAM
						CLEAR_BIT(sTrapInfo_Host.iArenaTraps_TrapCamActivatedBS, EventData.iTrapIndex)
						PRINTLN("[ARENATRAPS]", "[TRAP ", EventData.iTrapIndex, "] ", GET_STRING_FOR_TRAP_ACTIVATION_TYPE(EventData.iActivationType), " TrapCam has deactivated trap: ", EventData.iTrapIndex)
					BREAK
					
					CASE ciTRAPACTIVATIONTYPE_SUSTAINTIMER
						CLEAR_BIT(sTrapInfo_Host.iArenaTraps_TrapPadPressedBS, EventData.iTrapIndex)
						CLEAR_BIT(sTrapInfo_Host.iArenaTraps_TrapActivatedByTouchBS, EventData.iTrapIndex)
						//CLEAR_BIT(sTrapInfo_Host.iArenaTraps_TrapCamActivatedBS, EventData.iTrapIndex)
						
						PRINTLN("[ARENATRAPS]", "[TRAP ", EventData.iTrapIndex, "] ", GET_STRING_FOR_TRAP_ACTIVATION_TYPE(EventData.iActivationType), " Dummy deactivation of trap: ", EventData.iTrapIndex)
					BREAK
				ENDSWITCH
			ENDIF
		ENDIF
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_ARENA_LANDMINE_TOUCHED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iLandmineIndex
ENDSTRUCT

PROC BROADCAST_FMMC_ARENA_LANDMINE_TOUCHED(INT iLandmineIndex)
	SCRIPT_EVENT_DATA_FMMC_ARENA_LANDMINE_TOUCHED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_ARENA_LANDMINE_TOUCHED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iLandmineIndex = iLandmineIndex
	
	NET_PRINT("-----------------BROADCAST_FMMC_ARENA_LANDMINE_TOUCHED---------------------------") NET_NL()
	PRINTLN("[ARENATRAPS]", "[TRAP ", iLandmineIndex, "]", "  Sending Landmine touched event! iLandmineIndex is: ", iLandmineIndex)
	
	INT iPlayerFlags
	iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_ARENA_LANDMINE_TOUCHED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC PROCESS_SCRIPT_EVENT_FMMC_ARENA_LANDMINE_TOUCHED(INT iEventID, FMMC_ARENA_TRAPS_HOST_INFO &sTrapInfo_Host)
	SCRIPT_EVENT_DATA_FMMC_ARENA_LANDMINE_TOUCHED EventData
	
	IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iEventID, EventData, SIZE_OF(EventData))
		IF EventData.Details.Type = SCRIPT_EVENT_FMMC_ARENA_LANDMINE_TOUCHED
			
			PRINTLN("[ARENATRAPS]", "[TRAP ", EventData.iLandmineIndex, "]", "  Landmine ", EventData.iLandmineIndex, " has been touched!")

			IF NETWORK_IS_HOST_OF_THIS_SCRIPT()
				SET_BIT(sTrapInfo_Host.iArenaTraps_LandmineArmedBS, EventData.iLandmineIndex)
			ENDIF
		ENDIF
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_ARENA_ARTICULATED_JOINT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iJointIndex
	BOOL bActive
ENDSTRUCT

PROC BROADCAST_FMMC_ARENA_ARTICULATED_JOINT(INT iJointIndex, BOOL bActive)
	SCRIPT_EVENT_DATA_FMMC_ARENA_ARTICULATED_JOINT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_ARENA_ARTICULATED_JOINT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iJointIndex = iJointIndex
	Event.bActive = bActive
	
	NET_PRINT("-----------------BROADCAST_FMMC_ARENA_ARTICULATED_JOINT---------------------------") NET_NL()
	PRINTLN("[ARENATRAPS]", "[TRAP ", iJointIndex, "]", "  Sending Joint event! iJointIndex is: ", iJointIndex, " || bActive is ", bActive)
	
	INT iPlayerFlags
	iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_ARENA_ARTICULATED_JOINT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC PROCESS_SCRIPT_EVENT_FMMC_ARENA_ARTICULATED_JOINT(INT iEventID, NETWORK_INDEX& niDynoprops[])
	SCRIPT_EVENT_DATA_FMMC_ARENA_ARTICULATED_JOINT EventData
	
	IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iEventID, EventData, SIZE_OF(EventData))
		IF EventData.Details.Type = SCRIPT_EVENT_FMMC_ARENA_ARTICULATED_JOINT
			
			OBJECT_INDEX oiJointProp = NET_TO_OBJ(niDynoprops[EventData.iJointIndex])
			
			IF NETWORK_HAS_CONTROL_OF_ENTITY(oiJointProp)
				FREEZE_ENTITY_POSITION(oiJointProp, FALSE)
			ENDIF
			
			IF EventData.bActive
				PRINTLN("[ARENATRAPS]", "[TRAP ", EventData.iJointIndex, "]", " Articulated Joint ", EventData.iJointIndex, " has been activated!")
			ELSE
				PRINTLN("[ARENATRAPS]", "[TRAP ", EventData.iJointIndex, "]", " Articulated Joint ", EventData.iJointIndex, " has been reset!")
			ENDIF
			
			SET_DRIVE_ARTICULATED_JOINT(oiJointProp, EventData.bActive)
			
			IF NETWORK_IS_HOST_OF_THIS_SCRIPT()
				//PLACEHOLDER IN CASE WE ACTUALLY DO NEED TO SCRIPT THIS
			ENDIF
		ENDIF
	ENDIF
ENDPROC

//END OF ARENA TRAP EVENTS//

STRUCT SCRIPT_EVENT_DATA_FMMC_KILLSTREAK_POWERUP_ACTIVATED_FREEZE_POS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeamActivated
	BOOL bTeamAffected[FMMC_MAX_TEAMS]
ENDSTRUCT

PROC BROADCAST_FMMC_KILLSTREAK_POWERUP_ACTIVATED_FREEZE_POS(INT iTeamActivated, BOOL &bTeamAffected[])

	SCRIPT_EVENT_DATA_FMMC_KILLSTREAK_POWERUP_ACTIVATED_FREEZE_POS Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_KILLSTREAK_POWERUP_ACTIVATED_FREEZE_POS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeamActivated = iTeamActivated
	INT i = 0
	FOR i = 0 TO FMMC_MAX_TEAMS-1
		Event.bTeamAffected[i] = bTeamAffected[i]
	ENDFOR
	
	NET_PRINT("-----------------BROADCAST_FMMC_KILLSTREAK_POWERUP_ACTIVATED_FREEZE_POS---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_GHOST_STARTED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC
STRUCT SCRIPT_EVENT_DATA_FMMC_KILLSTREAK_POWERUP_ACTIVATED_TURF_TRADE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeamActivated
ENDSTRUCT

PROC BROADCAST_FMMC_KILLSTREAK_POWERUP_ACTIVATED_TURF_TRADE(INT iTeamActivated)

	SCRIPT_EVENT_DATA_FMMC_KILLSTREAK_POWERUP_ACTIVATED_TURF_TRADE Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_KILLSTREAK_POWERUP_ACTIVATED_TURF_TRADE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeamActivated = iTeamActivated
	
	NET_PRINT("-----------------BROADCAST_FMMC_KILLSTREAK_POWERUP_ACTIVATED_TURF_TRADE---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_GHOST_STARTED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_MANUAL_RESPAWN_TO_PASSENGERS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventLocalPartDriver
	NETWORK_INDEX vehEventIndex
ENDSTRUCT

PROC BROADCAST_FMMC_MANUAL_RESPAWN_TO_PASSENGERS(NETWORK_INDEX vehIndex, INT iLocalPartDriver)

	SCRIPT_EVENT_DATA_FMMC_MANUAL_RESPAWN_TO_PASSENGERS Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_MANUAL_RESPAWN_TO_PASSENGERS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vehEventIndex = vehIndex
	Event.iEventLocalPartDriver = iLocalPartDriver	
	
	NET_PRINT("-----------------BROADCAST_FMMC_MANUAL_RESPAWN_TO_PASSENGERS---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_MANUAL_RESPAWN_TO_PASSENGERS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_KILL_PLAYER_NOT_AT_LOCATE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventPart
ENDSTRUCT

PROC BROADCAST_FMMC_KILL_PLAYER_NOT_AT_LOCATE(INT iPart)
	SCRIPT_EVENT_DATA_FMMC_KILL_PLAYER_NOT_AT_LOCATE Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_KILL_PLAYER_NOT_AT_LOCATE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iEventPart = iPart
	
	NET_PRINT("-----------------BROADCAST_FMMC_KILL_PLAYER_NOT_AT_LOCATE---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_KILL_PLAYER_NOT_AT_LOCATE - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_BROADCAST_PREREQS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPreReqBS[ciPREREQ_Bitsets]
	BOOL bClear = FALSE
ENDSTRUCT

PROC BROADCAST_FMMC_BROADCAST_PREREQS(INT &iPreReqBS[], BOOL bClear = FALSE)
	SCRIPT_EVENT_DATA_FMMC_BROADCAST_PREREQS Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_BROADCAST_PREREQS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	INT iPreReq
	FOR iPreReq = 0 TO ciPREREQ_Bitsets - 1
		Event.iPreReqBS[iPreReq] = iPreReqBS[iPreReq]
	ENDFOR
	Event.bClear = bClear
	
	NET_PRINT("-----------------BROADCAST_FMMC_BROADCAST_PREREQS---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_BROADCAST_PREREQS - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_FOR_INSTANCED_CONTENT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPart
	INT iType
	INT iVeh
	INT iPed
	INT iObj
	INT iProp
	INT iDynoProp
	INT iZone
	INT iLoc
	BOOL bToggle
	INT iGenericInt
	FLOAT fGenericFloat
	NETWORK_INDEX niNetworkIndex
	FLOAT fGenericVecX, fGenericVecY, fGenericVecZ
ENDSTRUCT

PROC BROADCAST_FMMC_EVENT_FOR_INSTANCED_CONTENT(INT iPart, INT iType, INT iVeh = -1, INT iPed = -1, INT iObj = -1, INT iProp = -1, INT iDynoProp = -1, INT iZone = -1, BOOL bToggle = FALSE, INT iGenericInt = -1, INT iLoc = -1, NETWORK_INDEX niNetworkIndex = NULL, FLOAT fGenericFloat = 0.0, FLOAT fGenericVecX = 0.0, FLOAT fGenericVecY = 0.0, FLOAT fGenericVecZ = 0.0)

	SCRIPT_EVENT_DATA_FMMC_FOR_INSTANCED_CONTENT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_FOR_INSTANCED_CONTENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iPart = iPart
	Event.iType = iType
	Event.iVeh = iVeh
	Event.iPed = iPed
	Event.iObj = iObj
	Event.iProp = iProp
	Event.iDynoProp = iDynoProp
	Event.iZone = iZone
	Event.iLoc = iLoc
	Event.bToggle = bToggle
	Event.iGenericInt = iGenericInt
	Event.niNetworkIndex = niNetworkIndex
	Event.fGenericFloat = fGenericFloat
	Event.fGenericVecX = fGenericVecX
	Event.fGenericVecY = fGenericVecY
	Event.fGenericVecZ = fGenericVecZ
	
	NET_PRINT("-----------------BROADCAST_FMMC_EVENT_FOR_INSTANCED_CONTENT---------------------------") NET_NL()
	
	PRINTLN("iPart: ", iPart)
	PRINTLN("iType: ", iType)
	PRINTLN("bToggle: ", bToggle)
	PRINTLN("iGenericInt: ", iGenericInt)
	PRINTLN("fGenericFloat: ", fGenericFloat)
	
	IF iVeh > -1
		PRINTLN("iVeh: ", iVeh)	
	ENDIF
	IF iPed > -1
		PRINTLN("iPed: ", iPed)
	ENDIF
	IF iObj > -1
		PRINTLN("iObj: ", iObj)
	ENDIF
	IF iProp > -1
		PRINTLN("iProp: ", iProp)
	ENDIF
	IF iDynoProp > -1
		PRINTLN("iDynoProp: ", iDynoProp)
	ENDIF
	IF iZone > -1
		PRINTLN("iZone: ", iZone)
	ENDIF
	IF iLoc > -1
		PRINTLN("iLoc: ", iLoc)		
	ENDIF
	IF niNetworkIndex != NULL
		PRINTLN("niNetworkIndex: ", NATIVE_TO_INT(niNetworkIndex))		
	ENDIF
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_FOR_INSTANCED_CONTENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_EVENT_CONVERSATION_FOR_PED
	STRUCT_EVENT_COMMON_DETAILS Details
	FMMC_SCRIPTED_ANIM_CONVERSATION_DATA sScriptedAnimConversationEventData
ENDSTRUCT

PROC BROADCAST_FMMC_EVENT_START_SCRIPTED_ANIM_CONVERSATION(FMMC_SCRIPTED_ANIM_CONVERSATION_DATA& sScriptedAnimConversationData)

	SCRIPT_EVENT_DATA_FMMC_EVENT_CONVERSATION_FOR_PED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_START_SCRIPTED_ANIM_CONVERSATION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	NET_PRINT("-----------------BROADCAST_FMMC_EVENT_START_SCRIPTED_ANIM_CONVERSATION---------------------------") NET_NL()
	
	Event.sScriptedAnimConversationEventData = sScriptedAnimConversationData
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_EVENT_START_SCRIPTED_ANIM_CONVERSATION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_ENTITY_DAMAGED_EVENT_FAKE
	STRUCT_EVENT_COMMON_DETAILS Details	
	INT iPartToExclude = -1
	STRUCT_ENTITY_DAMAGE_EVENT sEntityID
	NETWORK_INDEX VictimIndex
	NETWORK_INDEX DamagerIndex
	PLAYER_INDEX piPlayerVictim
	PLAYER_INDEX piPlayerDamager
ENDSTRUCT

// An event we can send out which populates the struct "STRUCT_ENTITY_DAMAGE_EVENT sEntityID" and calls the functions to process as if a damage event had been sent out for mission entities.
// This is used for situations where SET_ENTITY_HEALTH with Instigator is not appropriate as it only generates a damage event on the local client.
// iPartToExclude should be set to the player we don't want processing the event. Usually this will be the local player calling the broadcast.
PROC BROADCAST_FMMC_EVENT_ENTITY_DAMAGED_EVENT_FAKE(INT iPartToExclude, PLAYER_INDEX piPlayerVictim, PLAYER_INDEX piPlayerDamager, NETWORK_INDEX VictimIndex, NETWORK_INDEX DamagerIndex, FLOAT Damage, BOOL VictimDestroyed, INT WeaponUsed, BOOL IsHeadShot, BOOL IsWithMeleeWeapon, BOOL VictimIncapacitated, BOOL IsResponsibleForCollision = FALSE, FLOAT EnduranceDamage = 0.0, FLOAT VictimSpeed = 0.0, FLOAT DamagerSpeed = 0.0, INT HitMaterial = 0)

	SCRIPT_EVENT_DATA_FMMC_ENTITY_DAMAGED_EVENT_FAKE Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_ENTITY_DAMAGED_EVENT_FAKE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPartToExclude = iPartToExclude
	
	// Need to use NETWORK_INDEX here as PED/VEH etc are local indexes that don't exist or will be different on other clients.
	Event.VictimIndex								= VictimIndex
	Event.DamagerIndex								= DamagerIndex
	Event.piPlayerVictim							= piPlayerVictim
	Event.piPlayerDamager							= piPlayerDamager
	
	// Standard damage event data
	Event.sEntityID.Damage							= Damage
	Event.sEntityID.EnduranceDamage					= EnduranceDamage
	Event.sEntityID.VictimIncapacitated				= VictimIncapacitated
	Event.sEntityID.VictimDestroyed					= VictimDestroyed
	Event.sEntityID.WeaponUsed						= WeaponUsed
	Event.sEntityID.VictimSpeed						= VictimSpeed
	Event.sEntityID.DamagerSpeed					= DamagerSpeed
	Event.sEntityID.IsResponsibleForCollision		= IsResponsibleForCollision
	Event.sEntityID.IsHeadShot						= IsHeadShot
	Event.sEntityID.IsWithMeleeWeapon 				= IsWithMeleeWeapon 
	Event.sEntityID.HitMaterial						= HitMaterial		
	
	DEBUG_PRINTCALLSTACK()
	
	PRINTLN("-----------------BROADCAST_FMMC_EVENT_ENTITY_DAMAGED_EVENT_FAKE---------------------------")
	PRINTLN("-----------------iPartToExclude               ", iPartToExclude							, "---------------------------")
	
	IF Event.piPlayerVictim != INVALID_PLAYER_INDEX()		
		PRINTLN("-----------------piPlayerVictim           ", GET_PLAYER_NAME(Event.piPlayerVictim), "---------------------------")
	ELIF NETWORK_DOES_NETWORK_ID_EXIST(Event.VictimIndex)
		PRINTLN("-----------------VictimIndex(NET)         ", NETWORK_ENTITY_GET_OBJECT_ID(NET_TO_ENT(Event.VictimIndex)), "---------------------------")
	ENDIF
	IF Event.piPlayerDamager != INVALID_PLAYER_INDEX()		
		PRINTLN("-----------------piPlayerDamager          ", GET_PLAYER_NAME(Event.piPlayerDamager), "---------------------------")
	ELIF NETWORK_DOES_NETWORK_ID_EXIST(Event.DamagerIndex)
		PRINTLN("-----------------DamagerIndex(NET)        ", NETWORK_ENTITY_GET_OBJECT_ID(NET_TO_ENT(Event.DamagerIndex)), "---------------------------")
	ENDIF
	
	PRINTLN("-----------------Damage                       ", Event.sEntityID.Damage					, "---------------------------")
	PRINTLN("-----------------EnduranceDamage              ", Event.sEntityID.EnduranceDamage			, "---------------------------")
	PRINTLN("-----------------VictimIncapacitated          ", Event.sEntityID.VictimIncapacitated		, "---------------------------")
	PRINTLN("-----------------VictimDestroyed              ", Event.sEntityID.VictimDestroyed			, "---------------------------")
	PRINTLN("-----------------WeaponUsed                   ", Event.sEntityID.WeaponUsed				, "---------------------------")
	PRINTLN("-----------------VictimSpeed                  ", Event.sEntityID.VictimSpeed				, "---------------------------")
	PRINTLN("-----------------DamagerSpeed                 ", Event.sEntityID.DamagerSpeed				, "---------------------------")
	PRINTLN("-----------------IsResponsibleForCollision    ", Event.sEntityID.IsResponsibleForCollision	, "---------------------------")
	PRINTLN("-----------------IsHeadShot                   ", Event.sEntityID.IsHeadShot				, "---------------------------")
	PRINTLN("-----------------IsWithMeleeWeapon            ", Event.sEntityID.IsWithMeleeWeapon 		, "---------------------------")
	PRINTLN("-----------------HitMaterial                  ", Event.sEntityID.HitMaterial				, "---------------------------")
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_EVENT_START_SCRIPTED_ANIM_CONVERSATION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_DELIVER_VEHICLE_STOP
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iVehicle
	INT iPart
	INT iTimeToStop
ENDSTRUCT

PROC BROADCAST_FMMC_DELIVER_VEHICLE_STOP(INT iVehicle, INT iPart, INT iTimeToStop)

	SCRIPT_EVENT_DATA_FMMC_DELIVER_VEHICLE_STOP Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_DELIVER_VEHICLE_STOP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iVehicle = iVehicle
	Event.iPart = iPart
	Event.iTimeToStop = iTimeToStop
	
	NET_PRINT("-----------------BROADCAST_FMMC_DELIVER_VEHICLE_STOP---------------------------") NET_NL()

	PRINTLN("iVehicle: ", iVehicle)
	PRINTLN("iPart: ", iPart)
	PRINTLN("iTimeToStop: ", iTimeToStop)

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_DELIVER_VEHICLE_STOP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_GHOST_STARTED
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bActivate
ENDSTRUCT

PROC BROADCAST_FMMC_GHOST_STARTED(Bool bActivate)

	SCRIPT_EVENT_DATA_FMMC_GHOST_STARTED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_GHOST_STARTED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bActivate = bActivate
	
	NET_PRINT("-----------------BROADCAST_FMMC_GHOST_STARTED---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_GHOST_STARTED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_ALPHA_CHANGE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPart
	INT iNetVehIndex
	INT iAlphaPlayer
	INT iAlphaVehicle
	INT iFrameCount
ENDSTRUCT

PROC BROADCAST_FMMC_ALPHA_CHANGE(INT iAlphaPlayer, INT iAlphaVehicle, INT iPart, INT iNetVehIndex, INT iFrameCount)

	SCRIPT_EVENT_DATA_FMMC_ALPHA_CHANGE Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_ALPHA_CHANGE
	Event.iAlphaPlayer = iAlphaPlayer
	Event.iAlphaVehicle = iAlphaVehicle
	Event.iPart = iPart
	Event.iNetVehIndex = iNetVehIndex
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iFrameCount = iFrameCount
	
	NET_PRINT("-----------------BROADCAST_FMMC_ALPHA_CHANGE--------------------------") NET_NL()	
	PRINTLN("iAlphaPlayer: ", iAlphaPlayer, " iAlphaVehicle: ", iAlphaVehicle, " iPart: ", iPart, " iNetVehIndex: ", iNetVehIndex)

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_ALPHA_CHANGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_SPAWN_PROTECTION_ALPHA
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bActivate
	INT iPart
	INT iFrameCount
ENDSTRUCT

PROC BROADCAST_FMMC_SPAWN_PROTECTION_ALPHA(Bool bActivate, INT iPart, INT iFrameCount)

	SCRIPT_EVENT_DATA_FMMC_SPAWN_PROTECTION_ALPHA Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_SPAWN_PROTECTION_ALPHA
	Event.bActivate = bActivate
	Event.iPart = iPart
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iFrameCount = iFrameCount
	NET_PRINT("-----------------BROADCAST_FMMC_SPAWN_PROTECTION_ALPHA--------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_SPAWN_PROTECTION_ALPHA - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PLAYER_ALPHA_WITH_WEAPON
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPart
	INT iAlphaValue
	INT iFrameCount
ENDSTRUCT

PROC BROADCAST_FMMC_PLAYER_ALPHA_WITH_WEAPON(INT iPart, INT iAlphaValue, INT iFrameCount)

	SCRIPT_EVENT_DATA_FMMC_PLAYER_ALPHA_WITH_WEAPON Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PLAYER_ALPHA_WITH_WEAPON
	Event.iPart = iPart
	Event.iAlphaValue = iAlphaValue
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iFrameCount = iFrameCount
	NET_PRINT("-----------------BROADCAST_FMMC_PLAYER_ALPHA_WITH_WEAPON--------------------------") NET_NL()
	PRINTLN("[BROADCAST_FMMC_PLAYER_ALPHA_WITH_WEAPON] Event.iPart: ", Event.iPart)
	PRINTLN("[BROADCAST_FMMC_PLAYER_ALPHA_WITH_WEAPON] Event.iAlphaValue: ", Event.iAlphaValue)

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PLAYER_ALPHA_WITH_WEAPON - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_AUDIO_TRIGGER_ACTIVATED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iSoundID
	VECTOR vPlayFromPos
	INT iProp
ENDSTRUCT

PROC BROADCAST_FMMC_AUDIO_TRIGGER_ACTIVATED(INT iSoundID, VECTOR vPlayFromPos, INT iProp)
	PRINTLN("[LM][BROADCAST_FMMC_AUDIO_TRIGGER_ACTIVATED] - Broadcasting...")
	SCRIPT_EVENT_DATA_FMMC_AUDIO_TRIGGER_ACTIVATED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_AUDIO_TRIGGER_ACTIVATED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iSoundID = iSoundID
	Event.vPlayFromPos = vPlayFromPos
	Event.iProp = iProp
	
	NET_PRINT("-----------------BROADCAST_FMMC_AUDIO_TRIGGER_ACTIVATED---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_AUDIO_TRIGGER_ACTIVATED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_INITIATE_SEAT_SWAP_TEAM_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeamVehiclePartners[MAX_VEHICLE_PARTNERS]
	
ENDSTRUCT

PROC BROADCAST_FMMC_INITIATE_SEAT_SWAP_TEAM_VEHICLE(INT &iTeamVehiclePartners[])

	SCRIPT_EVENT_DATA_FMMC_INITIATE_SEAT_SWAP_TEAM_VEHICLE Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_INITIATE_SEAT_SWAP_TEAM_VEHICLE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT i = 0
	FOR i = 0 TO MAX_VEHICLE_PARTNERS-1
		Event.iTeamVehiclePartners[i] = iTeamVehiclePartners[i]
	ENDFOR
	
	NET_PRINT("-----------------BROADCAST_FMMC_INITIATE_SEAT_SWAP_TEAM_VEHICLE---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_INITIATE_SEAT_SWAP_TEAM_VEHICLE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_TURF_WAR_SCORED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeamTW
	BOOL bTeamDrawTW[FMMC_MAX_TEAMS]
	BOOL bShard
ENDSTRUCT

PROC BROADCAST_FMMC_TURF_WAR_SCORED(INT iTeamTW, BOOL &bTeamDraw[], BOOL bShowShard)

	SCRIPT_EVENT_DATA_FMMC_TURF_WAR_SCORED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_TURF_WAR_SCORED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeamTW = iTeamTW
	Event.bShard = bShowShard
	
	INT iTeamCount = 0
	FOR iTeamCount = 0 TO FMMC_MAX_TEAMS-1
		Event.bTeamDrawTW[iTeamCount] = bTeamDraw[iTeamCount]
	ENDFOR
	
	NET_PRINT("-----------------BROADCAST_FMMC_TURF_WAR_SCORED---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_TURF_WAR_SCORED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_LEFT_LOCATE_DELAY_RECAPTURE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPartToBlock
	INT iLoc
ENDSTRUCT

PROC BROADCAST_FMMC_LEFT_LOCATE_DELAY_RECAPTURE(INT iPartToBlock, INT iLoc)

	SCRIPT_EVENT_DATA_FMMC_LEFT_LOCATE_DELAY_RECAPTURE Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_LEFT_LOCATE_DELAY_RECAPTURE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPartToBlock = iPartToBlock
	Event.iLoc = iLoc
	
	NET_PRINT("-----------------BROADCAST_FMMC_LEFT_LOCATE_DELAY_RECAPTURE---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_LEFT_LOCATE_DELAY_RECAPTURE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_OVERTIME_RESET_TURNS_AND_SCORE
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_FMMC_OVERTIME_RESET_TURNS_AND_SCORE()

	SCRIPT_EVENT_DATA_FMMC_OVERTIME_RESET_TURNS_AND_SCORE Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_OVERTIME_RESET_TURNS_AND_SCORE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	NET_PRINT("-----------------BROADCAST_FMMC_OVERTIME_RESET_TURNS_AND_SCORE---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OVERTIME_RESET_TURNS_AND_SCORE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_OVERTIME_ROUND_CHANGE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOl bStartOfNewRoundCycle
	INT iPart
	INT iTeam
	BOOL bShardOnly
ENDSTRUCT

PROC BROADCAST_FMMC_OVERTIME_ROUND_CHANGE(BOOL bStartOfNewRoundCycle, INT iPart, INT iTeam, BOOL bShardOnly = FALSE)

	SCRIPT_EVENT_DATA_FMMC_OVERTIME_ROUND_CHANGE Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_OVERTIME_ROUND_CHANGE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bStartOfNewRoundCycle = bStartOfNewRoundCycle
	Event.iPart = iPart
	Event.iTeam = iTeam
	Event.bShardOnly = bShardOnly
	
	NET_PRINT("-----------------BROADCAST_FMMC_OVERTIME_ROUND_CHANGE---------------------------") NET_NL()
	PRINTLN("[BROADCAST_FMMC_OVERTIME_ROUND_CHANGE] bStartOfNewRoundCycle: ", bStartOfNewRoundCycle)
	PRINTLN("[BROADCAST_FMMC_OVERTIME_ROUND_CHANGE] iPart: ", iPart)
	PRINTLN("[BROADCAST_FMMC_OVERTIME_ROUND_CHANGE] iTeam: ", iTeam)

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OVERTIME_ROUND_CHANGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_OVERTIME_ROUND_CHANGE_TURNS
	STRUCT_EVENT_COMMON_DETAILS Details

ENDSTRUCT

PROC BROADCAST_FMMC_OVERTIME_ROUND_CHANGE_TURNS()

	SCRIPT_EVENT_DATA_FMMC_OVERTIME_ROUND_CHANGE_TURNS Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_OVERTIME_ROUND_CHANGE_TURNS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	NET_PRINT("-----------------BROADCAST_FMMC_OVERTIME_ROUND_CHANGE_TURNS---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OVERTIME_ROUND_CHANGE_TURNS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_OVERTIME_LANDING
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bSuccessful
	INT iPart
	INT iTeam
ENDSTRUCT

PROC BROADCAST_FMMC_OVERTIME_LANDING(BOOL bSuccessful, INT iPart, INT iTeam)

	SCRIPT_EVENT_DATA_FMMC_OVERTIME_LANDING Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_OVERTIME_LANDING
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bSuccessful = bSuccessful
	Event.iPart = iPart
	Event.iTeam = iTeam
	
	NET_PRINT("-----------------BROADCAST_FMMC_OVERTIME_LANDING---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OVERTIME_LANDING - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_OVERTIME_VEHICLE_DESTROYED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPart
	INT iTeam
ENDSTRUCT

PROC BROADCAST_FMMC_OVERTIME_VEHICLE_DESTROYED(INT iPart, INT iTeam)

	SCRIPT_EVENT_DATA_FMMC_OVERTIME_VEHICLE_DESTROYED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_OVERTIME_VEHICLE_DESTROYED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPart = iPart
	Event.iTeam = iTeam
	
	
	NET_PRINT("-----------------BROADCAST_FMMC_OVERTIME_VEHICLE_DESTROYED---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OVERTIME_VEHICLE_DESTROYED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC
STRUCT SCRIPT_EVENT_DATA_FMMC_SUMO_ZONE_TIME_EXTEND_SHARD
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_FMMC_SUMO_ZONE_TIME_EXTEND_SHARD()
	
	SCRIPT_EVENT_DATA_FMMC_SUMO_ZONE_TIME_EXTEND_SHARD Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_SUMO_ZONE_TIME_EXTEND_SHARD
	
	NET_PRINT("-----------------BROADCAST_FMMC_SUMO_ZONE_TIME_EXTEND_SHARD---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_SUMO_ZONE_TIME_EXTEND_SHARD - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC
STRUCT SCRIPT_EVENT_DATA_FMMC_PP_TEAM_INTRO_ROOT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iRootNum
ENDSTRUCT

PROC BROADCAST_PP_INTRO_CHOSEN_TEAM_ROOT(INT iRootNum)
	SCRIPT_EVENT_DATA_FMMC_PP_TEAM_INTRO_ROOT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PP_TEAM_INTRO_ROOT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRootNum = iRootNum
	
	NET_PRINT("-----------------BROADCAST_PP_INTRO_CHOSEN_TEAM_ROOT---------------------------") NET_NL()
	PRINTLN("iRootNum = ", iRootNum)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT_EXCEPT_THIS_PLAYER(PLAYER_ID()) // send it to all players except me!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PP_INTRO_CHOSEN_TEAM_ROOT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF

ENDPROC

PROC BROADCAST_PP_PRE_INTRO_CHOSEN_ROOT(INT iRootNum)
	SCRIPT_EVENT_DATA_FMMC_PP_TEAM_INTRO_ROOT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PP_PRE_INTRO_ROOT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRootNum = iRootNum
	
	NET_PRINT("-----------------BROADCAST_PP_PRE_INTRO_CHOSEN_ROOT---------------------------") NET_NL()
	PRINTLN("iRootNum = ", iRootNum)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT_EXCEPT_THIS_PLAYER(PLAYER_ID()) // send it to all players except me!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PP_PRE_INTRO_CHOSEN_ROOT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF

ENDPROC

PROC BROADCAST_PP_SUDDDEATH_CHOSEN_ROOT(INT iRootNum)
	SCRIPT_EVENT_DATA_FMMC_PP_TEAM_INTRO_ROOT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PP_SUDDDEATH_ROOT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRootNum = iRootNum
	
	NET_PRINT("-----------------BROADCAST_PP_SUDDDEATH_CHOSEN_ROOT---------------------------") NET_NL()
	PRINTLN("iRootNum = ", iRootNum)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT_EXCEPT_THIS_PLAYER(PLAYER_ID()) // send it to all players except me!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PP_SUDDDEATH_CHOSEN_ROOT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF

ENDPROC

PROC BROADCAST_PP_WINNER_CHOSEN_ROOT(INT iRootNum)
	SCRIPT_EVENT_DATA_FMMC_PP_TEAM_INTRO_ROOT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PP_WINNER_ROOT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRootNum = iRootNum
	
	NET_PRINT("-----------------BROADCAST_PP_WINNER_CHOSEN_ROOT---------------------------") NET_NL()
	PRINTLN("iRootNum = ", iRootNum)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT_EXCEPT_THIS_PLAYER(PLAYER_ID()) // send it to all players except me!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PP_WINNER_CHOSEN_ROOT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF

ENDPROC

PROC BROADCAST_PP_EXIT_CHOSEN_ROOT(INT iRootNum)
	SCRIPT_EVENT_DATA_FMMC_PP_TEAM_INTRO_ROOT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PP_EXIT_ROOT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRootNum = iRootNum
	
	NET_PRINT("-----------------BROADCAST_PP_EXIT_CHOSEN_ROOT---------------------------") NET_NL()
	PRINTLN("iRootNum = ", iRootNum)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT_EXCEPT_THIS_PLAYER(PLAYER_ID()) // send it to all players except me!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PP_EXIT_CHOSEN_ROOT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF

ENDPROC

#IF IS_DEBUG_BUILD
STRUCT SCRIPT_EVENT_DATA_FMMC_PP_MANUAL_MUSIC
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iMusic
ENDSTRUCT

PROC BROADCAST_PP_MANUAL_MUSIC_CHANGE(INT iMusic)
	SCRIPT_EVENT_DATA_FMMC_PP_MANUAL_MUSIC Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_PP_MANUAL_MUSIC_CHANGE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iMusic = iMusic
	
	NET_PRINT("-----------------BROADCAST_PP_MANUAL_MUSIC_CHANGE---------------------------") NET_NL()
	PRINTLN("iMusic = ", iMusic)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PP_EXIT_CHOSEN_ROOT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC
#ENDIF

STRUCT SCRIPT_EVENT_DATA_FMMC_IN_AND_OUT_SFX_DETAILS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iActionType
	INT iTeam
ENDSTRUCT

PROC BROADCAST_IN_AND_OUT_SFX_PLAY(INT iActionType, INT iTeam)
	SCRIPT_EVENT_DATA_FMMC_IN_AND_OUT_SFX_DETAILS Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_IAO_SFX_PLAY
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iActionType = iActionType
	Event.iTeam = iTeam
	
	NET_PRINT("-----------------BROADCAST_IN_AND_OUT_SFX_PLAY---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PICKED_UP_POWERPLAY_POWERUP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_TRADING_PLACES_TRANSFORM_SFX
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_TRADING_PLACES_PLAY_TRANSFORM_SFX()
	SCRIPT_EVENT_DATA_FMMC_TRADING_PLACES_TRANSFORM_SFX Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_TP_TRANSFORM_SFX
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	NET_PRINT("-----------------BROADCAST_TRADING_PLACES_PLAY_TRANSFORM_SFX---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT_EXCEPT_THIS_PLAYER(PLAYER_ID())
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PICKED_UP_POWERPLAY_POWERUP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_RUG_PROCESS_PLAY_SOUND
	STRUCT_EVENT_COMMON_DETAILS Details
	INT soundToPlay
ENDSTRUCT


PROC BROADCAST_RUGBY_PLAY_SOUND(INT soundToPlay)
	SCRIPT_EVENT_DATA_FMMC_RUG_PROCESS_PLAY_SOUND Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_RUGBY_PLAY_SOUND
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.soundToPlay = soundToPlay
	
	NET_PRINT("-----------------BROADBAST_RUGBY_PLAY_SOUND---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADBAST_RUGBY_PLAY_SOUND - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//[KH] Event that broadcasts when the rugby ball has been dropped and how much distance was gained
PROC BROADCAST_FMMC_DISTANCE_GAINED_TICKER(INT iTeam, INT iDistanceMeters, INT iDistanceFeet, BOOL bGainedDistance)
	
	SCRIPT_EVENT_DATA_FMMC_DISTANCE_GAINED Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_DISTANCE_GAINED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iteam = iTeam
	Event.iDistanceMeters = iDistanceMeters
	Event.iDistanceFeet = iDistanceFeet
	Event.bGainedDistance = bGainedDistance
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OBJECTIVE_END_MESSAGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_SUDDEN_DEATH_REASON
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INT iReason
ENDSTRUCT

PROC BROADCAST_FMMC_SUDDEN_DEATH_REASON(INT iTeam, INT iReason)
	SCRIPT_EVENT_DATA_FMMC_SUDDEN_DEATH_REASON Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_SUDDEN_DEATH_REASON
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iteam = iTeam
	Event.iReason = iReason
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OBJECTIVE_END_MESSAGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

#IF IS_DEBUG_BUILD

STRUCT SCRIPT_EVENT_DATA_FMMC_OVERRIDE_LIVES_FAIL

	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bIgnoreOutOfLivesFail

ENDSTRUCT

PROC BROADCAST_FMMC_OVERRIDE_LIVES_FAIL(BOOL bIgnoreOutOfLivesFail)

	SCRIPT_EVENT_DATA_FMMC_OVERRIDE_LIVES_FAIL Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_OVERRIDE_LIVES_FAIL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bIgnoreOutOfLivesFail = bIgnoreOutOfLivesFail

	NET_PRINT("-----------------BROADCAST_FMMC_OVERRIDE_LIVES_FAIL---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OVERRIDE_LIVES_FAIL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF

ENDPROC

#ENDIF

STRUCT SCRIPT_EVENT_DATA_FMMC_PARTICIPANT_ID
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPart

ENDSTRUCT

PROC BROADCAST_FMMC_APARTMENTWARP_CS_REQUEST(INT iPart)
	SCRIPT_EVENT_DATA_FMMC_PARTICIPANT_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_APARTMENTWARP_CS_REQUEST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPart = iPart
	
	NET_PRINT("-----------------BROADCAST_FMMC_APARTMENTWARP_CS_REQUEST---------------------------") NET_NL()
	NET_PRINT("Event.iPart = ") NET_PRINT_INT(Event.iPart ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_APARTMENTWARP_CS_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_APARTMENTWARP_CS_RELEASE(INT iPart)
	SCRIPT_EVENT_DATA_FMMC_PARTICIPANT_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_APARTMENTWARP_CS_RELEASE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPart = iPart
	
	NET_PRINT("-----------------BROADCAST_FMMC_APARTMENTWARP_CS_RELEASE---------------------------") NET_NL()
	NET_PRINT("Event.iPart = ") NET_PRINT_INT(Event.iPart ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_APARTMENTWARP_CS_RELEASE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_HEARING(INT iPed)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_HEARING
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iPed
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_HEARING---------------------------") NET_NL()
	NET_PRINT("Event.iPedid = ") NET_PRINT_INT(Event.iPedid ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_HEARING - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_REMOTELY_ADD_RESPAWN_POINTS
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INT iRespawnPoint
	BOOL bDeactivateOthers
	
ENDSTRUCT

PROC BROADCAST_FMMC_REMOTELY_ADD_RESPAWN_POINTS(INT iTeam, INT iRespawnPoint, BOOL bDeactivateOthers)
	
	SCRIPT_EVENT_DATA_FMMC_REMOTELY_ADD_RESPAWN_POINTS Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_REMOTELY_ADD_RESPAWN_POINTS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	Event.iRespawnPoint = iRespawnPoint
	Event.bDeactivateOthers = bDeactivateOthers
	
	NET_PRINT("-----------------BROADCAST_FMMC_REMOTELY_ADD_RESPAWN_POINTS---------------------------") NET_NL()
	NET_PRINT("Event.iTeamSender = ") NET_PRINT_INT(GET_PLAYER_TEAM(PLAYER_ID())) NET_NL()
	NET_PRINT("Event.iTeam = ") NET_PRINT_INT(Event.iTeam) NET_NL()
	NET_PRINT("Event.iRespawnPoint = ") NET_PRINT_INT(Event.iRespawnPoint) NET_NL()
	NET_PRINT("Event.bDeactivateOthers = ") NET_PRINT_BOOL(Event.bDeactivateOthers) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("SCRIPT_EVENT_FMMC_REMOTELY_ADD_RESPAWN_POINTS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PED_SPOOKED
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPed
	INT iSpookedReason
	INT iPartCausingFail
	INT iTimeStamp
ENDSTRUCT

PROC BROADCAST_FMMC_PED_SPOOKED(INT iPed, INT iSpookedReason = 0, INT iPartCausingFail = -1, INT iTimeStamp = -1)
	
	SCRIPT_EVENT_DATA_FMMC_PED_SPOOKED Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_SPOOKED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPed = iPed
	Event.iSpookedReason = iSpookedReason
	Event.iPartCausingFail = iPartCausingFail
	Event.iTimeStamp = iTimeStamp
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_SPOOKED [SpookAggro]---------------------------") NET_NL()
	NET_PRINT("Event.iPedid = ") NET_PRINT_INT(Event.iPed) NET_NL()
	NET_PRINT("Event.iSpookedReason = ") NET_PRINT_INT(Event.iSpookedReason) NET_NL()
	NET_PRINT("Event.iPartCausingFail = ") NET_PRINT_INT(Event.iPartCausingFail) NET_NL()
	DEBUG_PRINTCALLSTACK()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("SCRIPT_EVENT_FMMC_PED_SPOOKED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_UNSPOOKED(INT iPed)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_UNSPOOKED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iPed
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_UNSPOOKED---------------------------") NET_NL()
	NET_PRINT("Event.iPedid = ") NET_PRINT_INT(Event.iPedid ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_UNSPOOKED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_SPOOK_HURTORKILLED(INT iPed)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_SPOOK_HURTORKILLED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iPed
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_SPOOK_HURTORKILLED---------------------------") NET_NL()
	NET_PRINT("Event.iPedid = ") NET_PRINT_INT(Event.iPedid ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_SPOOK_HURTORKILLED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_GIVEN_SPOOKED_GOTO_TASK(INT iped)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_GIVEN_SPOOKED_GOTO_TASK
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iPed
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_GIVEN_SPOOKED_GOTO_TASK---------------------------") NET_NL()
	NET_PRINT("Event.iPedid = ") NET_PRINT_INT(Event.iPedid ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_SPOOK_HURTORKILLED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_GIVEN_UNSPOOKED_GOTO_TASK(INT iped)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_GIVEN_UNSPOOKED_GOTO_TASK
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iPed
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_GIVEN_UNSPOOKED_GOTO_TASK---------------------------") NET_NL()
	NET_PRINT("Event.iPedid = ") NET_PRINT_INT(Event.iPedid ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send this to everyone
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_SPOOK_HURTORKILLED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_UPDATE_TASKED_GOTO_PROGRESS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPedID
	INT iGotoProgress
ENDSTRUCT

PROC BROADCAST_FMMC_PED_UPDATE_TASKED_GOTO_PROGRESS(INT iPed, INT iGotoProgress)
	
	SCRIPT_EVENT_DATA_FMMC_UPDATE_TASKED_GOTO_PROGRESS Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_UPDATE_TASKED_GOTO_PROGRESS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iPed
	Event.iGotoProgress = iGotoProgress
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_UPDATE_TASKED_GOTO_PROGRESS---------------------------") NET_NL()
	NET_PRINT("Event.iPedid = ") NET_PRINT_INT(Event.iPedid ) NET_NL()
	NET_PRINT("Event.iGotoProgress = ") NET_PRINT_INT(Event.iGotoProgress ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send this to everyone
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_UPDATE_TASKED_GOTO_PROGRESS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_AGGROED_PED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPedID
	BOOL bZoneForced
	INT iPartCausingFail
ENDSTRUCT

PROC BROADCAST_FMMC_PED_AGGROED(INT iPed, INT iPartCausingFail = -1,  BOOL bZoneForced = FALSE)
	
	SCRIPT_EVENT_DATA_FMMC_AGGROED_PED Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_AGGROED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedID = iPed
	Event.iPartCausingFail = iPartCausingFail
	Event.bZoneForced = bZoneForced
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_AGGROED---------------------------") NET_NL()
	NET_PRINT("Event.iPedID = ") NET_PRINT_INT(Event.iPedID) NET_NL()
	NET_PRINT("Event.iPartCausingFail = ") NET_PRINT_INT(Event.iPartCausingFail) NET_NL()
	NET_PRINT("Event.bZoneForced = ") NET_PRINT_BOOL(Event.bZoneForced) NET_NL()
	DEBUG_PRINTCALLSTACK()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_AGGROED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_SPEECH_AGGROED(INT iPed, INT iPartCausingFail = -1)
	
	SCRIPT_EVENT_DATA_FMMC_AGGROED_PED Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_SPEECH_AGGROED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedID = iPed
	Event.iPartCausingFail = iPartCausingFail
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_SPEECH_AGGROED---------------------------") NET_NL()
	NET_PRINT("Event.iPedID = ") NET_PRINT_INT(Event.iPedID) NET_NL()
	NET_PRINT("Event.iPartCausingFail = ") NET_PRINT_INT(Event.iPartCausingFail) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_SPEECH_AGGROED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_CANCEL_TASKS(INT iPed)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_CANCEL_TASKS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iPed
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_CANCEL_TASKS---------------------------") NET_NL()
	NET_PRINT("Event.iPedid = ") NET_PRINT_INT(Event.iPedid ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_CANCEL_TASKS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PED_SPEECH_AGRO_BITSET(INT iPed)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_SPEECH_AGRO_BITSET
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iPed
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_SPEECH_AGRO_BITSET---------------------------") NET_NL()
	NET_PRINT("Event.iPedid = ") NET_PRINT_INT(Event.iPedid ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send to all players!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_SPEECH_AGRO_BITSET - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_OBJECTIVE_COMPLETE(INT iObjectiveID,INT iparticipant,INT iEntitID,INT iPriority, INT iRevalidates, INT &iBitsetArrayPassed[])
	SCRIPT_EVENT_DATA_FMMC_OBJECTIVE_COMPLETE Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_OBJECTIVE_COMPLETE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iObjectiveID = iObjectiveID
	Event.iparticipant = iparticipant
	Event.iEntityID = iEntitID
	Event.iPriority = iPriority
	Event.iRevalidates = iRevalidates
	
	NET_PRINT("-----------------BROADCAST_FMMC_OBJECTIVE_COMPLETE---------------------------") NET_NL()
	INT i = 0 
	REPEAT COUNT_OF(iBitsetArrayPassed) i
		IF i < COUNT_OF(iBitsetArrayPassed)
			Event.iBitsetArrayPassed[i] = iBitsetArrayPassed[i]
			NET_PRINT("Event.iBitsetArrayPassed = ") NET_PRINT_INT(Event.iBitsetArrayPassed[i] ) NET_NL()
		ELSE
			NET_PRINT("Event.iBitsetArrayPassed size = ") NET_PRINT_INT(i) NET_NL()
			BREAKLOOP
		ENDIF
	ENDREPEAT
	NET_PRINT("Event.iObjectiveID = ") NET_PRINT_INT(Event.iObjectiveID ) NET_NL()
	NET_PRINT("Event.iparticipant = ") NET_PRINT_INT(Event.iparticipant) NET_NL()
	NET_PRINT("Event.iEntityID = ") NET_PRINT_INT(Event.iEntityID) NET_NL()
	NET_PRINT("Event.iPriority = ") NET_PRINT_INT(Event.iPriority) NET_NL()
	NET_PRINT("Event.iRevalidates = ") NET_PRINT_INT(Event.iRevalidates) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OBJECTIVE_COMPLETE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC


PROC BROADCAST_NETWORK_INDEX_FOR_LATER_RULE(NETWORK_INDEX LaterObjectiveNetID,INT iLaterObjectiveType,INT iLaterObjectiveID)
	SCRIPT_EVENT_DATA_NETWORK_INDEX_FOR_LATER_RULE Event

	Event.Details.Type = SCRIPT_EVENT_NETWORK_INDEX_FOR_LATER_RULE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.NetIdForLaterObjective = LaterObjectiveNetID
	Event.iLaterObjectiveType = iLaterObjectiveType
	Event.iLaterObjectiveEntityIndex = iLaterObjectiveID

	
	NET_PRINT("-----------------BROADCAST_NETWORK_INDEX_FOR_LATER_RULE---------------------------") NET_NL()
	NET_PRINT("Event.NetIdForLaterObjective = ") NET_PRINT_INT(NATIVE_TO_INT(Event.NetIdForLaterObjective)) NET_NL()
	NET_PRINT("Event.iLaterObjectiveType = ") NET_PRINT_INT(Event.iLaterObjectiveType ) NET_NL()
	NET_PRINT("Event.iLaterObjectiveEntityIndex = ") NET_PRINT_INT(Event.iLaterObjectiveEntityIndex) NET_NL()

	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_NETWORK_INDEX_FOR_LATER_RULE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC


PROC BROADCAST_SCRIPT_EVENT_BLOCK_SAVE_EOM_CAR_BEEN_DELIVERED(NETWORK_INDEX vehNetID )
	
	SCRIPT_EVENT_DATA_FMMC_NETWORK_INDEX Event

	Event.Details.Type = SCRIPT_EVENT_BLOCK_SAVE_EOM_CAR_BEEN_DELIVERED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vehNetID = vehNetID
	
	NET_PRINT("-----------------BROADCAST_SCRIPT_EVENT_BLOCK_SAVE_EOM_CAR_BEEN_DELIVERED---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SCRIPT_EVENT_BLOCK_SAVE_EOM_CAR_BEEN_DELIVERED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

PROC BROADCAST_FMMC_OBJECTIVE_END_MESSAGE(INT iObjectiveID, INT iteam,INT ipriority,BOOL bpass, BOOL bFailMission = FALSE)
	
	SCRIPT_EVENT_DATA_FMMC_OBJECTIVE_END_MESSAGE Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_OBJECTIVE_END_MESSAGE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iObjectiveID = iObjectiveID
	Event.ipriority = ipriority
	Event.iteam = iteam
	Event.bpass = bpass
	Event.bFailMission = bFailMission
	Event.iTimeStamp = NATIVE_TO_INT(GET_NETWORK_TIME())
	
	NET_PRINT("-----------------BROADCAST_FMMC_OBJECTIVE_END_MESSAGE---------------------------") NET_NL()
	NET_PRINT("Event.iObjectiveID = ") NET_PRINT_INT(Event.iObjectiveID ) NET_NL()
	NET_PRINT("Event.ipriority = ") NET_PRINT_INT(Event.ipriority) NET_NL()
	NET_PRINT("Event.iteam = ") NET_PRINT_INT(Event.iteam) NET_NL()
	IF Event.bpass
		NET_PRINT("Event.bpass = TRUE ") NET_NL()
	ELSE
		NET_PRINT("Event.bpass = FALSE ") NET_NL()
	ENDIF
	IF Event.bFailMission
		NET_PRINT("Event.bFailMission = TRUE ") NET_NL()
	ELSE
		NET_PRINT("Event.bFailMission = FALSE ") NET_NL()
	ENDIF
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OBJECTIVE_END_MESSAGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

//[KH] Event that broadcasts when a player has been knocked out of bounds
PROC BROADCAST_FMMC_OBJECTIVE_PLAYER_KNOCKED_OUT(int iTeam)
	
	SCRIPT_EVENT_DATA_FMMC_PLAYER_KNOCKED_OUT Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PLAYER_KNOCKED_OUT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iteam = iTeam
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OBJECTIVE_END_MESSAGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

PROC BROADCAST_FMMC_PLAYER_TEAM_SWITCH_REQUEST(INT iSessionKey, INT iTeam, INT iNewTeam, INT iVictimPart, PLAYER_INDEX piKiller, BOOL bSuicide = FALSE, BOOL bNoVictim = FALSE)
	SCRIPT_EVENT_DATA_FMMC_PLAYER_TEAM_SWITCH_REQUEST Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PLAYER_TEAM_SWITCH_REQUEST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	Event.iNewTeam = iNewTeam
	Event.iVictimPart = iVictimPart
	Event.bSuicide = bSuicide
	Event.bNoVictim = bNoVictim
	Event.piKiller = piKiller
	Event.iEventSessionKey = iSessionKey	
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PLAYER_TEAM_SWITCH_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//[KH] Event that broadcasts when a player has switched teams
PROC BROADCAST_FMMC_OBJECTIVE_PLAYER_SWITCHED_TEAMS(int iTeam, int iNewTeam, BOOL bShowShard = FALSE)
	
	SCRIPT_EVENT_DATA_FMMC_PLAYER_SWITCHED_TEAMS Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PLAYER_SWITCHED_TEAMS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iteam = iTeam
	Event.iNewTeam = iNewTeam
	Event.bShowShard = bShowShard
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OBJECTIVE_END_MESSAGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

PROC BROADCAST_SERVER_AUTHORISED_TEAM_SWAP(INT iKillerPart, INT iKillerNewTeam, INT iVictimPart, INT iVictimNewTeam, BOOL bSuicide, INT iSessionKey)
	SCRIPT_EVENT_DATA_SERVER_AUTHORISED_TEAM_SWAP Event
	
	Event.Details.Type = SCRIPT_EVENT_SERVER_AUTHORISED_TEAM_SWAP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iKillerPart = iKillerPart
	Event.iKillerNewTeam = iKillerNewTeam
	Event.iVictimPart = iVictimPart
	Event.iVictimNewTeam = iVictimNewTeam
	Event.bSuicide = bSuicide
	Event.iEventSessionKey = iSessionKey	
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SERVER_AUTHORISED_TEAM_SWAP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_CLIENT_TEAM_SWAP_COMPLETE(INT iPartToClear)
	SCRIPT_EVENT_DATA_CLIENT_TEAM_SWAP_COMPLETE Event
	
	Event.Details.Type = SCRIPT_EVENT_CLIENT_TEAM_SWAP_COMPLETE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPartToClear = iPartToClear
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CLIENT_TEAM_SWAP_COMPLETE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//[AW] Event that broadcasts when a player has commited suicide
PROC BROADCAST_FMMC_PLAYER_COMMITED_SUICIDE(int iTeam)
	
	SCRIPT_EVENT_DATA_FMMC_PLAYER_COMMITED_SUICIDE Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PLAYER_COMMITED_SUICIDE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iteam = iTeam
	
	PRINTLN("[BROADCAST_FMMC_PLAYER_COMMITED_SUICIDE][RH] Player has commited suicide and is from team: ", iTeam)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT(FALSE) // send it to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OBJECTIVE_END_MESSAGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_REQUEST_WAREHOUSE_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iWarehouseID
ENDSTRUCT

PROC BROADCAST_WAREHOUSE_DATA_REQUEST(PLAYER_INDEX pWHOwner, INT iWarehouseID)

	SCRIPT_EVENT_DATA_REQUEST_WAREHOUSE_DATA Event
	Event.Details.Type = SCRIPT_EVENT_REQUEST_WAREHOUSE_DATA
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iWarehouseID = iWarehouseID
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(pWHOwner))
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_WAREHOUSE_DATA_A
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iData[50]
ENDSTRUCT

PROC BROADCAST_WAREHOUSE_DATA_A(PLAYER_INDEX HostID, INT &iData[])

	SCRIPT_EVENT_DATA_WAREHOUSE_DATA_A Event
	Event.Details.Type = SCRIPT_EVENT_WAREHOUSE_DATA_A
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT i
	REPEAT COUNT_OF(iData) i
		Event.iData[i] = iData[i]
	ENDREPEAT
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(HostID))
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_WAREHOUSE_DATA_B
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iData[50]
ENDSTRUCT

PROC BROADCAST_WAREHOUSE_DATA_B(PLAYER_INDEX HostID, INT &iData[])

	SCRIPT_EVENT_DATA_WAREHOUSE_DATA_B Event
	Event.Details.Type = SCRIPT_EVENT_WAREHOUSE_DATA_B
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT i
	REPEAT COUNT_OF(iData) i
		Event.iData[i] = iData[i]
	ENDREPEAT
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(HostID))
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_WAREHOUSE_DATA_C
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iData[11]
ENDSTRUCT

PROC BROADCAST_WAREHOUSE_DATA_C(PLAYER_INDEX HostID, INT &iData[])

	SCRIPT_EVENT_DATA_WAREHOUSE_DATA_C Event
	Event.Details.Type = SCRIPT_EVENT_WAREHOUSE_DATA_C
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT i
	REPEAT COUNT_OF(iData) i
		Event.iData[i] = iData[i]
	ENDREPEAT
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(HostID))
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DELIVERED_SINGLE_CRATE_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCrateModelIndex
	INT iCrateID
	INT iWHSlot
ENDSTRUCT

PROC BROADCAST_DELIVERED_SINGLE_CRATE(PLAYER_INDEX OwnerID, INT iWHSlot, INT iCrateID, INT iCrateModelIndex)
	
	SCRIPT_EVENT_DATA_DELIVERED_SINGLE_CRATE_DATA Event
	Event.Details.Type = SCRIPT_EVENT_DELIVERED_SINGLE_CRATE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iCrateModelIndex = iCrateModelIndex
	Event.iCrateID = iCrateID
	Event.iWHSlot = iWHSlot
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(OwnerID))
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_REQUEST_HANGAR_PRODUCT_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_REQUEST_HANGAR_PRODUCT_DATA(PLAYER_INDEX pWHOwner)
	
	SCRIPT_EVENT_DATA_REQUEST_WAREHOUSE_DATA Event
	Event.Details.Type = SCRIPT_EVENT_REQUEST_HANGAR_PRODUCT_DATA
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(pWHOwner))
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_SEND_HANGAR_PRODUCT_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iProductData[50]
ENDSTRUCT

PROC BROADCAST_SEND_HANGAR_PRODUCT_DATA(PLAYER_INDEX HostID, INT &iProductData[])
	
	SCRIPT_EVENT_DATA_SEND_HANGAR_PRODUCT_DATA Event
	Event.Details.Type = SCRIPT_EVENT_SEND_HANGAR_PRODUCT_DATA
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT i
	REPEAT COUNT_OF(iProductData) i
		Event.iProductData[i] = iProductData[i]
	ENDREPEAT
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(HostID))
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DELIVERED_HANGAR_MISSION_PRODUCT_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iProductSlot
	INT iModelIndex
ENDSTRUCT

PROC BROADCAST_DELIVERED_HANGAR_MISSION_PRODUCT(PLAYER_INDEX OwnerID, INT iProductSlot, INT iModelIndex)
	
	SCRIPT_EVENT_DATA_DELIVERED_HANGAR_MISSION_PRODUCT_DATA Event
	Event.Details.Type = SCRIPT_EVENT_DELIVERED_HANGAR_MISSION_PRODUCT_DATA
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iProductSlot = iProductSlot
	Event.iModelIndex = iModelIndex
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(OwnerID))
	
ENDPROC

#IF IS_DEBUG_BUILD
STRUCT SCRIPT_EVENT_DATA_REMOVE_HANGAR_MISSION_PRODUCT_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX pOwner
ENDSTRUCT

PROC BROADCAST_REMOVE_HANGAR_MISSION_PRODUCT(PLAYER_INDEX OwnerID)
	
	SCRIPT_EVENT_DATA_REMOVE_HANGAR_MISSION_PRODUCT_DATA Event
	Event.Details.Type = SCRIPT_EVENT_REMOVE_HANGAR_MISSION_PRODUCT_DATA
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.pOwner = OwnerID
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(OwnerID))
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_ADD_HANGAR_MISSION_PRODUCT_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX pOwner
ENDSTRUCT

PROC BROADCAST_ADD_HANGAR_MISSION_PRODUCT(PLAYER_INDEX OwnerID)
	
	SCRIPT_EVENT_DATA_ADD_HANGAR_MISSION_PRODUCT_DATA Event
	Event.Details.Type = SCRIPT_EVENT_ADD_HANGAR_MISSION_PRODUCT_DATA
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.pOwner = OwnerID
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(OwnerID))
	
ENDPROC
#ENDIF

STRUCT SCRIPT_EVENT_DATA_GANG_STATUS_CHANGED
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL doHeadshot
ENDSTRUCT

PROC BROADCAST_GANG_STATUS_CHANGED(INT iPlayerFlags, BOOL DoHeadshot = FALSE)

	SCRIPT_EVENT_DATA_GANG_STATUS_CHANGED Event
	Event.Details.Type = SCRIPT_EVENT_GANG_STATUS_CHANGED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.doHeadshot = DoHeadshot
	
	IF DoHeadshot
		NET_PRINT("BROADCAST_GANG_STATUS_CHANGED - Refresh pedheads ") NET_NL()	
	ENDIF
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
ENDPROC

PROC BROADCAST_FMMC_OBJECTIVE_PLAYER_KNOCKED_OUT_NOISE()
	
	SCRIPT_EVENT_DATA_FMMC_PLAYER_KNOCKED_OUT Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PLAYER_KNOCKED_OUT_NOISE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OBJECTIVE_END_MESSAGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

PROC BROADCAST_BMB_BOMB_CREATED_MESSAGE( NETWORK_INDEX netBombID, INT radius )
	
	SCRIPT_EVENT_DATA_BMB_BOMB_DETAILS Event

	Event.Details.Type = SCRIPT_EVENT_BMB_BOMB_PLACED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bombID = netBombID
	Event.radius = radius

	NET_PRINT("-----------------BROADCAST_BMB_BOMB_CREATED_MESSAGE---------------------------") NET_NL()
	PRINTLN( "[BMB-NET] BROADCAST_BMB_BOMB_CREATED_MESSAGE, Native index: ", NATIVE_TO_INT( netBombID ) )

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_BMB_BOMB_CREATED_MESSAGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

PROC BROADCAST_BMB_PICKUP_CREATED_MESSAGE( INT chance1, INT chance2, VECTOR pos, BMB_POWERUP_TYPES type, INT i )
	
	SCRIPT_EVENT_DATA_BMB_PICKUP_DETAILS Event

	Event.Details.Type = SCRIPT_EVENT_BMB_PICKUP_CREATED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.chance1 = chance1
	Event.chance2 = chance2
	Event.propPos = pos
	Event.pickupType = type
	Event.i = i

	NET_PRINT("-----------------BROADCAST_BMB_PICKUP_CREATED_MESSAGE---------------------------") NET_NL()
	PRINTLN( "[BMB-NET] BROADCAST_BMB_PICKUP_CREATED_MESSAGE, Chance1: ", chance1, ", Chance2: ", chance2 )

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_BMB_PICKUP_CREATED_MESSAGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

PROC BROADCAST_BMB_PROP_DESTROY_MESSAGE( INT creatorPropIdx )
	
	SCRIPT_EVENT_DATA_BMB_PROP_DETAILS Event

	Event.Details.Type = SCRIPT_EVENT_BMB_PROP_DESTROY
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.propIdx = creatorPropIdx

	NET_PRINT("-----------------BROADCAST_BMB_PROP_DESTROY_MESSAGE---------------------------") NET_NL()
	PRINTLN( "[BMB-NET] BROADCAST_BMB_PROP_DESTROY_MESSAGE, Creator ID: ", creatorPropIdx )

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_BMB_PROP_DESTROY_MESSAGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

STRUCT SCRIPT_EVENT_PLAYER_CROSSED_LINE_DETAILS
	STRUCT_EVENT_COMMON_DETAILS Details	
	INT iTeam
ENDSTRUCT

PROC BROADCAST_FMMC_PLAYER_CROSSED_LINE( INT iTeam )
	
	SCRIPT_EVENT_PLAYER_CROSSED_LINE_DETAILS Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_PLAYER_CROSSED_THE_LINE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam

	NET_PRINT("-----------------BROADCAST_FMMC_PLAYER_CROSSED_LINE---------------------------") NET_NL()
	PRINTLN( "[RCC MISSION] BROADCAST_FMMC_PLAYER_CROSSED_LINE, iTeam: ", iTeam)

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PLAYER_CROSSED_LINE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

STRUCT SCRIPT_EVENT_PLAYER_IS_SWAN_DIVE_SCORING
	STRUCT_EVENT_COMMON_DETAILS Details	
ENDSTRUCT

PROC BROADCAST_FMMC_PLAYER_IS_SWAN_DIVE_SCORING()
	SCRIPT_EVENT_PLAYER_IS_SWAN_DIVE_SCORING Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_PLAYER_IS_SWAN_DIVE_SCORING
	Event.Details.FromPlayerIndex = PLAYER_ID()

	NET_PRINT("-----------------BROADCAST_FMMC_PLAYER_IS_SWAN_DIVE_SCORING---------------------------") NET_NL()

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT_EXCEPT_THIS_PLAYER(GET_PLAYER_INDEX()) // send it to everyone but me!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PLAYER_CROSSED_LINE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_RANDOM_SPAWN_POS_DETAILS
	STRUCT_EVENT_COMMON_DETAILS Details	
	INT iTeam
	INT iSpawnSlot
ENDSTRUCT

PROC BROADCAST_RANDOM_SPAWN_SLOT_USED_FOR_TEAM( INT iTeam, INT iSpawnSlot )
	
	SCRIPT_EVENT_RANDOM_SPAWN_POS_DETAILS Event

	Event.Details.Type = SCRIPT_EVENT_RANDOM_SPAWN_SLOT_USED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	Event.iSpawnSlot = iSpawnSlot

	NET_PRINT("-----------------BROADCAST_RANDOM_SPAWN_SLOT_USED_FOR_TEAM---------------------------") NET_NL()
	PRINTLN( "[RCC MISSION] BROADCAST_RANDOM_SPAWN_SLOT_USED_FOR_TEAM, iTeam: ", iTeam)
	PRINTLN( "[RCC MISSION] BROADCAST_RANDOM_SPAWN_SLOT_USED_FOR_TEAM, iSpawnSlot: ", iSpawnSlot)

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_RANDOM_SPAWN_SLOT_USED_FOR_TEAM - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

STRUCT SCRIPT_EVENT_PRON_PLAYERS_DRAWING_TRAILS_DETAILS
	STRUCT_EVENT_COMMON_DETAILS Details	
	INT iPlayer
	BOOL bIsPlayerDrawing
ENDSTRUCT

PROC BROADCAST_PRON_PLAYERS_DRAWING_TRAILS( INT iPlayer, BOOL bIsPlayerDrawing )
	
	SCRIPT_EVENT_PRON_PLAYERS_DRAWING_TRAILS_DETAILS Event

	Event.Details.Type = SCRIPT_EVENT_PRON_PLAYERS_DRAWING_TRAILS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPlayer = iPlayer
	Event.bIsPlayerDrawing = bIsPlayerDrawing

	NET_PRINT("-----------------BROADCAST_PRON_PLAYERS_DRAWING_TRAILS---------------------------") NET_NL()
	PRINTLN( "[RCC MISSION] BROADCAST_PRON_PLAYERS_DRAWING_TRAILS, iPlayer: ", iPlayer)
	PRINTLN( "[RCC MISSION] BROADCAST_PRON_PLAYERS_DRAWING_TRAILS, bIsPlayerDrawing: ", bIsPlayerDrawing)

	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PRON_PLAYERS_DRAWING_TRAILS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_TRIGGERED_BODY_SCANNER
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_EVENT_FMMC_TRIGGERED_BODY_SCANNER()
		
	SCRIPT_EVENT_DATA_FMMC_TRIGGERED_BODY_SCANNER Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_TRIGGERED_BODY_SCANNER
	Event.Details.FromPlayerIndex = PLAYER_ID()

	NET_PRINT("-----------------BROADCAST_TRIGGERED_BODY_SCANNER---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_TRIGGERED_BODY_SCANNER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

PROC BROADCAST_TEAM_HAS_FINISHED_CUTSCENE_EVENT( INT iTeam )
	SCRIPT_EVENT_DATA_FMMC_TEAM_HAS_FINISHED_CUTSCENE Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_TEAM_HAS_FINISHED_CUTSCENE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iteam

	NET_PRINT("-----------------BROADCAST_TEAM_HAS_FINISHED_CUTSCENE_EVENT---------------------------") NET_NL()
	CPRINTLN( DEBUG_CONTROLLER, "BROADCAST_TEAM_HAS_FINISHED_CUTSCENE_EVENT for team ", Event.iteam )
	NET_PRINT("Event.iteam = ") NET_PRINT_INT(Event.iteam) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT( SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags )	
	ELSE
		NET_PRINT("BROADCAST_TEAM_HAS_FINISHED_CUTSCENE_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
ENDPROC

PROC BROADCAST_TEAM_HAS_EARLY_CELEBRATION( INT iTeam, INT iWinningPoints )
	SCRIPT_EVENT_DATA_FMMC_TEAM_HAS_EARLY_CELEBRATION Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_TEAM_HAS_EARLY_CELEBRATION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iteam
	Event.iWinningPoints = iWinningPoints

	NET_PRINT("-----------------BROADCAST_TEAM_HAS_EARLY_CELEBRATION_EVENT---------------------------") NET_NL()
	CPRINTLN( DEBUG_CONTROLLER, "BROADCAST_TEAM_HAS_EARLY_CELEBRATION_EVENT for team ", Event.iteam )
	NET_PRINT("Event.iteam = ") NET_PRINT_INT(Event.iteam) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT( SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF( Event ), iPlayerFlags )	
	ELSE
		NET_PRINT("BROADCAST_TEAM_HAS_FINISHED_CUTSCENE_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_OBJECTIVE_MID_POINT(INT iObjective, INT iteam)
	
	
	SCRIPT_EVENT_DATA_FMMC_OBJECTIVE_MID_POINT Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_OBJECTIVE_MID_POINT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iteam
	Event.iObjective = iObjective

	NET_PRINT("-----------------BROADCAST_OBJECTIVE_MID_POINT---------------------------") NET_NL()
	NET_PRINT("Event.iObjectiveID = ") NET_PRINT_INT(Event.iObjective) NET_NL()
	NET_PRINT("Event.iteam = ") NET_PRINT_INT(Event.iteam) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_OBJECTIVE_MID_POINT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

PROC BROADCAST_CUTSCENE_SPAWN_PROGRESS(INT iCutscene, INT iCamShot)
	
	
	SCRIPT_EVENT_DATA_CUTSCENE_SPAWN_PROGRESS Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_CUTSCENE_SPAWN_PROGRESS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iCutscene = iCutscene
	Event.iCutsceneCamShot = iCamShot

	NET_PRINT("-----------------BROADCAST_CUTSCENE_SPAWN_PROGRESS---------------------------") NET_NL()
	NET_PRINT("Event.iCutscene = ") NET_PRINT_INT(Event.iCutscene) NET_NL()
	NET_PRINT("Event.iCamShot = ") NET_PRINT_INT(Event.iCutsceneCamShot) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CUTSCENE_SPAWN_PROGRESS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

PROC BROADCAST_FMMC_PRI_FIN_MCS2_PLANE_NON_CRITICAL(INT iVeh)
	
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PRI_FIN_MCS2_PLANE_NON_CRITICAL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedID = iVeh
	
	NET_PRINT("-----------------BROADCAST_FMMC_PRI_FIN_MCS2_PLANE_NON_CRITICAL---------------------------") NET_NL()
	NET_PRINT("Event.iPedID (iveh) = ") NET_PRINT_INT(iVeh) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PRI_FIN_MCS2_PLANE_NON_CRITICAL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_FMMC_PRI_FIN_MCS2_PLANE_CLEANUP(NETWORK_INDEX vehNetID)
	
	SCRIPT_EVENT_DATA_FMMC_NETWORK_INDEX Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PRI_FIN_MCS2_PLANE_CLEANUP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vehNetID = vehNetID
	
	NET_PRINT("-----------------BROADCAST_FMMC_PRI_FIN_MCS2_PLANE_CLEANUP---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_PRI_FIN_MCS2_PLANE_CLEANUP - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_FORCING_EVERYONE_FROM_VEH
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iVeh
	INT iPart
	
ENDSTRUCT

PROC BROADCAST_FMMC_FORCING_EVERYONE_FROM_VEH(INT iveh, INT iPart)
	
	SCRIPT_EVENT_DATA_FMMC_FORCING_EVERYONE_FROM_VEH Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_FORCING_EVERYONE_FROM_VEH
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iveh = iVeh
	Event.iPart = iPart
	
	NET_PRINT("-----------------BROADCAST_FMMC_FORCING_EVERYONE_FROM_VEH---------------------------") NET_NL()
	NET_PRINT("Event.iveh = ") NET_PRINT_INT(iVeh) NET_NL()
	NET_PRINT("Event.iPart = ") NET_PRINT_INT(iPart) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // broadcast to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_FORCING_EVERYONE_FROM_VEH - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

PROC BROADCAST_VIP_MARKER_POSITION(VECTOR vMarker)
	SCRIPT_EVENT_DATA_VIP_MARKER Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_VIP_MARKER_POSITION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vVIPMarkerPosition = vMarker

	NET_PRINT( "-----------------BROADCAST_VIP_MARKER_POSITION---------------------------" ) NET_NL()
	NET_PRINT( "Event.vVIPMarkerPosition = " ) NET_PRINT_VECTOR( Event.vVIPMarkerPosition ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF( iPlayerFlags <> 0 )
		SEND_TU_SCRIPT_EVENT( SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF( Event ), iPlayerFlags )	
	ELSE
		NET_PRINT( "BROADCAST_VIP_MARKER_POSITION - playerflags = 0 so not broadcasting" ) NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_CONTAINER_MINIGAME_DATA_CHANGE( INT iObj, INT iPart, BOOL bTarget, BOOL bInvestigationFinished = FALSE, BOOL bInvestigationInterrupted = FALSE, BOOL bShowCollectable = FALSE)
	SCRIPT_EVENT_DATA_CONTAINER_INVESTIGATED Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_INVESTIGATE_CONTAINER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iObj = iObj
	Event.iPart = iPart
	Event.bTarget = bTarget
	Event.bInvestigationFinished = bInvestigationFinished
	Event.bInvestigationInterrupted = bInvestigationInterrupted
	Event.bShowCollectable = bShowCollectable

	NET_PRINT( "-----------------BROADCAST_CONTAINER_MINIGAME_DATA_CHANGE---------------------------" ) NET_NL()
	NET_PRINT( "Event.iObj = " ) NET_PRINT_INT( Event.iObj ) NET_NL()
	NET_PRINT( "Event.iPart = " ) NET_PRINT_INT( Event.iPart ) NET_NL()
	NET_PRINT( "Event.bTarget = " ) NET_PRINT_BOOL( Event.bTarget ) NET_NL()
	NET_PRINT( "Event.bInvestigationFinished = " )  NET_PRINT_BOOL( Event.bInvestigationFinished ) NET_NL()
	NET_PRINT( "Event.bInvestigationInterrupted = " )  NET_PRINT_BOOL( Event.bInvestigationInterrupted ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF( iPlayerFlags <> 0 )
		SEND_TU_SCRIPT_EVENT( SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF( Event ), iPlayerFlags )	
	ELSE
		NET_PRINT( "BROADCAST_CONTAINER_MINIGAME_DATA_CHANGE - playerflags = 0 so not broadcasting" ) NET_NL()		
	ENDIF
ENDPROC


PROC BROADCAST_BINBAG_REQUEST( INT iObj, INT iPart, BOOL bPuttingDown )

	SCRIPT_EVENT_DATA_BINBAG_REQUEST Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_REQUEST_BINBAG
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iObj = iObj
	Event.iPart = iPart
	Event.bPuttingDown = bPuttingDown

	NET_PRINT( "-----------------BROADCAST_BINBAG_REQUEST---------------------------" ) NET_NL()
	NET_PRINT( "Event.iObj = " ) NET_PRINT_INT( Event.iObj ) NET_NL()
	NET_PRINT( "Event.iPart = " ) NET_PRINT_INT( Event.iPart ) NET_NL()
	NET_PRINT( "Event.bPuttingDown = " ) NET_PRINT_BOOL( Event.bPuttingDown ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF( iPlayerFlags <> 0 )
		SEND_TU_SCRIPT_EVENT( SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF( Event ), iPlayerFlags )	
	ELSE
		NET_PRINT( "BROADCAST_BINBAG_REQUEST - playerflags = 0 so not broadcasting" ) NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_BINBAG_OWNER_CHANGED( INT iObj, INT iPart )

	SCRIPT_EVENT_DATA_BINBAG_REQUEST Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_BINBAG_OWNER_CHANGED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iObj = iObj
	Event.iPart = iPart
	Event.bPuttingDown = FALSE

	NET_PRINT( "-----------------BROADCAST_BINBAG_OWNER_CHANGED---------------------------" ) NET_NL()
	NET_PRINT( "Event.iObj = " ) NET_PRINT_INT( Event.iObj ) NET_NL()
	NET_PRINT( "Event.iPart = " ) NET_PRINT_INT( Event.iPart ) NET_NL()
	NET_PRINT( "Event.bPuttingDown = " ) NET_PRINT_BOOL( Event.bPuttingDown ) NET_NL()
	DEBUG_PRINTCALLSTACK()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF( iPlayerFlags <> 0 )
		SEND_TU_SCRIPT_EVENT( SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF( Event ), iPlayerFlags )	
	ELSE
		NET_PRINT( "BROADCAST_BINBAG_OWNER_CHANGED - playerflags = 0 so not broadcasting" ) NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_TRASH_DRIVE_ENABLE( INT iVeh, INT iPart, BOOL bEnable )
	
	SCRIPT_EVENT_DATA_TRASH_DRIVE_ENABLE Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_TRASH_DRIVE_ENABLE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iVeh = iVeh
	Event.iPart = iPart
	Event.bEnable = bEnable

	NET_PRINT( "-----------------BROADCAST_TRASH_DRIVE_ENABLE---------------------------" ) NET_NL()
	NET_PRINT( "Event.iVeh = " ) NET_PRINT_INT( Event.iVeh ) NET_NL()
	NET_PRINT( "Event.iPart = " ) NET_PRINT_INT( Event.iPart ) NET_NL()
	NET_PRINT( "Event.bEnable = " ) NET_PRINT_BOOL( Event.bEnable ) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF( iPlayerFlags <> 0 )
		SEND_TU_SCRIPT_EVENT( SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF( Event ), iPlayerFlags )	
	ELSE
		NET_PRINT( "BROADCAST_TRASH_DRIVE_ENABLE - playerflags = 0 so not broadcasting" ) NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_INCREMENT_TEAM_SCORE_RESURRECTION
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INT iTeam0Score
	INT iTeam1Score
ENDSTRUCT

PROC BROADCAST_FMMC_INCREMENT_TEAM_SCORE_RESURRECTION(INT iTeam, INT iTeam0Score, INT iTeam1Score)
	
	SCRIPT_EVENT_DATA_FMMC_INCREMENT_TEAM_SCORE_RESURRECTION Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_INCREMENT_TEAM_SCORE_RESURRECTION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	Event.iTeam0Score = iTeam0Score
	Event.iTeam1Score = iTeam1Score
	
	NET_PRINT("-----------------BROADCAST_FMMC_INCREMENT_TEAM_SCORE_RESURRECTION---------------------------") NET_NL()
	NET_PRINT("Event.iTeam = ") NET_PRINT_INT(Event.iTeam) NET_NL()
	NET_PRINT("Event.iTeam0Score = ") NET_PRINT_INT(Event.iTeam0Score) NET_NL()
	NET_PRINT("Event.iTeam1Score = ") NET_PRINT_INT(Event.iTeam1Score) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_INCREMENT_TEAM_SCORE_RESURRECTION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_CUSTOM_OBJECT_PICKUP_SHARD
	
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX ObjPlayer
	INT iShardIndex
	INT iTeam
	
ENDSTRUCT

PROC BROADCAST_FMMC_DISPLAY_CUSTOM_OBJECT_PICKUP_SHARD(PLAYER_INDEX ObjPlayer, INT iShardIndex, INT iTeam)
	
	SCRIPT_EVENT_DATA_FMMC_CUSTOM_OBJECT_PICKUP_SHARD Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_DISPLAY_CUSTOM_OBJECT_PICKUP_SHARD
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iShardIndex = iShardIndex
	Event.ObjPlayer = ObjPlayer
	Event.iTeam = iTeam
	
	NET_PRINT("-----------------BROADCAST_FMMC_DISPLAY_CUSTOM_OBJECT_PICKUP_SHARD---------------------------") NET_NL()
	NET_PRINT("Event.ObjPlayer = ") NET_PRINT(GET_PLAYER_NAME(Event.ObjPlayer)) NET_NL()
	NET_PRINT("Event.iShardIndex = ") NET_PRINT_INT(Event.iShardIndex) NET_NL()
	NET_PRINT("Event.iTeam = ") NET_PRINT_INT(Event.iTeam) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_DISPLAY_CUSTOM_OBJECT_PICKUP_SHARD - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_EXIT_MISSION_MOC
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_FMMC_EXIT_MISSION_MOC()
	SCRIPT_EVENT_DATA_FMMC_EXIT_MISSION_MOC Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_EXIT_MISSION_MOC
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	NET_PRINT("-----------------BROADCAST_FMMC_EXIT_MISSION_MOC---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_EXIT_MISSION_MOC - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_STOLEN_FLAG_SHARD
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX PlayerThatStole
	INT iTeamThatStole
	INT iTeamStolenFrom
	INT iObjectIndex
	INT iPreviousOwner
ENDSTRUCT

PROC BROADCAST_FMMC_STOLEN_FLAG_SHARD(PLAYER_INDEX StealingPlayer, INT iTeamThatStole, INT iTeamStolenFrom, INT iObjectIndex, INT iPreviousOwner)
	SCRIPT_EVENT_DATA_FMMC_STOLEN_FLAG_SHARD Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_STOLEN_FLAG_SHARD
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.PlayerThatStole = StealingPlayer
	Event.iTeamThatStole = iTeamThatStole
	Event.iTeamStolenFrom = iTeamStolenFrom
	Event.iObjectIndex = iObjectIndex
	Event.iPreviousOwner = iPreviousOwner
	
	NET_PRINT("-----------------BROADCAST_FMMC_STOLEN_FLAG_SHARD---------------------------") NET_NL()
	NET_PRINT("Event.PlayerThatStole = ") NET_PRINT_INT(NATIVE_TO_INT(Event.PlayerThatStole)) NET_NL()
	NET_PRINT("Event.iTeamThatStole = ") NET_PRINT_INT(Event.iTeamThatStole) NET_NL()
	NET_PRINT("Event.iTeamStolenFrom = ") NET_PRINT_INT(Event.iTeamStolenFrom) NET_NL()
	NET_PRINT("Event.iObjectIndex = ") NET_PRINT_INT(Event.iObjectIndex) NET_NL()
	NET_PRINT("Event.iPreviousOwner = ") NET_PRINT_INT(Event.iPreviousOwner) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_STOLEN_FLAG_SHARD - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_CAPTURED_FLAG_SHARD
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeamThatCaptured
ENDSTRUCT
PROC BROADCAST_FMMC_CAPTURED_FLAG_SHARD(INT iTeamThatCaptured)
	SCRIPT_EVENT_DATA_FMMC_CAPTURED_FLAG_SHARD Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_CAPTURED_FLAG_SHARD
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeamThatCaptured = iTeamThatCaptured
	
	NET_PRINT("-----------------BROADCAST_FMMC_CAPTURED_FLAG_SHARD---------------------------") NET_NL()
	NET_PRINT("Event.iTeamThatCaptured = ") NET_PRINT_INT(Event.iTeamThatCaptured) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_CAPTURED_FLAG_SHARD - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_RETURNED_FLAG_SHARD
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeamThatReturned
	PLAYER_INDEX piPlayerThatReturned
	BOOL bUseShuntTitle
ENDSTRUCT
PROC BROADCAST_FMMC_RETURNED_FLAG_SHARD(INT iTeamThatReturned, PLAYER_INDEX piPlayerThatReturned, BOOL bUseShuntTitle = FALSE)
	SCRIPT_EVENT_DATA_FMMC_RETURNED_FLAG_SHARD Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_RETURNED_FLAG_SHARD
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeamThatReturned = iTeamThatReturned
	Event.piPlayerThatReturned = piPlayerThatReturned
	Event.bUseShuntTitle = bUseShuntTitle
	
	NET_PRINT("-----------------BROADCAST_FMMC_RETURNED_FLAG_SHARD---------------------------") NET_NL()
	NET_PRINT("Event.iTeamThatCaptured = ") NET_PRINT_INT(Event.iTeamThatReturned) NET_NL()
	NET_PRINT("Event.piPlayerThatReturned = ") NET_PRINT_INT(NATIVE_TO_INT(Event.piPlayerThatReturned)) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_RETURNED_FLAG_SHARD - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_CCTV_SPOTTED
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX PlayerSpotted
	INT iCam
ENDSTRUCT

PROC BROADCAST_FMMC_CCTV_SPOTTED(PLAYER_INDEX PlayerSpotted, INT iCam = -1)
	SCRIPT_EVENT_DATA_FMMC_CCTV_SPOTTED Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_CCTV_SPOTTED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.PlayerSpotted = PlayerSpotted
	Event.iCam = iCam
	
	NET_PRINT("-----------------BROADCAST_FMMC_CCTV_SPOTTED---------------------------") NET_NL()
	NET_PRINT("Event.PlayerSpotted = ") NET_PRINT_INT(NATIVE_TO_INT(Event.PlayerSpotted)) NET_NL()
	NET_PRINT("Event.iCam = ") NET_PRINT_INT(Event.iCam) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_CCTV_SPOTTED - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_TAGGED_ENTITY
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTaggedIndex
	INT iTaggedEntityType
	INT iTaggedEntityIndex
	INT iTaggedGangChaseUnit
ENDSTRUCT

PROC BROADCAST_FMMC_TAGGED_ENTITY(INT iTaggedIndex, INT iTaggedEntityType, INT iTaggedEntityIndex, INT iTaggedGangChaseUnit = -1)
	SCRIPT_EVENT_DATA_FMMC_TAGGED_ENTITY Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_TAGGED_ENTITY
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTaggedIndex = iTaggedIndex
	Event.iTaggedEntityType = iTaggedEntityType
	Event.iTaggedEntityIndex = iTaggedEntityIndex
	Event.iTaggedGangChaseUnit = iTaggedGangChaseUnit
	
	NET_PRINT("-----------------BROADCAST_FMMC_STAGGED_ENTITY---------------------------") NET_NL()
	NET_PRINT("Event.iTaggedIndex = ") NET_PRINT_INT(Event.iTaggedIndex) NET_NL()
	NET_PRINT("Event.iTaggedEntityType = ") NET_PRINT_INT(Event.iTaggedEntityType) NET_NL()
	NET_PRINT("Event.iTaggedEntityIndex = ") NET_PRINT_INT(Event.iTaggedEntityIndex) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_STAGGED_ENTITY - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_STOCKPILE_SOUND
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iStockpileSoundEventType
	INT iPart
ENDSTRUCT

PROC BROADCAST_FMMC_STOCKPILE_SOUND(INT iStockpileSoundType, INT iPart)
	SCRIPT_EVENT_DATA_FMMC_STOCKPILE_SOUND Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_STOCKPILE_SOUND
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iStockpileSoundEventType = iStockpileSoundType
	
	Event.iPart = iPart
	
	NET_PRINT("-----------------BROADCAST_FMMC_STOCKPILE_SOUND---------------------------") NET_NL()
	NET_PRINT("Event.Details.FromPlayerIndex = ") NET_PRINT_INT(NATIVE_TO_INT(Event.Details.FromPlayerIndex)) NET_NL()
	NET_PRINT("Event.iStockpileSoundEventType = ") NET_PRINT_INT(Event.iStockpileSoundEventType) NET_NL()
	NET_PRINT("Event.iPart = ") NET_PRINT_INT(Event.iPart) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_STOCKPILE_SOUND - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_LOCATE_CAPTURE_PLAYER_SCORE
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX PlayerThatOwnsLocate
	INT iPlayersTeam
	INT iLocateIndex
	INT iFrameCount
ENDSTRUCT

PROC BROADCAST_FMMC_LOCATE_CAPTURE_PLAYER_SCORE(PLAYER_INDEX PlayerThatOwnsLocate, INT iPlayersTeam, INT iLocateIndex, INT iFrameCount)
	SCRIPT_EVENT_DATA_FMMC_LOCATE_CAPTURE_PLAYER_SCORE Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_LOCATE_CAPTURE_PLAYER_SCORE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.PlayerThatOwnsLocate = PlayerThatOwnsLocate
	Event.iPlayersTeam = iPlayersTeam
	Event.iLocateIndex = iLocateIndex
	Event.iFrameCount = iFrameCount
	
	NET_PRINT("-----------------BROADCAST_FMMC_LOCATE_CAPTURE_PLAYER_SCORE---------------------------") NET_NL()
	NET_PRINT("Event.PlayerThatOwnsLocate = ") NET_PRINT_INT(NATIVE_TO_INT(Event.PlayerThatOwnsLocate)) NET_NL()
	NET_PRINT("Event.iPlayersTeam = ") NET_PRINT_INT(Event.iPlayersTeam) NET_NL()
	NET_PRINT("Event.iLocateIndex = ") NET_PRINT_INT(Event.iLocateIndex) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_FMMC_LOCATE_CAPTURE_PLAYER_SCORE - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PLAYER_SCORE
	
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX PlayerToIncrease
	INT iamount
	INT iServerKey
	INt iFrameCount

ENDSTRUCT

PROC BROADCAST_FMMC_INCREASE_REMOTE_PLAYER_SCORE(PLAYER_INDEX PlayerToIncrease, INT iamount, INT iServerKey, INT iFrameCount)
	
	SCRIPT_EVENT_DATA_FMMC_PLAYER_SCORE Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_PLAYER_SCORE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.PlayerToIncrease = PlayerToIncrease
	Event.iamount = iamount
	Event.iServerKey = iServerKey
	Event.iFrameCount = iFrameCount
	
	NET_PRINT("-----------------BROADCAST_FMMC_INCREASE_REMOTE_PLAYER_SCORE---------------------------") NET_NL()
	NET_PRINT("Event.PlayerToIncrease = ") NET_PRINT_INT(NATIVE_TO_INT(Event.PlayerToIncrease)) NET_NL()
	NET_PRINT("Event.iamount = ") NET_PRINT_INT(Event.iamount) NET_NL()
	
	INT iPlayerFlags = SPECIFIC_PLAYER(Event.PlayerToIncrease) // player whos score we want to increase
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_INCREASE_REMOTE_PLAYER_SCORE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_RUMBLE_TEAM_SCORES_SHARD
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iScores[FMMC_MAX_TEAMS]
ENDSTRUCT

PROC BROADCAST_FMMC_RUMBLE_TEAM_SCORES_SHARD(INT &iScores[])
	
	SCRIPT_EVENT_DATA_FMMC_RUMBLE_TEAM_SCORES_SHARD Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_RUMBLE_TEAM_SCORES_SHARD
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT i = 0
	FOR i = 0 TO FMMC_MAX_TEAMS-1
		Event.iScores[i] = iScores[i]
	ENDFOR
	
	NET_PRINT("-----------------BROADCAST_FMMC_RUMBLE_TEAM_SCORES_SHARD---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to all players!
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_RUMBLE_TEAM_SCORES_SHARD - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_OVERTIME_SCORED_SHARD
	STRUCT_EVENT_COMMON_DETAILS Details
	
	INT iTeam
	INT iPriority
	INT iScore
	BOOL bPlayOvertimeShard
	BOOL bPlayOvertimeRumbleShard
	INT iPartToMove
	INT iCurrentRound
ENDSTRUCT

PROC BROADCAST_FMMC_OVERTIME_SCORED_SHARD(INT iTeam, INT iPriority, INT iScore, INT iPartToMove, int iCurrentRound, BOOL bPlayOvertimeShard = FALSE, BOOL bPlayOvertimeRumbleShard = FALSE)

	SCRIPT_EVENT_DATA_FMMC_OVERTIME_SCORED_SHARD Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_OVERTIME_SCORED_SHARD
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	Event.iPriority = iPriority
	Event.iScore = iScore
	Event.bPlayOvertimeShard = bPlayOvertimeShard
	Event.bPlayOvertimeRumbleShard = bPlayOvertimeRumbleShard
	Event.iPartToMove = iPartToMove
	Event.iCurrentRound = iCurrentRound
	
	NET_PRINT("-----------------BROADCAST_FMMC_OVERTIME_SCORED_SHARD---------------------------") NET_NL()
	NET_PRINT("Event.iTeam = ") NET_PRINT_INT(Event.iTeam) NET_NL()
	NET_PRINT("Event.iPriority = ") NET_PRINT_INT(Event.iPriority) NET_NL()
	NET_PRINT("Event.iScore = ") NET_PRINT_INT(Event.iScore) NET_NL()
	NET_PRINT("Event.bPlayOvertimeShard = ") NET_PRINT_BOOL(Event.bPlayOvertimeShard) NET_NL()
	NET_PRINT("Event.bPlayOvertimeRumbleShard = ") NET_PRINT_BOOL(Event.bPlayOvertimeRumbleShard) NET_NL()
	NET_PRINT("Event.iPartToMove = ") NET_PRINT_INT(Event.iPartToMove) NET_NL()
		
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OVERTIME_SCORED_SHARD - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_OVERTIME_PAUSE_RENDERPHASE	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventSessionKey
	BOOL bHidePlayer
	BOOL bInstant
ENDSTRUCT

PROC BROADCAST_FMMC_OVERTIME_PAUSE_RENDERPHASE(INT iSessionKey, BOOL bHidePlayer = FALSE, BOOL bInstant = FALSE)

	SCRIPT_EVENT_DATA_FMMC_OVERTIME_PAUSE_RENDERPHASE Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_OVERTIME_PAUSE_RENDERPHASE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iEventSessionKey = iSessionKey	
	Event.bHidePlayer = bHidePlayer
	Event.bInstant = bInstant
	
	NET_PRINT("-----------------BROADCAST_FMMC_OVERTIME_PAUSE_RENDERPHASE---------------------------") NET_NL()
		
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OVERTIME_PAUSE_RENDERPHASE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC
STRUCT SCRIPT_EVENT_DATA_FMMC_INCREMENTED_LOCAL_PLAYER_SCORE
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INT iPriority
	INT iScore
	INT iVictimPart //to stop events getting dropped as dupes
	INT iIdentifier
ENDSTRUCT

PROC BROADCAST_FMMC_INCREMENTED_LOCAL_PLAYER_SCORE(INT iTeam, INT iPriority, INT iScore, INT iVictimPart = -1, INT iIdentifier = -1)
	
	SCRIPT_EVENT_DATA_FMMC_INCREMENTED_LOCAL_PLAYER_SCORE Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_INCREMENTED_LOCAL_PLAYER_SCORE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	Event.iPriority = iPriority
	Event.iScore = iScore
	Event.iVictimPart = iVictimPart
	Event.iIdentifier = iIdentifier
	
	NET_PRINT("-----------------BROADCAST_INCREMENTED_LOCAL_PLAYER_SCORE---------------------------") NET_NL()
	NET_PRINT("Event.iTeam = ") NET_PRINT_INT(Event.iTeam) NET_NL()
	NET_PRINT("Event.iPriority = ") NET_PRINT_INT(Event.iPriority) NET_NL()
	NET_PRINT("Event.iScore = ") NET_PRINT_INT(Event.iScore) NET_NL()
	NET_PRINT("Event.iIdentifier = ") NET_PRINT_INT(Event.iIdentifier) NET_NL()	
		
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_INCREMENTED_LOCAL_PLAYER_SCORE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_OBJECTIVE_REVALIDATE
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	INT iLocResetBS
	
ENDSTRUCT

PROC BROADCAST_FMMC_OBJECTIVE_REVALIDATE(INT iTeam, INT iLocResetBS)
	
	SCRIPT_EVENT_DATA_FMMC_OBJECTIVE_REVALIDATE Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_OBJECTIVE_REVALIDATE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTeam = iTeam
	Event.iLocResetBS = iLocResetBS
	
	NET_PRINT("-----------------BROADCAST_FMMC_OBJECTIVE_REVALIDATE---------------------------") NET_NL()
	NET_PRINT("Event.iTeam = ") NET_PRINT_INT(Event.iTeam) NET_NL()
	NET_PRINT("Event.iLocResetBS = ") NET_PRINT_INT(Event.iLocResetBS) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // send it to everyone!
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_OBJECTIVE_REVALIDATE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_DIALOGUE_LOOK
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iped
	
ENDSTRUCT


PROC BROADCAST_DIALOGUE_TRIGGER_LOOK_EVENT(INT iPed)
	
	SCRIPT_EVENT_DATA_FMMC_DIALOGUE_LOOK Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_DIALOGUE_LOOK
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iped = iped
	
	NET_PRINT("-----------------BROADCAST_DIALOGUE_TRIGGER_LOOK_EVENT---------------------------") NET_NL()
	NET_PRINT("Event.iped = ") NET_PRINT_INT(Event.iped) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DIALOGUE_TRIGGER_LOOK_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PED_RETASK_HANDSHAKE_EVENT
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iped
	
ENDSTRUCT


PROC BROADCAST_FMMC_PED_RETASK_HANDSHAKE_EVENT(INT iPed)
	
	SCRIPT_EVENT_DATA_FMMC_PED_RETASK_HANDSHAKE_EVENT Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_PED_RETASK_HANDSHAKE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iped = iped
	
	NET_PRINT("-----------------BROADCAST_FMMC_PED_RETASK_HANDSHAKE_EVENT---------------------------") NET_NL()
	NET_PRINT("Event.iped = ") NET_PRINT_INT(Event.iped) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_PED_RETASK_HANDSHAKE_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_START_SYNC_LOCK_HACK_TIMER
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iteam
	
ENDSTRUCT


PROC BROADCAST_FMMC_START_SYNC_LOCK_HACK_TIMER(INT iteam)
	
	SCRIPT_EVENT_DATA_FMMC_START_SYNC_LOCK_HACK_TIMER Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_START_SYNC_LOCK_HACK_TIMER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iteam = iteam
	NET_PRINT("-----------------BROADCAST_FMMC_START_SYNC_LOCK_HACK_TIMER---------------------------") NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS() 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_START_SYNC_LOCK_HACK_TIMER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

STRUCT EVENT_STRUCT_BIOLAB_LIFT_WARP_EVENT
	STRUCT_EVENT_COMMON_DETAILS 	Details
ENDSTRUCT

PROC BROADCAST_BIOLAB_LIFT_WARP_EVENT(BOOL bInLower)
	
	EVENT_STRUCT_BIOLAB_LIFT_WARP_EVENT Event
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	IF bInLower
		Event.Details.Type = SCRIPT_EVENT_FMMC_LOWER_LIFT_WARP
	ELSE
		Event.Details.Type = SCRIPT_EVENT_FMMC_UPPER_LIFT_WARP
	ENDIF
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[RCC MISSION]  BROADCAST_BIOLAB_LIFT_WARP_EVENT - called...")
		PRINTLN("[RCC MISSION]  From script: ", GET_THIS_SCRIPT_NAME())
		PRINTLN("[RCC MISSION]  bInLower: ", bInLower)
	#ENDIF

	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE))

ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_SAFETY_DEPOSIT_BOX_LOOTED
	STRUCT_EVENT_COMMON_DETAILS 	Details
	INT iBox
	INT iCabinet
	INT iPart
ENDSTRUCT

PROC BROADCAST_SCRIPT_EVENT_SAFETY_DEPOSIT_BOX_LOOTED(INT iBox, INT iCabinet, INT iPart)
	
	SCRIPT_EVENT_DATA_FMMC_SAFETY_DEPOSIT_BOX_LOOTED Event
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.Details.Type 	= SCRIPT_EVENT_FMMC_SAFETY_DEPOSIT_BOX_LOOTED
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[RCC MISSION]  BROADCAST_SCRIPT_EVENT_SAFETY_DEPOSIT_BOX_LOOTED - called...")
		PRINTLN("[RCC MISSION]  From script: ", GET_THIS_SCRIPT_NAME())
		PRINTLN("[RCC MISSION]  iBox: ", iBox)
		PRINTLN("[RCC MISSION]  iCabinet: ", iCabinet)
		PRINTLN("[RCC MISSION]  iPart: ", iPart)
	#ENDIF
	
	Event.iBox = iBox
	Event.iCabinet = iCabinet
	Event.iPart = iPart
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE))

ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_OCCUPY_SAFETY_DEPOSIT_BOX_CABINET
	STRUCT_EVENT_COMMON_DETAILS 	Details
	INT iCabinet
	INT iPart
	BOOL bUsing
ENDSTRUCT

PROC BROADCAST_SCRIPT_EVENT_OCCUPY_SAFETY_DEPOSIT_BOX_CABINET(INT iCabinet, INT iPart, BOOL bUsing)
	
	SCRIPT_EVENT_DATA_FMMC_OCCUPY_SAFETY_DEPOSIT_BOX_CABINET Event
	Event.Details.FromPlayerIndex = PLAYER_ID()	
	Event.Details.Type 	= SCRIPT_EVENT_FMMC_OCCUPY_SAFETY_DEPOSIT_BOX_CABINET
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[RCC MISSION]  BROADCAST_SCRIPT_EVENT_OCCUPY_SAFETY_DEPOSIT_BOX_CABINET - called...")
		PRINTLN("[RCC MISSION]  From script: ", GET_THIS_SCRIPT_NAME())
		PRINTLN("[RCC MISSION]  iCabinet: ", iCabinet)
		PRINTLN("[RCC MISSION]  iPart: ", iPart)
		PRINTLN("[RCC MISSION]  bUsing: ", bUsing)
	#ENDIF
	
	Event.iCabinet = iCabinet
	Event.iPart = iPart
	Event.bUsing = bUsing
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE))

ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_PAINTING_STOLEN
	STRUCT_EVENT_COMMON_DETAILS 	Details
	INT iPainting
	INT iPart
ENDSTRUCT

PROC BROADCAST_SCRIPT_EVENT_PAINTING_STOLEN(INT iPainting, INT iPart)
	
	SCRIPT_EVENT_DATA_FMMC_PAINTING_STOLEN Event
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.Details.Type 	= SCRIPT_EVENT_FMMC_PAINTING_STOLEN
	PRINTLN("[ML Painting take] Broadcast has been called")
	#IF IS_DEBUG_BUILD
		PRINTLN("[RCC MISSION]  BROADCAST_SCRIPT_EVENT_PAINTING_STOLEN - called...")
		PRINTLN("[RCC MISSION]  From script: ", GET_THIS_SCRIPT_NAME())
		PRINTLN("[RCC MISSION]  iPainting: ", iPainting)
		PRINTLN("[RCC MISSION]  iPart: ", iPart)
	#ENDIF
	
	Event.iPainting = iPainting
	Event.iPart = iPart
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE))

ENDPROC

PROC BROADCAST_SCRIPT_EVENT_GRAB_CASH(INT iObj, INT iCashGrabbed, INT iCurrentPile, BOOL bIsBonusCash, BOOL bFinalCashPile, BOOL bDailyCashVault = FALSE)
	
	SCRIPT_EVENT_DATA_FMMC_CASH_GRAB Event
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.Details.Type 	= SCRIPT_EVENT_FMMC_GRAB_CASH
	Event.iobjIndex 	= iObj
	Event.iCashGrabbed 	= iCashGrabbed
	Event.iCurrentPile 	= iCurrentPile
	Event.bIsBonusCash 	= bIsBonusCash
	Event.bFinalCashPile= bFinalCashPile
	Event.bDailyCashVault = bDailyCashVault
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[RCC MISSION]  BROADCAST_SCRIPT_EVENT_GRAB_CASH - called...")
		PRINTLN("[RCC MISSION]  From script: ", GET_THIS_SCRIPT_NAME())
		PRINTLN("[RCC MISSION]  iObj: ", iObj)
		PRINTLN("[RCC MISSION]  iCashGrabbed: ", iCashGrabbed)
		PRINTLN("[RCC MISSION]  iCurrentPile: ", iCurrentPile)
		PRINTLN("[RCC MISSION]  bIsBonusCash: ", bIsBonusCash)
		PRINTLN("[RCC MISSION]  bFinalCashPile: ", bFinalCashPile)
		PRINTLN("[RCC MISSION]  bDailyCashVault: ", bDailyCashVault)
	#ENDIF
	
	//set the global so thateach player know if they were involved in cash grab
	//needed for 2nd part of the ornate bank heist, as non global vars get reset when script terminates
	g_TransitionSessionNonResetVars.bInvolvedInCashGrab = TRUE

	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE))

ENDPROC

PROC BROADCAST_SCRIPT_EVENT_GRAB_CASH_CASH_DROPPED(FLOAT fScale, BOOL bHitInTheBag = FALSE)
	
	SCRIPT_EVENT_DATA_FMMC_CASH_GRAB_CASH_DROPPED Event
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.Details.Type 	= SCRIPT_EVENT_FMMC_GRAB_CASH_DROP_CASH
	Event.fScale		= fScale
	Event.bHitInTheBag	= bHitInTheBag
	Event.iDropTime		= GET_GAME_TIMER()
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[RCC MISSION]  BROADCAST_SCRIPT_EVENT_GRAB_CASH_CASH_DROPPED - called...")
		PRINTLN("[RCC MISSION]  From script: ", GET_THIS_SCRIPT_NAME())
		PRINTLN("[RCC MISSION]  fScale: ", Event.fScale)
		PRINTLN("[RCC MISSION]  iDropTime: ", Event.iDropTime)
		PRINTLN("[RCC MISSION]  bHitInTheBag: ", Event.bHitInTheBag)
	#ENDIF

	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE))

ENDPROC

PROC BROADCAST_SCRIPT_EVENT_GRAB_CASH_DISPLAY_TAKE()
	
	SCRIPT_EVENT_DATA_FMMC_JUST_EVENT Event
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_GRAB_CASH_DISPLAY_TAKE
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[RCC MISSION]  BROADCAST_SCRIPT_EVENT_GRAB_CASH_DISPLAY_TAKE - called...")
		PRINTLN("[RCC MISSION]  From script: ", GET_THIS_SCRIPT_NAME())
	#ENDIF

	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE))

ENDPROC

PROC BROADCAST_SCRIPT_EVENT_TREVOR_COVER_CONVERSATION_TRIGGERED(INT iConversationToPlay, INT iRandomAnimation, INT iPed)
	
	SCRIPT_EVENT_DATA_FMMC_TREVOR_COVER_CONVERSATION_TRIGGERED Event
	
	Event.Details.FromPlayerIndex   = PLAYER_ID()
	Event.Details.Type				= SCRIPT_EVENT_FMMC_TREVOR_COVER_CONVERSATION_TRIGGERED
	Event.iPed						= iPed
	Event.iRandomAnimation			= iRandomAnimation
	Event.iConversationToPlay		= iConversationToPlay
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[RCC MISSION]  BROADCAST_SCRIPT_EVENT_TREVOR_COVER_CONVERSATION_TRIGGERED - called...")
		PRINTLN("[RCC MISSION]  From script: ", GET_THIS_SCRIPT_NAME())
	#ENDIF

	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE))
	
ENDPROC

PROC BROADCAST_SCRIPT_EVENT_SWAP_DOOR_FOR_DAMAGED_VERSION(INT iRule)
	
	SCRIPT_EVENT_DATA_FMMC_SWAP_DOOR_FOR_DAMAGED_VERSION Event
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.Details.Type = SCRIPT_EVENT_FMMC_SWAP_DOOR_FOR_DAMAGED_VERSION
	Event.iRule = iRule
	
	#IF IS_DEBUG_BUILD
		PRINTLN("[RCC MISSION]  BROADCAST_SCRIPT_EVENT_SWAP_DOOR_FOR_DAMAGED_VERSION - called...")
		PRINTLN("[RCC MISSION]  From script: ", GET_THIS_SCRIPT_NAME())
		PRINTLN("[RCC MISSION]  iRule: ", iRule)
	#ENDIF

	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE))

ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_CUTSCENE_VEH
	
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iVehNetID
	INT iCSNumVeh

ENDSTRUCT


PROC BROADCAST_FMMC_DELIVERED_CUTSCENE_VEH(INT iVehNetID,INT iCSNumVeh)
	
	SCRIPT_EVENT_DATA_FMMC_CUTSCENE_VEH Event

	Event.Details.Type = SCRIPT_EVENT_FMMC_DELIVER_CUTSCENE_VEH
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iVehNetID = iVehNetID
	Event.iCSNumVeh = iCSNumVeh
	
	NET_PRINT("-----------------BROADCAST_FMMC_DELIVERED_CUTSCENE_VEH---------------------------") NET_NL()
	NET_PRINT("Event.iVehNetID  = ") NET_PRINT_INT(iVehNetID) NET_NL()
	NET_PRINT("Event.iCSNumVeh  = ") NET_PRINT_INT(iCSNumVeh) NET_NL()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FMMC_DELIVERED_CUTSCENE_VEH - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_TERRITORY_CASH
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCashteam
	INT iplayerteam
ENDSTRUCT

PROC BROADCAST_TERRITORY_CASH_PICKUP(INT iCashteam,INT iplayerteam)
	SCRIPT_EVENT_DATA_TERRITORY_CASH Event

	Event.Details.Type = SCRIPT_EVENT_TERRITORY_CASH
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iCashteam = iCashteam
	Event.iplayerteam = iplayerteam
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PROPERTY_TAKEOVER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

PROC BROADCAST_FMMC_PRI_STA_IG2_AUDIOSTREAM( INT iPed )
	SCRIPT_EVENT_DATA_FMMC_PED_ID Event
	
	Event.Details.Type = SCRIPT_EVENT_FMMC_PRI_STA_IG2_AUDIOSTREAM
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPedid = iPed
	
	INT iPlayerFlags = ALL_PLAYERS(FALSE)
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
		PRINTLN("BROADCAST_FMMC_PRI_STA_IG2_AUDIOSTREAM - broadcasting ped = ", iPed, " to play audio stream") NET_NL()		
	ELSE
		NET_PRINT("BROADCAST_FMMC_PRI_STA_IG2_AUDIOSTREAM - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC



STRUCT SCRIPT_EVENT_DATA_TERRITORY_KILL

	STRUCT_EVENT_COMMON_DETAILS Details
	INT iProperty
	INT iTeam
	INT ikills
	
ENDSTRUCT

PROC BROADCAST_TERRITORY_KILL(INT iProperty,INT iTeam,INT ikills)

	SCRIPT_EVENT_DATA_TERRITORY_KILL Event

	Event.Details.Type = SCRIPT_EVENT_TERRITORY_KILL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iProperty = iProperty
	Event.iTeam = iTeam
	Event.ikills = ikills
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PROPERTY_KILL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

#IF IS_DEBUG_BUILD
STRUCT SCRIPT_EVENT_DATA_PROPERTY_TAKEOVER
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iProperty
	INT iTeam
	INT iOldOwner

ENDSTRUCT


PROC BROADCAST_PROPERTY_TAKEOVER(INT iProperty,INT iTeam,INT iOldOwner)
	SCRIPT_EVENT_DATA_PROPERTY_TAKEOVER Event

	Event.Details.Type = SCRIPT_EVENT_PROPERTY_TAKEOVER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iProperty = iProperty
	Event.iTeam = iTeam
	Event.iOldOwner = iOldOwner

		
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PROPERTY_TAKEOVER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_SET_TEAM_TARGET_TERRITORY
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTerritory
	INT iteam
ENDSTRUCT

PROC BROADCAST_TEAM_TARGET_TERRITORY(INT iTerritory,INT iteam)
	SCRIPT_EVENT_DATA_SET_TEAM_TARGET_TERRITORY Event

	Event.Details.Type = SCRIPT_EVENT_SET_TEAM_TARGET_TERRITORY
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTerritory = iTerritory
	Event.iTeam = iteam
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_COP_TARGET_TERRITORY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC
#ENDIF


STRUCT SCRIPT_EVENT_DATA_ALTER_NON_LOCAL_PLAYER_STAT
	STRUCT_EVENT_COMMON_DETAILS Details
	//BOOL b_ALTER_NON_LOCAL_PLAYER_STAT_active
	PLAYER_INDEX stat_change_non_local_player_index
	MP_INT_AWARD E_int_award  = MAX_NUM_MP_INT_AWARD
	MP_BOOL_AWARD E_bool_award = MAX_NUM_MP_BOOL_AWARD
	MP_FLOAT_AWARD E_float_award = MAX_NUM_MP_FLOAT_AWARD
	
	MP_INT_STATS E_int_stats = MAX_NUM_MP_INT_STATS
	MP_BOOL_STATS E_bool_stats= MAX_NUM_MP_BOOL_STATS
	MP_FLOAT_STATS E_float_stats = MAX_NUM_MP_FLOAT_STATS
	
	INT i_new_stat_value
	FLOAT f_new_stat_value
	BOOL b_new_stat_value
// may have to add all types of stats and award enums 
	
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_MEETING_ACTIVE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bmeetingactive

ENDSTRUCT

PROC BROADCAST_MEETING_ACTIVE(BOOL bmeetingactive)
	SCRIPT_EVENT_DATA_MEETING_ACTIVE Event

	Event.Details.Type = SCRIPT_EVENT_MEETING_ACTIVE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bmeetingactive = bmeetingactive
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // any player could be the host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_MEETING_ACTIVE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC


//Request to send a basic text to another player
STRUCT SCRIPT_EVENT_DATA_SEND_BASIC_TEXT
	STRUCT_EVENT_COMMON_DETAILS Details
	#IF IS_DEBUG_BUILD
	INT iDebugIdentifier
	#ENDIF
	TEXT_LABEL_23 textLabel
ENDSTRUCT
	
//Tell all my friends in the session that I want to play with them
PROC BROADCAST_SEND_BASIC_TEXT(INT iPlayerFlags,STRING textLabel)
	//Set up the event details
	SCRIPT_EVENT_DATA_SEND_BASIC_TEXT Event
	Event.Details.Type 				= SCRIPT_EVENT_SEND_BASIC_TEXT
	#IF IS_DEBUG_BUILD
	Event.iDebugIdentifier = GET_RANDOM_INT_IN_RANGE(0,99999999)
	#ENDIF
	Event.Details.FromPlayerIndex	= PLAYER_ID()
	Event.textLabel = textLabel
	PRINTLN("Player sending BROADCAST_SEND_BASIC_TEXT with ID: ", Event.iDebugIdentifier)
	//send it
	IF NOT (iPlayerFlags = 0)
		
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SEND_BASIC_TEXT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
ENDPROC

////Request to send a basic text to another player
//STRUCT SCRIPT_EVENT_DATA_UPDATE_PROPERTIES
//	STRUCT_EVENT_COMMON_DETAILS Details
//	#IF IS_DEBUG_BUILD
//	INT iDebugIdentifier
//	#ENDIF
//	INT iProperty1
//	INT iProperty2
//ENDSTRUCT
//	
////Tell all my friends in the session that I want to play with them
//PROC BROADCAST_UPDATE_PROPERTIES(INT iPlayerFlags,INT iProperty1, INT iProperty2)
//	//Set up the event details
//	SCRIPT_EVENT_DATA_UPDATE_PROPERTIES Event
//	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_PROPERTIES
//	#IF IS_DEBUG_BUILD
//	Event.iDebugIdentifier = GET_RANDOM_INT_IN_RANGE(0,99999999)
//	#ENDIF
//	Event.Details.FromPlayerIndex	= PLAYER_ID()
//	Event.iProperty1 = iProperty1
//	Event.iProperty2 = iProperty2
//	PRINTLN("Player sending BROADCAST_UPDATE_PROPERTIES with ID: ", Event.iDebugIdentifier)
//	//send it
//	IF NOT (iPlayerFlags = 0)
//		
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_UPDATE_PROPERTIES - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF		
//ENDPROC

//Request to play in freemode event data
STRUCT SCRIPT_EVENT_DATA_FREEMODE_MISSION_PLAY_REQUEST
	STRUCT_EVENT_COMMON_DETAILS Details
	#IF IS_DEBUG_BUILD
	INT iDebugIdentifier
	#ENDIF
	INT							iMissionType
	INT							iCreatorID 
	INT							iVariation
	VECTOR						vLocation
	TEXT_LABEL_23				sContentID
	INT							iPackedInt
ENDSTRUCT

//Broadcast event to invite players to activities in freemode
// KGM 15/6/14: Added iPackedInt so that the player accepting a same-session invite into a Heist Corona can setup the correct apartment details
//				NOTE: Not needed for cross-session invites which gets this info through transition variables
PROC BROADCAST_FREEMODE_INVITE_GENERAL(INT iPlayerFlags,INT iMissionType, INT iCreatorID, INT iVariation, VECTOR vLocation, TEXT_LABEL_23 sContentID)
	//Set up the event details
	SCRIPT_EVENT_DATA_FREEMODE_MISSION_PLAY_REQUEST Event
	#IF IS_DEBUG_BUILD
	Event.iDebugIdentifier = GET_RANDOM_INT_IN_RANGE(0,99999999)
	#ENDIF
	Event.Details.Type 				= SCRIPT_EVENT_FREEMODE_INVITE_GENERAL
	Event.Details.FromPlayerIndex	= PLAYER_ID()
	Event.iMissionType				= iMissionType
	Event.iCreatorID				= iCreatorID
	Event.iVariation				= iVariation
	Event.vLocation					= vLocation
	Event.sContentID				= sContentID
	// KGM: always pass the packedInt transition value - the joblist will only use this if the invite being accepted is heist-related
	Event.iPackedInt				= g_TransitionSessionNonResetVars.sTransVars.sInviteToPropertyDetails.iPackedInt
	
	#IF IS_DEBUG_BUILD
	INT i
	PRINTLN("Player sending BROADCAST_FREEMODE_INVITE_GENERAL with ID: ", Event.iDebugIdentifier)
	PRINTLN("BROADCAST_FREEMODE_INVITE_GENERAL Event.iMissionType: ", Event.iMissionType )
	PRINTLN("BROADCAST_FREEMODE_INVITE_GENERAL Event.iCreatorID: ", Event.iCreatorID )
	PRINTLN("BROADCAST_FREEMODE_INVITE_GENERAL Event.iVariation: ", Event.iVariation )
	PRINTLN("BROADCAST_FREEMODE_INVITE_GENERAL Event.vLocation: ", Event.vLocation )
	PRINTLN("BROADCAST_FREEMODE_INVITE_GENERAL Event.iPlayerFlags: ",iPlayerFlags)
	PRINTLN("BROADCAST_FREEMODE_INVITE_GENERAL Event.iPackedInt: ",Event.iPackedInt)
	REPEAT NUM_NETWORK_PLAYERS i
		IF IS_BIT_SET(iPlayerFlags,i)
			IF IS_NET_PLAYER_OK(INT_TO_PLAYERINDEX(i),FALSE)
				PRINTLN("BROADCAST_FREEMODE_INVITE_GENERAL sent to player ",GET_PLAYER_NAME(INT_TO_PLAYERINDEX(i)))
			ENDIF
		ENDIF
	ENDREPEAT
	#ENDIF
	//send it
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FREEMODE_INVITE_GENERAL- playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF			
ENDPROC


STRUCT SCRIPT_EVENT_DATA_TEAM_ARREST_DIE_WARP
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iteam
ENDSTRUCT

PROC BROADCAST_TEAM_ARREST_DIE_WARP(INT iteam = TEAM_INVALID)
	SCRIPT_EVENT_DATA_TEAM_ARREST_DIE_WARP Event

	Event.Details.Type = SCRIPT_EVENT_TEAM_ARREST_DIE_WARP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iteam = iteam
	
	INT iPlayerFlags = ALL_PLAYERS_IN_TEAM(GET_PLAYER_TEAM(PLAYER_ID()),TRUE)
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_TEAM_ARREST_DIE_WARP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF		
	
ENDPROC

#IF IS_DEBUG_BUILD
	STRUCT SCRIPT_EVENT_DATA_BLOCK_TERRITORY_UPLOAD
		STRUCT_EVENT_COMMON_DETAILS Details
		BOOL bblockupload
		INT iexceptionterritory
	ENDSTRUCT
	
	PROC BROADCAST_BLOCK_TERRITORY_UPLOAD_EVENT(BOOL bblockupload,INT iexceptionterritory)	

		SCRIPT_EVENT_DATA_BLOCK_TERRITORY_UPLOAD Event

		Event.Details.Type = SCRIPT_EVENT_BLOCK_TERRITORY_UPLOAD
		Event.Details.FromPlayerIndex = PLAYER_ID()
		Event.bblockupload = bblockupload
		Event.iexceptionterritory = iexceptionterritory
		
		IF bblockupload
			NET_PRINT("SCRIPT_EVENT_DATA_BLOCK_TERRITORY_UPLOAD - bblockupload = TRUE") NET_NL()	
		ELSE
			NET_PRINT("SCRIPT_EVENT_DATA_BLOCK_TERRITORY_UPLOAD - bblockupload = FALSE") NET_NL()	
		ENDIF
		NET_PRINT("SCRIPT_EVENT_DATA_BLOCK_TERRITORY_UPLOAD - iexceptionterritory: ") PRINTINT(iexceptionterritory) NET_NL()	
		
		INT iPlayerFlags = ALL_PLAYERS(TRUE)
		
		IF NOT (iPlayerFlags = 0)
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
		ELSE
			NET_PRINT("SCRIPT_EVENT_DATA_BLOCK_TERRITORY_UPLOAD - playerflags = 0 so not broadcasting") NET_NL()		
		ENDIF	
	
	ENDPROC
	
	STRUCT SCRIPT_EVENT_DATA_BUYING_DRUGS
		STRUCT_EVENT_COMMON_DETAILS Details 
		INT iDealerLocation
	ENDSTRUCT

	PROC BROADCAST_START_BUYING_DRUGS(INT iDealerLocation)
		
		NET_PRINT("BROADCAST_START_BUYING_DRUGS - called...") NET_NL()
		
		SCRIPT_EVENT_DATA_BUYING_DRUGS Event
		
		Event.Details.Type = SCRIPT_EVENT_START_BUYING_DRUGS
		Event.Details.FromPlayerIndex = PLAYER_ID()
		Event.iDealerLocation = iDealerLocation
		
		INT iPlayerFlags = ALL_PLAYERS(TRUE) // any player could be the host 
		IF NOT (iPlayerFlags = 0)
			
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
		ELSE
			NET_PRINT("BROADCAST_START_BUYING_DRUGS - playerflags = 0 so not broadcasting") NET_NL()		
		ENDIF		
		
	ENDPROC
	
	//╔═════════════════════════════════════════════════════════════════════════════╗
	//║							NOTIFY PLAYERS OF SNITCH KILLED																	
	//╚═════════════════════════════════════════════════════════════════════════════╝

	// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
	STRUCT SCRIPT_EVENT_DATA_SNITCH_KILLED
		STRUCT_EVENT_COMMON_DETAILS Details 
		PLAYER_INDEX snitchKiller
	ENDSTRUCT

	//PURPOSE: Broadcast for all player to let them know a snitch was killed
	PROC BROADCAST_SNITCH_KILLED(INT iPlayerFlags, PLAYER_INDEX theKiller)
		SCRIPT_EVENT_DATA_SNITCH_KILLED Event
		Event.Details.Type = SCRIPT_EVENT_SNITCH_KILLED
		Event.Details.FromPlayerIndex = PLAYER_ID()
		Event.snitchKiller = theKiller
		IF NOT (iPlayerFlags = 0)
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
		ELSE
			NET_PRINT("BROADCAST_SNITCH_KILLED - playerflags = 0 so not broadcasting") NET_NL()		
		ENDIF	
	ENDPROC
	
#ENDIF

STRUCT SCRIPT_EVENT_SPAWN_OCCLUSION_AREA_FOR_MISSION_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vCoords1
	VECTOR vCoords2
	FLOAT fFloat
	INT iShape
	MP_MISSION Mission
	INT iInstance
	BOOL bMakeActive
	BOOL bIsBox
ENDSTRUCT

PROC BROADCAST_SPAWN_OCCLUSION_AREA_FOR_THIS_MISSION(VECTOR vCoords1, VECTOR vCoords2, FLOAT fFloat, INT iShape, MP_MISSION MPMission, INT iMissionInstance, BOOL bActive)

	SCRIPT_EVENT_SPAWN_OCCLUSION_AREA_FOR_MISSION_DATA Event
	
	Event.Details.Type = SCRIPT_EVENT_SPAWN_OCCLUSION_AREA_FOR_MISSION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.vCoords1 = vCoords1
	Event.vCoords2 = vCoords2
	Event.fFloat = fFloat
	Event.iShape = iShape
	Event.Mission = MPMission
	Event.iInstance = iMissionInstance
	Event.bMakeActive = bActive

	INT iPlayerFlags = ALL_PLAYERS(TRUE) // any player could be the cnc host 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CHANGE_HEIST_CAR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	

ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║						Joinable Mission Event - NEW METHOD						║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_JOINABLE_MP_MISSION
	STRUCT_EVENT_COMMON_DETAILS Details 
	JOINABLE_MP_MISSION_DATA JoinableMission
ENDSTRUCT

//PURPOSE: broadcast a change to the joinable state of a mission
PROC BROADCAST_JOINABLE_MP_MISSION_EVENT(JOINABLE_MP_MISSION_DATA JoinEventData)
	SCRIPT_EVENT_DATA_JOINABLE_MP_MISSION Event
	Event.Details.Type = SCRIPT_EVENT_JOINABLE_SCRIPT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.JoinableMission = JoinEventData
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_JOINABLE_MP_MISSION_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║						Joined Mission Event - NEW METHOD						║
//╚═════════════════════════════════════════════════════════════════════════════╝

//// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
//STRUCT SCRIPT_EVENT_DATA_JOINED_MP_MISSION
//	STRUCT_EVENT_COMMON_DETAILS Details 
//	MP_MISSION Mission
//ENDSTRUCT
//
////PURPOSE: broadcast a change to the joinable state of a mission
//PROC BROADCAST_JOINED_MP_MISSION_EVENT(MP_MISSION MissionJoined)
//	SCRIPT_EVENT_DATA_JOINED_MP_MISSION Event
//	Event.Details.Type = SCRIPT_EVENT_JOINED_MISSION
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.Mission = MissionJoined
//	INT iPlayerFlags = ALL_PLAYERS_IN_TEAM(GET_PLAYER_TEAM(PLAYER_ID()), FALSE)
//	IF NOT (iPlayerFlags = 0)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_JOINED_MP_MISSION_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF	
//ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				Send an event to change a players code name						║
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_ASSIGN_PLAYER_A_NEW_CODE_NAME
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX PlayerID
	INT iCodeName
ENDSTRUCT

PROC BROADCAST_ASSIGN_PLAYER_A_NEW_CODE_NAME(PLAYER_INDEX PlayerID, INT iCodeName = 1)
	SCRIPT_EVENT_DATA_ASSIGN_PLAYER_A_NEW_CODE_NAME Event
	Event.Details.Type = SCRIPT_EVENT_ASSIGN_PLAYER_A_NEW_CODE_NAME
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.PlayerID = PlayerID
	Event.iCodeName = iCodeName
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SET_PLAYER_CODE_NAME - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				ONE ON ONE DM													║
//╚═════════════════════════════════════════════════════════════════════════════╝

FUNC BOOL IS_MODEL_VEH_DM_MODEL(MODEL_NAMES mnVehModel)
	SWITCH mnVehModel
		CASE LAZER
		CASE BUZZARD
		CASE RHINO
		CASE HYDRA
		CASE SAVAGE
			RETURN TRUE
		BREAK
	ENDSWITCH

	RETURN FALSE
ENDFUNC

FUNC BOOL IS_PLAYER_IN_A_ONE_ONE_ONE_VEHICLE(PLAYER_INDEX playerId)
	PED_INDEX pedPlayer 
	VEHICLE_INDEX viVehicleIndex
	
	IF IS_NET_PLAYER_OK(playerId)
		pedPlayer = GET_PLAYER_PED(playerId)
	
		//Check to see if they are in a helicopter
		IF IS_PED_IN_ANY_VEHICLE(pedPlayer)
			viVehicleIndex = GET_VEHICLE_PED_IS_IN(pedPlayer)
	//		IF IS_VEHICLE_DRIVEABLE(viVehicleIndex)
			IF DOES_ENTITY_EXIST(viVehicleIndex)
				g_mnImpromptuVehicle =  GET_ENTITY_MODEL(viVehicleIndex)
				IF IS_MODEL_VEH_DM_MODEL(g_mnImpromptuVehicle)
					PRINTLN("[CS_IMPROMPTU] IS_PLAYER_IN_A_ONE_ONE_ONE_VEHICLE, YES ")
					
					RETURN TRUE
				ELSE
					PRINTLN("[CS_IMPROMPTU] IS_PLAYER_IN_A_ONE_ONE_ONE_VEHICLE, NO, IS_MODEL_VEH_DM_MODEL ")
				ENDIF
			ELSE
				PRINTLN("[CS_IMPROMPTU] IS_PLAYER_IN_A_ONE_ONE_ONE_VEHICLE, NO, viVehicleIndex ")
			ENDIF
		ELSE
			PRINTLN("[CS_IMPROMPTU] IS_PLAYER_IN_A_ONE_ONE_ONE_VEHICLE, NO, IS_PED_IN_ANY_VEHICLE ")
		ENDIF
	ELSE
		viVehicleIndex = GET_PLAYERS_LAST_VEHICLE()
		IF DOES_ENTITY_EXIST(viVehicleIndex)
			g_mnImpromptuVehicle = GET_ENTITY_MODEL(viVehicleIndex)
			IF IS_MODEL_VEH_DM_MODEL(g_mnImpromptuVehicle)
				PRINTLN("[CS_IMPROMPTU] IS_PLAYER_IN_A_ONE_ONE_ONE_VEHICLE, YES (GET_PLAYERS_LAST_VEHICLE) ")
						
				RETURN TRUE
			ENDIF
		ENDIF
	ENDIF
	
	RETURN FALSE
ENDFUNC

STRUCT SCRIPT_EVENT_DATA_IMPROMPTU_DM
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bAccept
	BOOL bInHeli
	INT iInstanceToUse
	INT iDuration
	INT iPosix
ENDSTRUCT

PROC SET_IMPROMPTU_RIVAL_GLOBAL(PLAYER_INDEX playerRival)
	g_sImpromptuVars.playerImpromptuRival = playerRival
	#IF IS_DEBUG_BUILD
	IF playerRival != INVALID_PLAYER_INDEX()
		PRINTLN("SET_IMPROMPTU_RIVAL_GLOBAL = ", GET_PLAYER_NAME(g_sImpromptuVars.playerImpromptuRival), " my name is ", GET_PLAYER_NAME(PLAYER_ID()))
	ELSE
		PRINTLN("SET_IMPROMPTU_RIVAL_GLOBAL = INVALID_PLAYER_INDEX() my name is ", GET_PLAYER_NAME(PLAYER_ID()))
	ENDIF
	#ENDIF
ENDPROC

//PROC SET_I_AM_IN_ONE_ON_ONE_VEH()
//	IF NOT IS_BIT_SET(g_sImpromptuVars.iBitSet, ciIMPROMPTU_IN_A_HELI)
//		PRINTLN("    ----->    [CS_IMPROMPTU], ciIMPROMPTU_IN_A_HELI")
//		SET_BIT(g_sImpromptuVars.iBitSet, ciIMPROMPTU_IN_A_HELI)
//	ENDIF
//ENDPROC

//PROC SET_RIVAL_IN_ONE_ON_ONE_VEH()
//	IF NOT IS_BIT_SET(g_sImpromptuVars.iBitSet, ciIMPROMPTU_RIVAL_IN_A_HELI)
//		PRINTLN("    ----->    [CS_IMPROMPTU], ciIMPROMPTU_RIVAL_IN_A_HELI")
//		SET_BIT(g_sImpromptuVars.iBitSet, ciIMPROMPTU_RIVAL_IN_A_HELI)
//	ENDIF
//ENDPROC

PROC SET_IMPROMPTU_SPAWN_GLOBAL(BOOL bTurnOn)
	IF bTurnOn
		IF g_ImpromptuSpawn = FALSE
			PRINTLN("SET_IMPROMPTU_SPAWN_GLOBAL, TRUE")
			g_ImpromptuSpawn = TRUE
		ENDIF
	ELSE
		IF g_ImpromptuSpawn = TRUE
			PRINTLN("SET_IMPROMPTU_SPAWN_GLOBAL, FALSE")
			g_ImpromptuSpawn = FALSE
		ENDIF
	ENDIF
ENDPROC

PROC RESET_GRIEF_PASSIVE_TRACKING_AGAINST_PLAYER_FOR_IMPROMPTU_DM(PLAYER_INDEX thisPlayer)
	IF NATIVE_TO_INT(thisPlayer) != -1
		IF g_sGriefPassivePlayer[NATIVE_TO_INT(thisPlayer)].iKills > 0
			IF HAS_NET_TIMER_STARTED(g_sGriefPassivePlayer[NATIVE_TO_INT(thisPlayer)].GriefPassiveWindowTimer)
				RESET_NET_TIMER(g_sGriefPassivePlayer[NATIVE_TO_INT(thisPlayer)].GriefPassiveWindowTimer)
			ENDIF
			IF HAS_NET_TIMER_STARTED(g_sGriefPassivePlayer[NATIVE_TO_INT(thisPlayer)].GriefDurationTimer)
				RESET_NET_TIMER(g_sGriefPassivePlayer[NATIVE_TO_INT(thisPlayer)].GriefDurationTimer)
			ENDIF
			g_sGriefPassivePlayer[NATIVE_TO_INT(thisPlayer)].iKills = 0
			PRINTLN("[ST] [GRIEF PASSIVE] - SEND_IMPROMPTU_CHALLENGE - Sending a 1v1 deathmatch invite, resetting kill stat and resetting timers for player ", GET_PLAYER_NAME(thisPlayer))
		ENDIF
	ENDIF	
ENDPROC

// Challenge player to One on One DM
PROC SEND_IMPROMPTU_CHALLENGE(PLAYER_INDEX PlayerID, BOOL bInHeli, INT iPosix)
	SCRIPT_EVENT_DATA_IMPROMPTU_DM Event
	Event.Details.Type 				= SCRIPT_EVENT_IMPROMPTU_DM_REQUEST
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bInHeli					= bInHeli
	Event.iDuration					= GET_MP_INT_CHARACTER_STAT(MP_STAT_TIME_FOR_ONE_ON_ONE_DM)
	Event.iPosix = iPosix
	SET_IMPROMPTU_RIVAL_GLOBAL(PlayerID)
	
	// We have a valid player, send the challenge event
	IF IS_NET_PLAYER_OK(PlayerID, FALSE)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event),  SPECIFIC_PLAYER(PlayerID))	
		SET_BIT(g_sImpromptuVars.iBitSet, ciIMPROMPTU_ACTIVE_REQUEST_AWAITING_REPLY)
		CLEAR_BIT(g_sImpromptuVars.iBitSet, ciIMPROMPTU_KILL_ALL_REQUESTS)
		IF NOT g_bShouldBlockPauseJobs 
			PRINTLN(" [CS_IMPROMPTU] SEND_IMPROMPTU_CHALLENGE, g_bShouldBlockPauseJobs = TRUE ")
			g_bShouldBlockPauseJobs = TRUE
		ENDIF
		
		SET_PACKED_STAT_BOOL(PACKED_MP_CHALLENGE_ONEONONEDM, TRUE)
		
		RESET_GRIEF_PASSIVE_TRACKING_AGAINST_PLAYER_FOR_IMPROMPTU_DM(PlayerID)
		
//		IF IS_PLAYER_IN_A_ONE_ONE_ONE_VEHICLE(PLAYER_ID())
//			IF IS_PLAYER_IN_A_ONE_ONE_ONE_VEHICLE(PlayerID)
//				PRINTLN(" [CS_IMPROMPTU] SEND_IMPROMPTU_CHALLENGE, IS_PLAYER_IN_A_ONE_ONE_ONE_VEHICLE >>> YES, SENDER ")
////				SET_I_AM_IN_ONE_ON_ONE_VEH()
////				SET_RIVAL_IN_ONE_ON_ONE_VEH()
//			ENDIF
//		ENDIF
		
	// Debug
	#IF IS_DEBUG_BUILD
		PRINTLN(" REQUEST ")
		PRINTLN(" [CS_IMPROMPTU] g_sImpromptuVars.iBitSet, ciIMPROMPTU_KILL_ALL_REQUESTS, Event.iPosix = ", Event.iPosix)
		PRINTLN(" [CS_IMPROMPTU] SEND_IMPROMPTU_CHALLENGE from = ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex) )
		PRINTLN(" [CS_IMPROMPTU] SEND_IMPROMPTU_CHALLENGE to = ", GET_PLAYER_NAME(PlayerID), " id = ", NATIVE_TO_INT(PlayerID))
		PRINTLN(" [CS_IMPROMPTU] SEND_IMPROMPTU_CHALLENGE [IMP_TIME] iDuration = ", Event.iDuration)
		IF Event.bInHeli
			PRINTLN(" [CS_IMPROMPTU] bInHeli " )
		ELSE
			PRINTLN(" [CS_IMPROMPTU] NOT bInHeli " )
		ENDIF
	ELSE
		SCRIPT_ASSERT(" SEND_IMPROMPTU_CHALLENGE, invalid player ")
		PRINTLN(" [CS_IMPROMPTU] SEND_IMPROMPTU_CHALLENGE, invalid player ")
	#ENDIF
	ENDIF
ENDPROC

// Reply to challenger (One on One Deathmatch) see REPLY_TO_IMPROMPTU_CHALLENGE
PROC REPLY_TO_IMPROMPTU_CHALLENGE(PLAYER_INDEX PlayerID, BOOL bAccept, INT iInstanceToUse, BOOL bInHeli, INT iPosix)
	SCRIPT_EVENT_DATA_IMPROMPTU_DM Event
	Event.Details.Type 				= SCRIPT_EVENT_IMPROMPTU_DM_REPLY
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bAccept					= bAccept
	Event.bInHeli					= bInHeli
	Event.iInstanceToUse			= iInstanceToUse
	Event.iPosix					= iPosix
	SET_IMPROMPTU_RIVAL_GLOBAL(PlayerID)
	
	// Send reply if valid player
	IF PlayerID <> INVALID_PLAYER_INDEX()
	AND IS_NET_PLAYER_OK(PlayerID, FALSE)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event),  SPECIFIC_PLAYER(PlayerID))	
		CLEAR_BIT(g_sImpromptuVars.iBitSet, ciIMPROMPTU_KILL_ALL_REQUESTS)
		IF bAccept
			SET_IMPROMPTU_SPAWN_GLOBAL(TRUE)
			
			RESET_GRIEF_PASSIVE_TRACKING_AGAINST_PLAYER_FOR_IMPROMPTU_DM(PlayerID)
		ENDIF
		
	// Debug	
	#IF IS_DEBUG_BUILD
		PRINTLN(" REPLY ")
		PRINTLN(" [CS_IMPROMPTU] 3540699 g_sImpromptuVars.iBitSet, ciIMPROMPTU_KILL_ALL_REQUESTS, Event.iPosix = ", Event.iPosix)
		PRINTLN(" [CS_IMPROMPTU] REPLY_TO_IMPROMPTU_CHALLENGE from = ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex) )
		PRINTLN(" [CS_IMPROMPTU] SEND_IMPROMPTU_CHALLENGE to = ", GET_PLAYER_NAME(PlayerID), " id = ", NATIVE_TO_INT(PlayerID))
		IF Event.bInHeli
			PRINTLN(" [CS_IMPROMPTU] bInHeli " )
		ELSE
			PRINTLN(" [CS_IMPROMPTU] NOT bInHeli " )
		ENDIF
		PRINTLN(" [CS_IMPROMPTU] Event.iInstanceToUse ", Event.iInstanceToUse)
	ELSE
		SCRIPT_ASSERT(" REPLY_TO_IMPROMPTU_CHALLENGE, invalid player ")
		PRINTLN(" [CS_IMPROMPTU] REPLY_TO_IMPROMPTU_CHALLENGE, invalid player ")
	#ENDIF
	ENDIF
ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║				SCRIPT_EVENT_EXEC_DROP											║
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_EXEC_DROP
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iVeh
	INT iDropOff
	INT iPosix
ENDSTRUCT

PROC BROADCAST_CRATE_EVENT(INT iVeh, INT iDropOff, INT iPosix)
	SCRIPT_EVENT_DATA_EXEC_DROP Event
	Event.Details.Type = SCRIPT_EVENT_EXEC_DROP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iVeh = iVeh
	Event.iDropOff = iDropOff
	Event.iPosix = iPosix
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_CRATE_EVENT iVeh = ", iVeh, " iDropOff = ", iDropOff, " iPosix = ", iPosix)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("BROADCAST_CRATE_EVENT - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				SCRIPT_EVENT_SELL_BAG_DROP										║
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_BAG_DROP
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iBag
	INT iDrop
	INT iPosix
ENDSTRUCT

PROC BROADCAST_BAG_EVENT(INT iBag, INT iDrop, INT iPosix)
	SCRIPT_EVENT_DATA_BAG_DROP Event
	Event.Details.Type = SCRIPT_EVENT_BAG_DROP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iBag = iBag
	Event.iDrop = iDrop
	Event.iPosix = iPosix
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		PRINTLN("[BIKER_SELL] [BAGS] BROADCAST_BAG_EVENT, iBag = ", iBag, " iDrop = ", iDrop, " iPosix = ", iPosix)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("[BIKER_SELL] [BAGS] BROADCAST_BAG_EVENT - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				SCRIPT_EVENT_REPAIR												║
//╚═════════════════════════════════════════════════════════════════════════════╝

//STRUCT SCRIPT_EVENT_DATA_EXEC_DROP_REPAIR
//	STRUCT_EVENT_COMMON_DETAILS Details
//	INT iStatus
//ENDSTRUCT
//
//CONST_INT ciREPAIR_SET 		0
//CONST_INT ciREPAIR_RESET	1
//CONST_INT ciREPAIR_SUCCESS	2
//
//PROC BROADCAST_REPAIR_EVENT(INT iStatus)
//	SCRIPT_EVENT_DATA_EXEC_DROP_REPAIR Event
//	Event.Details.Type = SCRIPT_EVENT_EXEC_DROP_REPAIR
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.iStatus = iStatus
//	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
//	IF NOT (iPlayerFlags = 0)
//		PRINTLN("BROADCAST_REPAIR_EVENT iStatus = ", iStatus)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	#IF IS_DEBUG_BUILD	
//	ELSE
//		PRINTLN("BROADCAST_SERVER_DM_FINISHED - playerflags = 0 so not broadcasting") 
//	#ENDIF
//	ENDIF	
//ENDPROC

 // #IF FEATURE_EXECUTIVE

STRUCT SCRIPT_EVENT_DATA_BIKER_BORDER_PATROL_FAIL_CHECKPOINT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iVeh
	INT iFailedDropOff
ENDSTRUCT

PROC BROADCAST_PLAYER_FAILED_CHECKPOINT(INT iVeh, INT iClosestDrop)
	SCRIPT_EVENT_DATA_BIKER_BORDER_PATROL_FAIL_CHECKPOINT Event
	Event.Details.Type = SCRIPT_EVENT_BIKER_FAIL_CHECKPOINT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iVeh = iVeh
	Event.iFailedDropOff = iClosestDrop
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_PLAYER_FAILED_CHECKPOINT ")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("BROADCAST_PLAYER_FAILED_CHECKPOINT - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
ENDPROC

STRUCT AMBIENT_VEHICLE_DETAILS
	MODEL_NAMES ModelName
	INT iHashPlateText
	INT iRand	
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_LOCK_ANY_DUPE_AMBIENT_VEHICLES
	STRUCT_EVENT_COMMON_DETAILS Details
	AMBIENT_VEHICLE_DETAILS AmbVeh
ENDSTRUCT

PROC BROADCAST_LOCK_ANY_DUPE_AMBIENT_VEHICLES(AMBIENT_VEHICLE_DETAILS AmbVeh)
	SCRIPT_EVENT_DATA_LOCK_ANY_DUPE_AMBIENT_VEHICLES Event
	Event.Details.Type = SCRIPT_EVENT_LOCK_ANY_DUPE_AMBIENT_VEHICLES
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.AmbVeh.ModelName = AmbVeh.ModelName
	Event.AmbVeh.iHashPlateText = AmbVeh.iHashPlateText
	Event.AmbVeh.iRand = AmbVeh.iRand
	PRINTLN("[vehicle_duping] BROADCAST_LOCK_ANY_DUPE_AMBIENT_VEHICLES, ModelName=", ENUM_TO_INT(AmbVeh.ModelName), ", iHashPlateText=", AmbVeh.iHashPlateText, ", iRand=", AmbVeh.iRand)
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event),  ALL_PLAYERS())	
ENDPROC

PROC LOCK_ANY_AMBIENT_DUPES_OF_THIS_VEHICLE(VEHICLE_INDEX VehicleID)

	IF ( g_sMPTunables.bEnabled_LOCK_ANY_AMBIENT_DUPES_OF_THIS_VEHICLE)
		AMBIENT_VEHICLE_DETAILS AmbVeh

		IF DOES_ENTITY_EXIST(VehicleID)
		
			IF NETWORK_GET_ENTITY_IS_NETWORKED(VehicleID)
		
				AmbVeh.ModelName = GET_ENTITY_MODEL(VehicleID)
				AmbVeh.iHashPlateText = GET_HASH_KEY(GET_VEHICLE_NUMBER_PLATE_TEXT(VehicleID))
								
				IF DECOR_IS_REGISTERED_AS_TYPE("RandomID", DECOR_TYPE_INT)
					IF NOT DECOR_EXIST_ON(VehicleID, "RandomID")
						AmbVeh.iRand = GET_RANDOM_INT_IN_RANGE()
						DECOR_SET_INT(VehicleID, "RandomID", AmbVeh.iRand)
					ELSE
						AmbVeh.iRand = 	DECOR_GET_INT(VehicleID, "RandomID")
					ENDIF
				ENDIF
				
				BROADCAST_LOCK_ANY_DUPE_AMBIENT_VEHICLES(AmbVeh)
			
			ELSE
				PRINTLN("[vehicle_duping] LOCK_ANY_AMBIENT_DUPES_OF_THIS_VEHICLE - vehicle is not networked")
			ENDIF
			
		ENDIF
	ELSE
		PRINTLN("[vehicle_duping] LOCK_ANY_AMBIENT_DUPES_OF_THIS_VEHICLE - disabled")
	ENDIF

ENDPROC



FUNC INT ALL_PLAYERS_IN_MY_GANG(BOOL bIncludeBoss = FALSE)
	INT iPlayerFlags
	INT iParticipant
	PLAYER_INDEX playerMyBoss
	PRINTLN("ALL_PLAYERS_IN_MY_GANG - bIncludeBoss = ", bIncludeBoss)
	IF GB_IS_LOCAL_PLAYER_MEMBER_OF_A_GANG(TRUE)
		REPEAT NUM_NETWORK_PLAYERS iParticipant
			PLAYER_INDEX playerId = INT_TO_PLAYERINDEX(iParticipant)
			IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
				
				IF GB_IS_LOCAL_PLAYER_BOSS_OF_A_GANG()
					IF GB_IS_PLAYER_MEMBER_OF_THIS_GANG(PlayerId, PLAYER_ID(),bIncludeBoss)
						SET_BIT( iPlayerFlags , NATIVE_TO_INT(PlayerID))
						PRINTLN("ALL_PLAYERS_IN_MY_GANG - I'M A BOSS - THIS PLAYER IN MY GANG ", GET_PLAYER_NAME(PlayerId))
					ENDIF
				ELSE
					playerMyBoss = GB_GET_LOCAL_PLAYER_GANG_BOSS()
					IF playerMyBoss <> INVALID_PLAYER_INDEX()
						IF GB_IS_PLAYER_MEMBER_OF_THIS_GANG(PlayerId, playerMyBoss, bIncludeBoss)
							SET_BIT( iPlayerFlags , NATIVE_TO_INT(PlayerID))
							PRINTLN("ALL_PLAYERS_IN_MY_GANG - I'M NOT A BOSS - MY BOSS IS ", GET_PLAYER_NAME(playerMyBoss)," THIS PLAYER IN MY GANG ", GET_PLAYER_NAME(PlayerId))
						ENDIF
					ENDIF
				ENDIF	
			ENDIF
		ENDREPEAT
	ELSE
		PRINTLN("ALL_PLAYERS_IN_MY_GANG - I'M NOT A GANG MEMBER")
	ENDIF
	
	
	RETURN iPlayerFlags
ENDFUNC

FUNC INT ALL_PLAYERS_IN_PLAYER_GANG(PLAYER_INDEX piPlayer, BOOL bIncludeBoss = FALSE)
	INT iPlayerFlags
	INT iParticipant
	PLAYER_INDEX playerMyBoss
	PRINTLN("ALL_PLAYERS_IN_PLAYER_GANG - bIncludeBoss = ", bIncludeBoss)
	IF GB_IS_PLAYER_MEMBER_OF_A_GANG(piPlayer,TRUE)
		REPEAT NUM_NETWORK_PLAYERS iParticipant
			PLAYER_INDEX playerId = INT_TO_PLAYERINDEX(iParticipant)
			IF IS_NET_PLAYER_OK(playerId, FALSE, FALSE)
				
				IF GB_IS_PLAYER_BOSS_OF_A_GANG(piPlayer)
					IF GB_IS_PLAYER_MEMBER_OF_THIS_GANG(PlayerId, piPlayer,bIncludeBoss)
						SET_BIT( iPlayerFlags , NATIVE_TO_INT(PlayerID))
						PRINTLN("ALL_PLAYERS_IN_PLAYER_GANG - I'M A BOSS - THIS PLAYER IN MY GANG ", GET_PLAYER_NAME(PlayerId))
					ENDIF
				ELSE
					playerMyBoss = GB_GET_THIS_PLAYER_GANG_BOSS(piPlayer)
					IF playerMyBoss <> INVALID_PLAYER_INDEX()
						IF GB_IS_PLAYER_MEMBER_OF_THIS_GANG(PlayerId, playerMyBoss, bIncludeBoss)
							SET_BIT( iPlayerFlags , NATIVE_TO_INT(PlayerID))
							PRINTLN("ALL_PLAYERS_IN_PLAYER_GANG - I'M NOT A BOSS - MY BOSS IS ", GET_PLAYER_NAME(playerMyBoss)," THIS PLAYER IN MY GANG ", GET_PLAYER_NAME(PlayerId))
						ENDIF
					ENDIF
				ENDIF	
			ENDIF
		ENDREPEAT
	ELSE
		PRINTLN("ALL_PLAYERS_IN_PLAYER_GANG - I'M NOT A GANG MEMBER")
	ENDIF
	
	
	RETURN iPlayerFlags
ENDFUNC
//╔═════════════════════════════════════════════════════════════════════════════╗
//║							BOSS DROPS								

#IF IS_DEBUG_BUILD

FUNC STRING GB_GET_BOSS_DROP_STRING(eGB_BOSS_DROPS eBossDrop)
	
	SWITCH eBossDrop
		CASE eGB_BOSS_DROPS_NONE
			RETURN "eGB_BOSS_DROPS_NONE"
		BREAK
		CASE eGB_BOSS_DROPS_BULLSHARK
			RETURN "eGB_BOSS_DROPS_BULLSHARK"
		BREAK
		CASE eGB_BOSS_DROPS_AMMO
			RETURN "eGB_BOSS_DROPS_AMMO"
		BREAK
		CASE eGB_BOSS_DROPS_ARMOUR
			RETURN "eGB_BOSS_DROPS_ARMOUR"
		BREAK
		CASE eGB_BOSS_DROPS_MOLOTOV
			RETURN "eGB_BOSS_DROPS_MOLOTOV"
		BREAK
		CASE eGB_BOSS_DROPS_SNACKS
			RETURN "eGB_BOSS_DROPS_SNACKS"
		BREAK
	ENDSWITCH
	
	RETURN ""
ENDFUNC

#ENDIF //#IF IS_DEBUG_BUILD

STRUCT GB_SCRIPT_EVENT_DATA_BOSS_DROP
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iSubType
	INT iAmount
	PLAYER_INDEX playerFor
	eGB_BOSS_DROPS eBossDrop
	VECTOR vPos
	FLOAT fHeading
	NETWORK_INDEX niPickup
ENDSTRUCT

FUNC BOOL GB_IS_BOSS_DROP_SLOT_AVAILABLE()

	IF g_sBossDropOverall.iTotalActiveBossDrops < ciGB_TOTAL_MAX_DROPS_ON_GROUND
	
		RETURN TRUE
	ENDIF
	
	RETURN FALSE
ENDFUNC

FUNC BOOL GB_IS_THIS_BOSS_DROP_IN_PROGRESS(eGB_BOSS_DROPS eBossDrop)

	SWITCH eBossDrop
		CASE eGB_BOSS_DROPS_BULLSHARK
			RETURN ( g_sBossDropOverall.iActiveCountBullshark > 0 )
		
		CASE eGB_BOSS_DROPS_AMMO
			RETURN ( g_sBossDropOverall.iActiveCountAmmo > 0 )
			
		CASE eGB_BOSS_DROPS_ARMOUR
			RETURN ( g_sBossDropOverall.iActiveCountArmour > 0 )
		
		CASE eGB_BOSS_DROPS_MOLOTOV
			RETURN ( g_sBossDropOverall.iActiveCountMolotov > 0 )
		
		CASE eGB_BOSS_DROPS_SNACKS
			RETURN ( g_sBossDropOverall.iActiveCountSnack > 0 )

	ENDSWITCH

	RETURN FALSE
ENDFUNC

// The Gang Boss sends this event when a Boss Drop is chosen from the Pi menu
PROC GB_BROADCAST_BOSS_DROP(eGB_BOSS_DROPS eBossDrop, PLAYER_INDEX playerFor, INT iSubType, INT iAmount, NETWORK_INDEX niPickup, VECTOR vPickupPos)
	GB_SCRIPT_EVENT_DATA_BOSS_DROP Event
	Event.Details.Type = SCRIPT_EVENT_BOSS_DROP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iSubType = iSubType
	Event.iAmount = iAmount
	Event.eBossDrop = eBossDrop
	Event.playerFor = playerFor
	Event.niPickup = niPickup
	
	INT iPlayerFlags

	IF IS_NET_PLAYER_OK(PLAYER_ID(), FALSE)
	AND GB_IS_BOSS_DROP_SLOT_AVAILABLE()
		
		Event.vPos = vPickupPos
		
		iPlayerFlags = ALL_PLAYERS_IN_MY_GANG(FALSE)
		
		IF iPlayerFlags <> 0
	
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
		ELSE
			PRINTLN("[MAGNATE_GANG_BOSS] [BOSS_DROPS]  GB_BROADCAST_BOSS_DROP, iPlayerFlags = 0 ")
		ENDIF
		
	#IF IS_DEBUG_BUILD
		PRINTLN(" [MAGNATE_GANG_BOSS] [BOSS_DROPS]  GB_BROADCAST_BOSS_DROP   ----->    SCRIPT_EVENT_BOSS_DROP - SENT BY ", GET_PLAYER_NAME(PLAYER_ID()),
				" iSubType = ", iSubType, " iAmount = ", iAmount, " eBossDrop = ", GB_GET_BOSS_DROP_STRING(eBossDrop), " vPos = ", Event.vPos, " fHeading = ", Event.fHeading,
				" niPickup = ", NATIVE_TO_INT(niPickup))
	ELSE
		PRINTLN("[MAGNATE_GANG_BOSS] [BOSS_DROPS] GB_BROADCAST_BOSS_DROP, ERROR, iTotalActiveBossDrops = ", g_sBossDropOverall.iTotalActiveBossDrops, " ciGB_TOTAL_MAX_DROPS_ON_GROUND = ", ciGB_TOTAL_MAX_DROPS_ON_GROUND)
	#ENDIF // #IF IS_DEBUG_BUILD
	
	ENDIF
ENDPROC

//╚═════════════════════════════════════════════════════════════════════════════╝


CONST_INT BOSSVBOSS_DM		0
CONST_INT BOSSVBOSS_JOUST	1
CONST_INT BOSS_COOPERATIVE	2

CONST_INT BOSS_V_BOSS_ACTIVELY_REJECT		0
CONST_INT BOSS_V_BOSS_UNABLE_TO_TAKE_PART	1


STRUCT SCRIPT_EVENT_DATA_BOSS_DM
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bAccept
	BOOL bInHeli
	INT iInstanceToUse
	INT iDuration
	INT iFmmcType
	INT iType
	INT iVariation
	INT iRejectReason
ENDSTRUCT


// Challenge player to One on One DM
PROC SEND_BOSSVBOSS_CHALLENGE(PLAYER_INDEX PlayerID, BOOL bInHeli , INT iType = BOSSVBOSS_DM )
	SCRIPT_EVENT_DATA_BOSS_DM Event
	Event.Details.Type 				= SCRIPT_EVENT_BOSSVBOSS_DM_REQUEST
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bInHeli					= bInHeli
	Event.iDuration					= GET_MP_INT_CHARACTER_STAT(MP_STAT_TIME_FOR_ONE_ON_ONE_DM)
	Event.iType						= iType
	SET_IMPROMPTU_RIVAL_GLOBAL(PlayerID)
	
	// We have a valid player, send the challenge event
	IF IS_NET_PLAYER_OK(PlayerID, FALSE)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event),  SPECIFIC_PLAYER(PlayerID))	
		SET_BIT(g_sImpromptuVars.iBitSet, ciBOSSVBOSS_ACTIVE_REQUEST_AWAITING_REPLY)
		CLEAR_BIT(g_sImpromptuVars.iBitSet, ciBOSSVBOSS_KILL_ALL_REQUESTS)
		
		g_sImpromptuVars.iBossDmType = Event.iType
		IF NOT g_bShouldBlockPauseJobs 
			PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] SEND_BOSSVBOSS_CHALLENGE, g_bShouldBlockPauseJobs = TRUE ")
			g_bShouldBlockPauseJobs = TRUE
		ENDIF
		
		SET_PACKED_STAT_BOOL(PACKED_MP_CHALLENGE_ONEONONEDM, TRUE)
		

	// Debug
	#IF IS_DEBUG_BUILD
		PRINTLN(" REQUEST ")
	//	PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] g_sImpromptuVars.iBitSet, ciIMPROMPTU_KILL_ALL_REQUESTS")
		PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] SEND_BOSSVBOSS_CHALLENGE from = ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex) )
		PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] SEND_BOSSVBOSS_CHALLENGE to = ", GET_PLAYER_NAME(PlayerID), " id = ", NATIVE_TO_INT(PlayerID))
		PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] SEND_BOSSVBOSS_CHALLENGE [IMP_TIME] iDuration = ", Event.iDuration)
		PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] SEND_BOSSVBOSS_CHALLENGE iType = ", iType)
		IF Event.bInHeli
			PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] bInHeli " )
		ELSE
			PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] NOT bInHeli " )
		ENDIF
	ELSE
		SCRIPT_ASSERT("[dsw] SEND_BOSSVBOSS_CHALLENGE, invalid player ")
		PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] SEND_BOSSVBOSS_CHALLENGE, invalid player ")
	#ENDIF
	ENDIF
ENDPROC


FUNC INT GET_BOSS_INVITE_TYPE_FROM_FMMC_TYPE(INT iFMMCType)
	SWITCH iFMMCType
		CASE FMMC_TYPE_GB_BOSS_DEATHMATCH	RETURN BOSSVBOSS_DM
		CASE FMMC_TYPE_BIKER_JOUST			RETURN BOSSVBOSS_JOUST
	ENDSWITCH
	
	RETURN BOSS_COOPERATIVE
ENDFUNC

PROC SEND_BOSS_COOP_INVITE(PLAYER_INDEX PlayerID, INT iFmmcType, INT iVariation = -1)
	SCRIPT_EVENT_DATA_BOSS_DM Event
	Event.Details.Type 				= SCRIPT_EVENT_BOSSVBOSS_DM_REQUEST
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iVariation				= iVariation
	Event.iFmmcType					= iFmmcType
	Event.iType						= GET_BOSS_INVITE_TYPE_FROM_FMMC_TYPE(iFMMCType)
	
	SET_IMPROMPTU_RIVAL_GLOBAL(PlayerID)
	IF IS_NET_PLAYER_OK(PlayerID, FALSE)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event),  SPECIFIC_PLAYER(PlayerID))	
		SET_BIT(g_sImpromptuVars.iBitSet, ciBOSSVBOSS_ACTIVE_REQUEST_AWAITING_REPLY)
		CLEAR_BIT(g_sImpromptuVars.iBitSet, ciBOSSVBOSS_KILL_ALL_REQUESTS)
		g_sImpromptuVars.iBossDmType = Event.iType
		g_sImpromptuVars.iFmmcType = Event.iFmmcType
		g_sImpromptuVars.iVariation = Event.iVariation
	#IF IS_DEBUG_BUILD

		PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] [SEND_BOSS_COOP_INVITE] SEND_BOSS_COOP_INVITE from = ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex) )
		PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] [SEND_BOSS_COOP_INVITE] SEND_BOSSSEND_BOSS_COOP_INVITEVBOSS_CHALLENGE to = ", GET_PLAYER_NAME(PlayerID), " id = ", NATIVE_TO_INT(PlayerID))

		PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] [SEND_BOSS_COOP_INVITE] SEND_BOSS_COOP_INVITE iType = ", Event.iType)
		PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] [SEND_BOSS_COOP_INVITE] SEND_BOSS_COOP_INVITE iFmmcType = ", Event.iFmmcType)


	ELSE
		SCRIPT_ASSERT("[dsw] SEND_BOSS_COOP_INVITE, invalid player ")
		PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] SEND_BOSS_COOP_INVITE, invalid player ")
	#ENDIF
	ENDIF
ENDPROC

// Reply to challenger (One on One Deathmatch)
PROC REPLY_TO_BOSSVBOSS_CHALLENGE(PLAYER_INDEX PlayerID, BOOL bAccept, INT iInstanceToUse, BOOL bInHeli, INT iRejectReason = BOSS_V_BOSS_ACTIVELY_REJECT)
	SCRIPT_EVENT_DATA_BOSS_DM Event
	Event.Details.Type 				= SCRIPT_EVENT_BOSSVBOSS_DM_REPLY
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bAccept					= bAccept
	Event.bInHeli					= bInHeli
	Event.iInstanceToUse			= iInstanceToUse
	Event.iRejectReason				= iRejectReason
	SET_IMPROMPTU_RIVAL_GLOBAL(PlayerID)
	
	// Send reply if valid player
	IF PlayerID <> INVALID_PLAYER_INDEX()
	AND IS_NET_PLAYER_OK(PlayerID, FALSE)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event),  SPECIFIC_PLAYER(PlayerID))	
		CLEAR_BIT(g_sImpromptuVars.iBitSet, ciBOSSVBOSS_KILL_ALL_REQUESTS)
		IF bAccept
			IF g_sImpromptuVars.iBossDmType = BOSSVBOSS_DM
				SET_IMPROMPTU_SPAWN_GLOBAL(TRUE)
			ENDIF
		ENDIF
		
	// Debug	
	#IF IS_DEBUG_BUILD
		PRINTLN(" REPLY ")
		PRINTLN(" [dsw] [CS_IMPROMPTU] g_sImpromptuVars.iBitSet, ciBOSSVBOSS_KILL_ALL_REQUESTS ")
		PRINTLN(" [dsw] [CS_IMPROMPTU] REPLY_TO_BOSSVBOSS_CHALLENGE from = ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex), " bAccept = ", bAccept)
		PRINTLN(" [dsw] [CS_IMPROMPTU] SEND_IMPROMPTU_CHALLENGE to = ", GET_PLAYER_NAME(PlayerID), " id = ", NATIVE_TO_INT(PlayerID))
		IF Event.bInHeli
			PRINTLN("[dsw] [CS_IMPROMPTU] bInHeli " )
		ELSE
			PRINTLN("[dsw] [CS_IMPROMPTU] NOT bInHeli " )
		ENDIF
		PRINTLN("[dsw] [CS_IMPROMPTU] Event.iInstanceToUse ", Event.iInstanceToUse)
	ELSE
		SCRIPT_ASSERT("[dsw] REPLY_TO_BOSSVBOSS_CHALLENGE, invalid player ")
		PRINTLN("[dsw] [CS_IMPROMPTU] REPLY_TO_BOSSVBOSS_CHALLENGE, invalid player ")
	#ENDIF
	ENDIF
ENDPROC

PROC GB_GET_MY_GANG_MEMBERS_TO_JOIN_BOSSVBOSS_DM(INT iInstanceToUse)
	SCRIPT_EVENT_DATA_BOSS_DM Event
	Event.Details.Type 				= SCRIPT_EVENT_BOSSVBOSS_DM_JOIN_MY_BOSS
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bAccept					= TRUE
	Event.iInstanceToUse			= iInstanceToUse
	
	IF ALL_PLAYERS_IN_MY_GANG(FALSE) <> 0
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event),  ALL_PLAYERS_IN_MY_GANG(FALSE))	
	ELSE
		PRINTLN(" [dsw] [BOSSVBOSS] [CS_IMPROMPTU] [GB_GET_MY_GANG_MEMBERS_TO_JOIN_BOSSVBOSS_DM] ALL_PLAYERS_IN_MY_GANG is 0!")
	ENDIF
	CLEAR_BIT(g_sImpromptuVars.iBitSet, ciBOSSVBOSS_KILL_ALL_REQUESTS)
	
	#IF IS_DEBUG_BUILD
		
		PRINTLN(" [dsw] [BOSSVBOSS] [CS_IMPROMPTU] [GB_GET_MY_GANG_MEMBERS_TO_JOIN_BOSSVBOSS_DM] ")
		PRINTLN("[dsw] [BOSSVBOSS] [CS_IMPROMPTU] GB_GET_MY_GANG_MEMBERS_TO_JOIN_BOSSVBOSS_DM Event.iInstanceToUse ", Event.iInstanceToUse)

	#ENDIF
	
ENDPROC
 // FEATURE_GANG_BOSS

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				DEATHMATCH														║
//╚═════════════════════════════════════════════════════════════════════════════╝

PROC INCREMENT_DEATH_STREAK()
	g_iDeathStreak++
	PRINTLN("INCREMENT_DEATH_STREAK g_iDeathStreak ", g_iDeathStreak)
	DEBUG_PRINTCALLSTACK()
ENDPROC

PROC RESET_DEATH_STREAK()
	g_iDeathStreak = 0
	g_e_Chosen_Perk = KS_PP_NOT_USE
	PRINTLN("RESET_DEATH_STREAK  ")
	DEBUG_PRINTCALLSTACK()
ENDPROC

// Add or deduct points and stats
PROC INCREMENT_KILLS()
	g_iMyAmountOfKills++
	PRINTLN("INCREMENT_KILLS | g_iMyAmountOfKills: ", g_iMyAmountOfKills)
	DEBUG_PRINTCALLSTACK()
	RESET_DEATH_STREAK()
ENDPROC

PROC DECREMENT_KILLS()
	IF g_iMyAmountOfKills > 0
		g_iMyAmountOfKills--
		PRINTLN("DECREMENT_KILLS ", g_iMyAmountOfKills)
		DEBUG_PRINTCALLSTACK()
	ENDIF
ENDPROC

PROC INCREMENT_DEATHS()
	g_iMyAmountOfDeaths++
	PRINTLN("INCREMENT_DEATHS g_iMyAmountOfDeaths ", g_iMyAmountOfDeaths)
	DEBUG_PRINTCALLSTACK()
	INCREMENT_DEATH_STREAK()
ENDPROC

PROC INCREMENT_SUICIDES()
	g_iMyAmountOfSuicides++
	PRINTLN("INCREMENT_SUICIDES g_iMyAmountOfSuicides ", g_iMyAmountOfSuicides)
	DEBUG_PRINTCALLSTACK()
ENDPROC

PROC DEDUCT_DEATHMATCH_SCORE()
	IF g_b_On_Deathmatch
		IF g_iMyDMScore > 0
			g_iMyDMScore --
			PRINTLN("DEDUCT_DEATHMATCH_SCORE g_iMyDMScore ", g_iMyDMScore)
			DEBUG_PRINTCALLSTACK()
		ENDIF
	ENDIF
ENDPROC

PROC INCREMENT_DEATHMATCH_SCORE(INT iVictimPlayerId = -1, INT iIncrementValue = 1)
	IF g_b_On_Deathmatch
		IF g_bFM_ON_IMPROMPTU_DEATHMATCH
		AND GlobalplayerBD_FM[NATIVE_TO_INT(PLAYER_ID())].iCurrentMissionType != FMMC_TYPE_GB_BOSS_DEATHMATCH
			IF g_sImpromptuVars.playerImpromptuRival = INT_TO_PLAYERINDEX(iVictimPlayerId)
//				IF IS_BIT_SET(GlobalplayerBD_FM[iVictimPlayerId].iXPBitset, ciGLOBAL_XP_BIT_ON_IMPROMPTU_DM)
				g_iMyDMScore += iIncrementValue
				PRINTLN("INCREMENT_DEATHMATCH_SCORE, IS_ON_IMPROMPTU_DEATHMATCH_GLOBAL_SET, g_iMyDMScore ", g_iMyDMScore)
//				ENDIF
			ENDIF
		ELSE
			g_iMyDMScore += iIncrementValue
			PRINTLN("INCREMENT_DEATHMATCH_SCORE g_iMyDMScore ", g_iMyDMScore)
		ENDIF
		
		DEBUG_PRINTCALLSTACK()
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				VEH DM KILL														║
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_LAST_DAMAGER
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iLastDamagerPlayer = -1 
	INT iKillerId = -1
	WEAPON_TYPE weaponType
ENDSTRUCT

PROC BROADCAST_LAST_DAMAGER(INT iLastDamagerPlayer, INT killerPlayerID, WEAPON_TYPE weaponUsed)
	SCRIPT_EVENT_DATA_LAST_DAMAGER Event
	Event.Details.Type = SCRIPT_EVENT_DM_VEH_KILL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iLastDamagerPlayer = iLastDamagerPlayer
	Event.iKillerId = killerPlayerID
	Event.weaponType = weaponUsed
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		PRINTLN(" [CS_EVENTS] BROADCAST_LAST_DAMAGER iLastDamagerPlayer      = ", iLastDamagerPlayer)
		PRINTLN(" [CS_EVENTS] BROADCAST_LAST_DAMAGER killerPlayerID      = ", killerPlayerID)
//		PRINTLN(" [CS_EVENTS] BROADCAST_LAST_DAMAGER g_weaponUsedLastDamager =  ",  GET_WEAPON_NAME(INT_TO_ENUM(WEAPON_TYPE, g_weaponUsedLastDamager))) 
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN(" [CS_EVENTS] BROADCAST_LAST_DAMAGER - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF
ENDPROC

PROC RESET_LAST_DAMAGER()
	PRINTLN(" [CS_EVENTS] RESET_LAST_DAMAGER ")
	g_iLastDamagerPlayer = -1
	g_iLastDamagerTimeStamp = -1	
	GlobalplayerBD[NATIVE_TO_INT(PLAYER_ID())].iLastDamagerPlayer = -1
	g_weaponUsedLastDamager = WEAPONTYPE_INVALID
ENDPROC

PROC SEND_LAST_DAMAGER_EVENT(INT iKillerId)
	IF g_iLastDamagerPlayer <> -1
	AND iKillerId <> g_iLastDamagerPlayer
		BROADCAST_LAST_DAMAGER(g_iLastDamagerPlayer, iKillerId, g_weaponUsedLastDamager)
		PRINTLN(" [CS_EVENTS] SEND_LAST_DAMAGER_EVENT") 
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				FIRST DM KILL													║
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_FIRST_KILL
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iFirstKillPlayer
ENDSTRUCT

PROC BROADCAST_FIRST_KILLER(INT iFirstKillPlayer)
	SCRIPT_EVENT_DATA_FIRST_KILL Event
	Event.Details.Type = SCRIPT_EVENT_FIRST_KILL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iFirstKillPlayer = iFirstKillPlayer
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_FIRST_KILLER iFirstKillPlayer = ", iFirstKillPlayer)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("BROADCAST_FIRST_KILLER - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
ENDPROC

PROC DO_DEATHMATCH_FIRST_KILLER(INT iKillerplayerID)
	// First strike ticker
	IF g_b_On_Deathmatch
		IF NOT IS_BIT_SET(g_sDmGlobalVars.iBitSet, ciDM_GLOBAL_BITSET_FIRST_STRIKE)
			BROADCAST_FIRST_KILLER(iKillerplayerID)
			SET_BIT(g_sDmGlobalVars.iBitSet, ciDM_GLOBAL_BITSET_FIRST_STRIKE)
		ENDIF
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				SCRIPT_EVENT_DM_REWARD_CASH										║
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_DM_REWARD_CASH
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iDeadPlayer
	INT iCashCollected
ENDSTRUCT

PROC BROADCAST_DM_REWARD_CASH(INT iDeadPlayer, INT iCashCollected)
	SCRIPT_EVENT_DATA_DM_REWARD_CASH Event
	Event.Details.Type = SCRIPT_EVENT_DM_REWARD_CASH
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iDeadPlayer = iDeadPlayer
	Event.iCashCollected = iCashCollected
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_DM_REWARD_CASH iDeadPlayer = ", iDeadPlayer)
		PRINTLN("BROADCAST_DM_REWARD_CASH iCashCollected = ", iCashCollected)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("BROADCAST_DM_REWARD_CASH - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				SCRIPT_EVENT_BULLSHARK											║
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_BULLSHARK_COLLECTED
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bCollectedBullshark
ENDSTRUCT

PROC BROADCAST_BULLSHARK_COLLECTED()
	SCRIPT_EVENT_DATA_BULLSHARK_COLLECTED Event
	Event.Details.Type = SCRIPT_EVENT_DM_BULLSHARK
	Event.Details.FromPlayerIndex = PLAYER_ID()
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_BULLSHARK_COLLECTED bCollectedBullshark = TRUE", NATIVE_TO_INT(Event.Details.FromPlayerIndex))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("BROADCAST_BULLSHARK_COLLECTED - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				SCRIPT_EVENT_DM_FINISHED										║
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_DM_FINISH
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bDMFinished
ENDSTRUCT

PROC BROADCAST_SERVER_DM_FINISHED(BOOL bDMFinished)
	SCRIPT_EVENT_DATA_DM_FINISH Event
	Event.Details.Type = SCRIPT_EVENT_DM_FINISHED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bDMFinished = bDMFinished

	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_SERVER_DM_FINISHED ")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("BROADCAST_SERVER_DM_FINISHED - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				SCRIPT_EVENT_RACE_FINISHED										║
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_RACE_FINISH
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bRaceFinished
	INT iTime
	INT iPosix
	FLOAT fAggScore
ENDSTRUCT

PROC BROADCAST_SERVER_RACE_FINISHED(BOOL bRaceFinished, INT iTime, FLOAT fAggScore, INT iPosix)
	SCRIPT_EVENT_DATA_RACE_FINISH Event
	Event.Details.Type = SCRIPT_EVENT_RACE_FINISHED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bRaceFinished = bRaceFinished
	Event.iTime = iTime
	Event.iPosix = iPosix
	Event.fAggScore = fAggScore
	
	#IF IS_DEBUG_BUILD	
		STRING sNameSender = GET_PLAYER_NAME(PLAYER_ID())
		PRINTLN("[CS_FINISH] BROADCAST_SERVER_RACE_FINISHED, ", sNameSender, " has finished the Race iTime = ", Event.iTime, " Event.fAggScore = ", Event.fAggScore, " Event.iPosix = ", Event.iPosix) 
	#ENDIF

	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		PRINTLN("[CS_FULL_UPDATE] BROADCAST_SERVER_RACE_FINISHED ")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("[CS_FULL_UPDATE] BROADCAST_SERVER_RACE_FINISHED - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				SCRIPT_EVENT_NJVS_VOTED											║
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_NJVS_PLAYER_VOTED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iJobVotedFor
	BOOL bVotedYes
ENDSTRUCT

PROC BROADCAST_VOTED_FOR_JOB(INT iJob, BOOL bVotedYes)
	SCRIPT_EVENT_DATA_NJVS_PLAYER_VOTED Event
	Event.Details.Type = SCRIPT_EVENT_RACE_NJVS_VOTED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iJobVotedFor = iJob
	Event.bVotedYes = bVotedYes
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_VOTED_FOR_JOB ")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
		STRING sNameSender = GET_PLAYER_NAME(PLAYER_ID())
		PRINTLN("BROADCAST_VOTED_FOR_JOB, ", sNameSender, " has voted ") 
	ELSE
		PRINTLN("BROADCAST_VOTED_FOR_JOB - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				SCRIPT_EVENT_RALLY_ARROW										║
//╚═════════════════════════════════════════════════════════════════════════════╝

#IF IS_DEBUG_BUILD
FUNC STRING GET_ARROW_DIRECTION_NAME(INT iArrowDirection)
	STRING sArrow
	SWITCH iArrowDirection
		CASE ciRALLY_ARROW_UP 		sArrow = "[CS_ARR] UP " 	BREAK
		CASE ciRALLY_ARROW_DOWN 	sArrow = "[CS_ARR] DOWN " 	BREAK
		CASE ciRALLY_ARROW_LEFT 	sArrow = "[CS_ARR] LEFT " 	BREAK
		CASE ciRALLY_ARROW_RIGHT 	sArrow = "[CS_ARR] RIGHT " 	BREAK
		CASE ciTARGET_ARROW_SPEEDUP 	sArrow = "[CS_ARR] SPEEDUP " 	BREAK
		CASE ciTARGET_ARROW_SLOWDOWN 	sArrow = "[CS_ARR] SLOWDOWN " 	BREAK
		CASE ciTARGET_ARROW_STOP 	sArrow = "[CS_ARR] STOP " 	BREAK
	ENDSWITCH
	
	RETURN sArrow
ENDFUNC
#ENDIF

STRUCT SCRIPT_EVENT_DATA_RALLY_ARROWS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iArrowDirection
	BOOL bButtonHeld
	INT iFrameTime
ENDSTRUCT

PROC BROADCAST_RALLY_ARROW_DIRECTION(INT iArrowDirection, BOOL bButtonHeld = FALSE)
	SCRIPT_EVENT_DATA_RALLY_ARROWS Event
	Event.Details.Type = SCRIPT_EVENT_RACE_RALLY_ARROWS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iArrowDirection = iArrowDirection
	Event.bButtonHeld = bButtonHeld
	Event.iFrameTime = GET_FRAME_COUNT()
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
		STRING sNameSender = GET_PLAYER_NAME(PLAYER_ID())
		PRINTLN("[CS_ARR] BROADCAST_RALLY_ARROW_DIRECTION, ", sNameSender, "  , iArrowDirection =   ", GET_ARROW_DIRECTION_NAME(event.iArrowDirection)) 
	ELSE
		PRINTLN("[CS_ARR] BROADCAST_RALLY_ARROW_DIRECTION - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				remove a car window												║
//╚═════════════════════════════════════════════════════════════════════════════╝

//STRUCT SCRIPT_EVENT_DATA_REMOVE_WINDOW_REQUEST
//	STRUCT_EVENT_COMMON_DETAILS Details
//	SC_WINDOW_LIST WindowToDelete
//ENDSTRUCT

//PROC BROADCAST_REMOVE_WINDOW_REQUEST(SC_WINDOW_LIST eWindow)
//	SCRIPT_EVENT_DATA_REMOVE_WINDOW_REQUEST Event
//
//	Event.Details.Type = SCRIPT_EVENT_REMOVE_WINDOW_REQUEST
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.WindowToDelete = eWindow
//	
//	INT iPlayerFlags
//	iPlayerFlags = ALL_PLAYERS_IN_RANGE(100)
//	IF NOT (iPlayerFlags = 0)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_REMOVE_WINDOW_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF		
//	
//ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				RACE POS														║
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_RACE_POSITION
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iNewPos
	BOOL bEliminated
ENDSTRUCT

PROC BROADCAST_NEW_RACE_POSITION(INT iPos, BOOL bEliminated = FALSE)
	SCRIPT_EVENT_DATA_RACE_POSITION Event
	Event.Details.Type = SCRIPT_EVENT_RACE_POS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iNewPos = iPos
	Event.bEliminated = bEliminated
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_NEW_RACE_POSITION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				HIT A RACE CHECKPOINT											║
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_HIT_CHECKPOINT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iParticipant
	INT iCheckpoint
	INT iTimeThroughCheckpoint
	INT iLap
	INT iPosition
	INT iBestLapTime
	INT iBJPoints
	BOOL bFinishedRace
	BOOL bIsTheDriver
ENDSTRUCT

PROC BROADCAST_RACE_HIT_CHECKPOINT(INT iTimeThroughCheckpoint, INT iParticipant, INT iCheckpoint, INT iLap, INT iPosition, INT iBestLapTime, BOOL bFinishedRace, INT iBJPoints = -1, BOOL bIsTheDriver = TRUE)
	SCRIPT_EVENT_DATA_HIT_CHECKPOINT Event
	Event.Details.Type = SCRIPT_EVENT_HIT_CHECKPOINT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iParticipant = iParticipant
	Event.iCheckpoint = iCheckpoint
	Event.iTimeThroughCheckpoint = iTimeThroughCheckpoint
	Event.iLap = iLap
	Event.bFinishedRace = bFinishedRace
	Event.iPosition = iPosition
	Event.iBestLapTime = iBestLapTime
	Event.iBJPoints = iBJPoints
	Event.bIsTheDriver = bIsTheDriver
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN(" [CS_SPLIT] BROADCAST_RACE_HIT_CHECKPOINT - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
	
	PRINTLN(" [CS_SPLIT] BROADCAST_RACE_HIT_CHECKPOINT ", " Time = ", iTimeThroughCheckpoint, " // PartId = ", iParticipant, " // iCurrentCheckpoint =  ", iCheckpoint,	
			" // iLap = ", iLap, " // iBJPoints = ", iBJPoints, " iPosition = ", iPosition)
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				LAMAR HIT A RACE CHECKPOINT										║
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_LAMAR_HIT_CHECKPOINT
	STRUCT_EVENT_COMMON_DETAILS Details
//	INT iParticipant
	INT iCheckpoint
	INT iTimeThroughCheckpoint
	INT iLap
//	INT iPosition
//	INT iBestLapTime
//	BOOL bFinishedRace
ENDSTRUCT

PROC BROADCAST_LAMAR_HIT_CHECKPOINT(INT iTimeThroughCheckpoint, INT iCheckpoint, INT iLap)
	SCRIPT_EVENT_DATA_LAMAR_HIT_CHECKPOINT Event
	Event.Details.Type = SCRIPT_EVENT_LAMAR_HIT_CHECKPOINT
	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.iParticipant = iParticipant
	Event.iCheckpoint = iCheckpoint
	Event.iTimeThroughCheckpoint = iTimeThroughCheckpoint
	Event.iLap = iLap
//	Event.bFinishedRace = bFinishedRace
//	Event.iPosition = iPosition
//	Event.iBestLapTime = iBestLapTime
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("BROADCAST_LAMAR_HIT_CHECKPOINT - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
	
	PRINTLN("BROADCAST_LAMAR_HIT_CHECKPOINT Time = ", iTimeThroughCheckpoint, "  // iCurrentCheckpoint =  ", iCheckpoint,	" // iLap = ", iLap)
ENDPROC
//╔═════════════════════════════════════════════════════════════════════════════╗
//║				AGGREGATE RACE OVER												║
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_AGGREGATE_RACE_OVER
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPosix
ENDSTRUCT

PROC BROADCAST_AGGREGATE_RACE_OVER(INT iPosix)
	SCRIPT_EVENT_DATA_AGGREGATE_RACE_OVER Event
	Event.Details.Type = SCRIPT_EVENT_AGGREGATE_RACE_OVER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	Event.iPosix = iPosix
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_AGGREGATE_RACE_OVER, Event.iPosix = ", Event.iPosix)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	#IF IS_DEBUG_BUILD	
	ELSE
	#ENDIF
	ENDIF	
	
ENDPROC
//â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—
//â•‘				JOB_INTRO														â•‘
//â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
//╔═════════════════════════════════════════════════════════════════════════════╗
//║				JOB_INTRO														║
//╚═════════════════════════════════════════════════════════════════════════════╝

#IF IS_DEBUG_BUILD

INT iBitSetDebug
CONST_INT ciDEBUG_HOLD 	0
CONST_INT ciDEBUG_NAME 	1
CONST_INT ciDEBUG_RESET 2

#ENDIF

CONST_INT ciJOB_INTRO_HOLD  0
CONST_INT ciJOB_INTRO_NAME  1
CONST_INT ciJOB_INTRO_RESET 2

STRUCT SCRIPT_EVENT_DATA_JOB_INTRO
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iWidget
ENDSTRUCT

PROC PROCESS_JOB_INTRO_EVENT(INT iEventID)
	SCRIPT_EVENT_DATA_JOB_INTRO Event
	IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iEventID, Event, SIZE_OF(Event))	
		IF Event.Details.FromPlayerIndex <> PLAYER_ID()

			#IF IS_DEBUG_BUILD
			
			SWITCH Event.iWidget
				CASE ciJOB_INTRO_HOLD  

					g_DM_Intro_Hold = TRUE
					CLEAR_BIT(iBitSetDebug, ciDEBUG_HOLD)
					PRINTLN("[JB_INT] PROCESS_JOB_INTRO_EVENT , ciDEBUG_HOLD ")

				BREAK
				CASE ciJOB_INTRO_NAME  

					g_DM_Intro_Name_Anim = TRUE
					CLEAR_BIT(iBitSetDebug, ciDEBUG_NAME)
					PRINTLN("[JB_INT] PROCESS_JOB_INTRO_EVENT , ciDEBUG_NAME ")

				BREAK
				CASE ciJOB_INTRO_RESET 

					g_DM_Reset = TRUE
					CLEAR_BIT(iBitSetDebug, ciDEBUG_RESET)
					PRINTLN("[JB_INT] PROCESS_JOB_INTRO_EVENT , ciDEBUG_RESET ")

				BREAK
			ENDSWITCH
			
			PRINTLN("[JB_INT] PROCESS_JOB_INTRO_EVENT , 	RECEIVED ")
			
			#ENDIF
		
		ENDIF
	ENDIF
ENDPROC

PROC BROADCAST_JOB_INTRO(INT iWidget)
	SCRIPT_EVENT_DATA_JOB_INTRO Event
	Event.Details.Type = SCRIPT_EVENT_JOB_INTRO
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iWidget = iWidget
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("[JB_INT] BROADCAST_JOB_INTRO - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
	
	PRINTLN("[JB_INT] BROADCAST_JOB_INTRO FromPlayerIndex = ", NATIVE_TO_INT(Event.Details.FromPlayerIndex), " iWidget = ", iWidget)
ENDPROC

#IF IS_DEBUG_BUILD

PROC MANAGE_JOB_INTRO_EVENT_SENDING()

	PRINTLN("[JB_INT] MANAGE_JOB_INTRO_EVENT_SENDING 1 ")

	IF NOT IS_BIT_SET(iBitSetDebug, ciDEBUG_HOLD)
		IF g_DM_Intro_Hold			
			PRINTLN("[JB_INT] MANAGE_JOB_INTRO_EVENT_SENDING, ciJOB_INTRO_HOLD ")
			BROADCAST_JOB_INTRO(ciJOB_INTRO_HOLD)
			SET_BIT(iBitSetDebug, ciDEBUG_HOLD)
		ENDIF
	ENDIF
	
	IF NOT IS_BIT_SET(iBitSetDebug, ciDEBUG_NAME)
		IF g_DM_Intro_Name_Anim
			PRINTLN("[JB_INT] MANAGE_JOB_INTRO_EVENT_SENDING, ciJOB_INTRO_NAME ")
			BROADCAST_JOB_INTRO(ciJOB_INTRO_NAME)
			SET_BIT(iBitSetDebug, ciDEBUG_NAME)
		ENDIF
	ENDIF
	
	IF NOT IS_BIT_SET(iBitSetDebug, ciDEBUG_RESET)
		IF g_DM_Reset		
			PRINTLN("[JB_INT] MANAGE_JOB_INTRO_EVENT_SENDING, ciJOB_INTRO_RESET ")
			BROADCAST_JOB_INTRO(ciJOB_INTRO_RESET)
			SET_BIT(iBitSetDebug, ciDEBUG_RESET)
		ENDIF
	ENDIF
	
ENDPROC

#ENDIF

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				DEV SPECTATE EVENTS												║
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_DEV_SPECTATOR
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_DEV_SPECTATE_CONTINUE_BUTTON()
	SCRIPT_EVENT_DATA_DEV_SPECTATOR Event
	Event.Details.Type = SCRIPT_EVENT_DEV_SPECTATE_CONTINUE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("[DEV_SPC] BROADCAST_DEV_SPECTATE_CONTINUE_BUTTON - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
	
	PRINTLN("[DEV_SPC] BROADCAST_DEV_SPECTATE_CONTINUE_BUTTON FromPlayerIndex = ", NATIVE_TO_INT(Event.Details.FromPlayerIndex))
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEV_SPECTATOR_LBD
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_DEV_SPECTATE_LBD_CONTINUE_BUTTON()
	SCRIPT_EVENT_DATA_DEV_SPECTATOR_LBD Event
	Event.Details.Type = SCRIPT_EVENT_DEV_SPECTATE_LBD_GO
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("[DEV_SPC] BROADCAST_DEV_SPECTATE_LBD_CONTINUE_BUTTON - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
	
	PRINTLN("[DEV_SPC] BROADCAST_DEV_SPECTATE_LBD_CONTINUE_BUTTON FromPlayerIndex = ", NATIVE_TO_INT(Event.Details.FromPlayerIndex))
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Exclude Player from mission							
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_EXCLUDE_PLAYER
	STRUCT_EVENT_COMMON_DETAILS Details 
	JOINABLE_MP_MISSION_DATA JoinableMission
ENDSTRUCT

//PURPOSE: broadcast a change to the joinable state of a mission
PROC BROADCAST_EXCLUDE_PLAYER_EVENT(JOINABLE_MP_MISSION_DATA JoinEventData)
	SCRIPT_EVENT_DATA_EXCLUDE_PLAYER Event
	Event.Details.Type = SCRIPT_EVENT_EXCLUDE_PLAYER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.JoinableMission = JoinEventData
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_EXCLUDE_PLAYER_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC


STRUCT SCRIPT_EVENT_DATA_SET_LAST_FM_EVENT_VARIATION
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iVariation
ENDSTRUCT

//PURPOSE: broadcast a change to the joinable state of a mission
PROC BROADCAST_SET_LAST_FM_EVENT_VARIATION(INT iVariation)
	SCRIPT_EVENT_DATA_SET_LAST_FM_EVENT_VARIATION Event
	Event.Details.Type = SCRIPT_EVENT_SEND_LAST_FM_EVENT_VARIATION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iVariation = iVariation
	INT iPlayerFlags = ALL_PLAYERS(TRUE) // joinable data gets sent to everyone as anyone can be the server 
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SET_LAST_FM_EVENT_VARIATION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC
//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Join  Script Event 																		
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_AMBIENT_MP_MISSION
	STRUCT_EVENT_COMMON_DETAILS Details 
	MP_MISSION_DATA PreMission
ENDSTRUCT



//PURPOSE: Find the next empty slot in the AMBIENT queue
FUNC INT FIND_EMPTY_SPACE_IN_AMBIENT_QUEUE()
	INT i
	REPEAT MAX_NUM_PRE_GROUP_SCRIPTS i
		IF NOT IS_BIT_SET(g_iPreScriptReadyToLaunch, i)
			RETURN i			
		ENDIF	
	ENDREPEAT

	SCRIPT_ASSERT("FIND_EMPTY_SPACE_IN_AMBIENT_QUEUE, MAX_NUM_PRE_GROUP_SCRIPTS Queue is full.")
	RETURN 0
ENDFUNC


//PURPOSE: Broadcast for players to join this ambient script.  This will not set the script as a main mission. 
PROC BROADCAST_JOIN_THIS_AMBIENT_MP_MISSION_EVENT(MP_MISSION_DATA JoinPreMissionEventData, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_AMBIENT_MP_MISSION Event
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.PreMission = JoinPreMissionEventData
	IF ARE_VECTORS_EQUAL(Event.PreMission.mdSecondaryCoords, <<0.0, 0.0, 0.0>>)
	OR ARE_VECTORS_EQUAL(Event.PreMission.mdPrimaryCoords, <<0.0, 0.0, 0.0>>)
		FILL_IN_LOCATION_MISSION_DATA(Event.PreMission.mdID.idMission, iPlayerFlags, Event.PreMission.mdSecondaryCoords, Event.PreMission.mdPrimaryCoords)
	ENDIF
	IF NOT (iPlayerFlags = 0)
		IF (Event.PreMission.mdID.idMission = eAM_CRATE_DROP)
			IF (GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(HASH("AM_CRATE_DROP")) > 0)
				#IF IS_DEBUG_BUILD	NET_PRINT("...KGM MP: QUICK WORKAROUND FIX TO ENSURE CRATE DROP DOESN'T LAUNCH TWICE ON SAME MACHINE") NET_NL()	#ENDIF
				EXIT
			ENDIF
		ENDIF
		
		//Find a spare queue slot and fill it with data
		INT i = FIND_EMPTY_SPACE_IN_AMBIENT_QUEUE()

		//This will now launch the script in MAINTAIN_SCRIPT_LAUNCH
		MPGlobalsEvents.PreMissionScriptData[i] = Event.PreMission
			
		NET_PRINT_STRING_INT("PROCESS_JOIN_AMBIENT_SCRIPT_EVENT queued in: ", i)
		NET_PRINT("   [Script: ")
		NET_PRINT(GET_MP_MISSION_NAME(MPGlobalsEvents.PreMissionScriptData[i].mdID.idMission))
		NET_PRINT("  Instance: ")
		NET_PRINT_INT(MPGlobalsEvents.PreMissionScriptData[i].iInstanceId)
		NET_PRINT("]")
		NET_NL()
		SET_BIT(g_iPreScriptReadyToLaunch, i)
	ELSE
		NET_PRINT("BROADCAST_AMBIENT_SCRIPT_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Invite to join script																		
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_INVITE_TO_MP_MISSION
	STRUCT_EVENT_COMMON_DETAILS Details 
	MP_MISSION_DATA ScriptData
ENDSTRUCT

//PURPOSE: Broadcast for players to join a script. 
PROC BROADCAST_INVITE_TO_JOIN_MP_MISSION(MP_MISSION_DATA JoinScriptData, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_INVITE_TO_MP_MISSION Event
	Event.Details.Type = SCRIPT_EVENT_INVITE_TO_JOIN_MP_MISSION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.ScriptData = JoinScriptData
	IF ARE_VECTORS_EQUAL(Event.ScriptData.mdSecondaryCoords, <<0.0, 0.0, 0.0>>)
	OR ARE_VECTORS_EQUAL(Event.ScriptData.mdPrimaryCoords, <<0.0, 0.0, 0.0>>)
		FILL_IN_LOCATION_MISSION_DATA(Event.ScriptData.mdID.idMission, iPlayerFlags, Event.ScriptData.mdSecondaryCoords, Event.ScriptData.mdPrimaryCoords)
	ENDIF
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_INVITE_TO_JOIN_MP_MISSION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║						Give Player Cash from Last Job																		
//╚═════════════════════════════════════════════════════════════════════════════╝

PROC BROADCAST_GIVE_PLAYER_CASH_FROM_LAST_JOB(PLAYER_INDEX PlayerID, INT iCash, BOOL banimate = TRUE , BOOL bIsBossCut = FALSE )

	IF IS_NET_PLAYER_OK(PlayerID, FALSE, TRUE)
		SCRIPT_EVENT_DATA_GIVE_PLAYER_CASH_FROM_LAST_JOB Event
		
		Event.iType  = ENUM_TO_INT(SCRIPT_EVENT_GIVE_PLAYER_CASH_FROM_LAST_JOB)
		Event.FromPlayerIndex = PLAYER_ID()
		Event.iCashToGive = iCash
		Event.banimate = banimate
		Event.bBossCut = bIsBossCut
		Event.iUniquePlayersHash = GET_THIS_PLAYER_UNIQUE_EVENT_ID(PlayerID)
		GET_THIS_SESSION_UNIQUE_EVENT_IDS(Event.iUniqueSessionHash0, Event.iUniqueSessionHash1)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerID))
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_GIVE_PLAYER_CASH_FROM_LAST_JOB - SENT TO - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_GIVE_PLAYER_CASH_FROM_LAST_JOB - PLAYER NOT OKAY - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
	ENDIF

ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				Give Player Refund from Sharing Cash from Last Job																		
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_GIVE_PLAYER_REFUND_FROM_LAST_JOB
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iRefundToGive
	INT iUniquePlayersHash
ENDSTRUCT

//PROC BROADCAST_GIVE_PLAYER_REFUND_FROM_LAST_JOB(PLAYER_INDEX PlayerID, INT iRefund)
//
//	IF IS_NET_PLAYER_OK(PlayerID, FALSE, TRUE)
//		SCRIPT_EVENT_DATA_GIVE_PLAYER_REFUND_FROM_LAST_JOB Event
//		
//		Event.Details.Type  = SCRIPT_EVENT_GIVE_PLAYER_REFUND_FROM_LAST_JOB
//		Event.Details.FromPlayerIndex = PLAYER_ID()
//		Event.iRefundToGive = iRefund
//		Event.iUniquePlayersHash = GET_THIS_PLAYER_UNIQUE_EVENT_ID(PlayerID)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerID))
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_GIVE_PLAYER_REFUND_FROM_LAST_JOB - SENT TO - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_GIVE_PLAYER_REFUND_FROM_LAST_JOB - REFUND = $") NET_PRINT_INT(Event.iRefundToGive) NET_NL()
//	ELSE
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_GIVE_PLAYER_REFUND_FROM_LAST_JOB - PLAYER NOT OKAY - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//	ENDIF
//
//ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Give Player Item																		
//╚═════════════════════════════════════════════════════════════════════════════╝
//STRUCT SCRIPT_EVENT_DATA_GIVE_PLAYER_ITEM
//	STRUCT_EVENT_COMMON_DETAILS Details 
//	FLOAT fAmount
//	INT iAmountEVC
//	INT iAmountPVC
//	FLOAT fAmountUSDE
//	INT iItemType
//	BOOL banimate
//ENDSTRUCT
//
//PROC BROADCAST_GIVE_PLAYER_ITEM(PLAYER_INDEX PlayerID, FLOAT fAmount, INT iItemType, BOOL banimate = TRUE, INT iEVC = 0, INT iPVC = 0, FLOAT fUSDE = 0.0)
//
//	IF IS_NET_PLAYER_OK(PlayerID, FALSE, TRUE)
//		SCRIPT_EVENT_DATA_GIVE_PLAYER_ITEM Event
//		
//		Event.Details.Type  = SCRIPT_EVENT_GIVE_PLAYER_ITEM
//		Event.Details.FromPlayerIndex = PLAYER_ID()
//		Event.fAmount = fAmount
//		Event.iItemType = iItemType
//		Event.banimate = banimate
//		Event.iAmountEVC = iEVC
//		Event.iAmountPVC = iPVC
//		Event.fAmountUSDE = fUSDE
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerID))
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_GIVE_PLAYER_ITEM - SENT TO - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//		PRINTLN("     ---------->     BROADCAST_RECEIVED_PLAYER_ITEM - fAmount = ", fAmount)
//		PRINTLN("     ---------->     BROADCAST_RECEIVED_PLAYER_ITEM - iEVC = ", iEVC)
//		PRINTLN("     ---------->     BROADCAST_RECEIVED_PLAYER_ITEM - iPVC = ", iPVC)
//		PRINTLN("     ---------->     BROADCAST_RECEIVED_PLAYER_ITEM - fUSDE = ", fUSDE)
//	ELSE
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_GIVE_PLAYER_ITEM - PLAYER NOT OKAY - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//	ENDIF
//
//ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Received Player Item																		
//╚═════════════════════════════════════════════════════════════════════════════╝
//STRUCT SCRIPT_EVENT_DATA_RECEIVED_PLAYER_ITEM
//	STRUCT_EVENT_COMMON_DETAILS Details 
//	BOOL bReceived
//ENDSTRUCT
//
//PROC BROADCAST_RECEIVED_PLAYER_ITEM(PLAYER_INDEX PlayerID, BOOL bReceived)
//
//	IF IS_NET_PLAYER_OK(PlayerID, FALSE, TRUE)
//		SCRIPT_EVENT_DATA_RECEIVED_PLAYER_ITEM Event
//		
//		Event.Details.Type  = SCRIPT_EVENT_RECEIVED_PLAYER_ITEM
//		Event.Details.FromPlayerIndex = PLAYER_ID()
//		Event.bReceived = bReceived
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerID))
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_RECEIVED_PLAYER_ITEM - SENT TO - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//		PRINTLN("     ---------->     BROADCAST_RECEIVED_PLAYER_ITEM - bReceived = ", bReceived)
//	ELSE
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_RECEIVED_PLAYER_ITEM - PLAYER NOT OKAY - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//	ENDIF
//
//ENDPROC

////╔═════════════════════════════════════════════════════════════════════════════╗
////║							Send Buddy Request																		
////╚═════════════════════════════════════════════════════════════════════════════╝
//STRUCT SCRIPT_EVENT_DATA_BUDDY_REQUEST
//	STRUCT_EVENT_COMMON_DETAILS Details
//ENDSTRUCT
//
//PROC BROADCAST_BUDDY_REQUEST(PLAYER_INDEX PlayerID)
//
//	IF IS_NET_PLAYER_OK(PlayerID, FALSE, TRUE)
//		SCRIPT_EVENT_DATA_BUDDY_REQUEST Event
//		
//		Event.Details.Type  = SCRIPT_EVENT_BUDDY_REQUEST
//		Event.Details.FromPlayerIndex = PLAYER_ID()
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerID))	
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_BUDDY_REQUEST - SENT TO - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//	ELSE
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_BUDDY_REQUEST - PLAYER NOT OKAY - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//	ENDIF
//
//ENDPROC
//
////╔═════════════════════════════════════════════════════════════════════════════╗
////║							Send Buddy Accept																		
////╚═════════════════════════════════════════════════════════════════════════════╝
//STRUCT SCRIPT_EVENT_DATA_BUDDY_ACCEPT
//	STRUCT_EVENT_COMMON_DETAILS Details
//ENDSTRUCT
//
//PROC BROADCAST_BUDDY_ACCEPT(PLAYER_INDEX PlayerID)
//
//	IF IS_NET_PLAYER_OK(PlayerID, FALSE, TRUE)
//		SCRIPT_EVENT_DATA_BUDDY_ACCEPT Event
//		
//		Event.Details.Type  = SCRIPT_EVENT_BUDDY_ACCEPT
//		Event.Details.FromPlayerIndex = PLAYER_ID()
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerID))	
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_BUDDY_ACCEPT - SENT TO - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//	ELSE
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_BUDDY_ACCEPT - PLAYER NOT OKAY - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//	ENDIF
//
//ENDPROC
//
////╔═════════════════════════════════════════════════════════════════════════════╗
////║							Send Buddy Removal																		
////╚═════════════════════════════════════════════════════════════════════════════╝
//STRUCT SCRIPT_EVENT_DATA_BUDDY_REMOVAL
//	STRUCT_EVENT_COMMON_DETAILS Details
//ENDSTRUCT
//
//PROC BROADCAST_BUDDY_REMOVAL(PLAYER_INDEX PlayerID)
//
//	IF IS_NET_PLAYER_OK(PlayerID, FALSE, TRUE)
//		SCRIPT_EVENT_DATA_BUDDY_REMOVAL Event
//		
//		Event.Details.Type  = SCRIPT_EVENT_BUDDY_REMOVAL
//		Event.Details.FromPlayerIndex = PLAYER_ID()
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerID))	
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_BUDDY_REMOVAL - SENT TO - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//	ELSE
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_BUDDY_REMOVAL - PLAYER NOT OKAY - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//	ENDIF
//
//ENDPROC
//
////╔═════════════════════════════════════════════════════════════════════════════╗
////║							Send Still Buddy Check																		
////╚═════════════════════════════════════════════════════════════════════════════╝
//STRUCT SCRIPT_EVENT_DATA_STILL_BUDDY_CHECK
//	STRUCT_EVENT_COMMON_DETAILS Details
//ENDSTRUCT
//
//PROC BROADCAST_STILL_BUDDY_CHECK(PLAYER_INDEX PlayerID)
//
//	//IF IS_NET_PLAYER_OK(PlayerID, FALSE, TRUE)
//		SCRIPT_EVENT_DATA_STILL_BUDDY_CHECK Event
//		
//		Event.Details.Type  = SCRIPT_EVENT_STILL_BUDDY_CHECK
//		Event.Details.FromPlayerIndex = PLAYER_ID()
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerID))	
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_STILL_BUDDY_CHECK - SENT TO - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//	//ELSE
//	//	NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_STILL_BUDDY_CHECK - PLAYER NOT OKAY - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//	//ENDIF
//
//ENDPROC
//
////╔═════════════════════════════════════════════════════════════════════════════╗
////║							Send Still Buddy Response																		
////╚═════════════════════════════════════════════════════════════════════════════╝
//STRUCT SCRIPT_EVENT_DATA_STILL_BUDDY_RESPONSE
//	STRUCT_EVENT_COMMON_DETAILS Details
//	BOOL bStillBuddy = FALSE
//ENDSTRUCT
//
//PROC BROADCAST_STILL_BUDDY_RESPONSE(PLAYER_INDEX PlayerID, BOOL bStillBuddy)
//
//	//IF IS_NET_PLAYER_OK(PlayerID, FALSE, TRUE)
//		SCRIPT_EVENT_DATA_STILL_BUDDY_RESPONSE Event
//		
//		Event.Details.Type  = SCRIPT_EVENT_STILL_BUDDY_RESPONSE
//		Event.Details.FromPlayerIndex = PLAYER_ID()
//		Event.bStillBuddy = bStillBuddy
//		
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerID))
//		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_STILL_BUDDY_RESPONSE - SENT TO - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//	//ELSE
//	//	NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_STILL_BUDDY_RESPONSE - PLAYER NOT OKAY - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
//	//ENDIF
//
//ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Set Players as Partners																		
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_MAKE_PLAYERS_PARTNERS
	STRUCT_EVENT_COMMON_DETAILS Details 
	PLAYER_INDEX PlayerID1
	PLAYER_INDEX PlayerID2
ENDSTRUCT

PROC BROADCAST_MAKE_PLAYERS_PARTNERS(PLAYER_INDEX PlayerID1, PLAYER_INDEX PlayerID2)

	IF IS_NET_PLAYER_OK(PlayerID1, FALSE, TRUE)
		IF IS_NET_PLAYER_OK(PlayerID2, FALSE, TRUE)
			
			SCRIPT_EVENT_DATA_MAKE_PLAYERS_PARTNERS Event
			
			Event.Details.Type  = SCRIPT_EVENT_MAKE_PLAYERS_PARTNERS
			Event.Details.FromPlayerIndex = PLAYER_ID()
			Event.PlayerID1 = PlayerID1
			Event.PlayerID2 = PlayerID2
			
			
			INT iPlayerFlags = ALL_PLAYERS(TRUE) // any player could be the host 
			IF NOT (iPlayerFlags = 0)
				SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
			ELSE
				NET_PRINT("BROADCAST_MAKE_PLAYERS_PARTNERS - playerflags = 0 so not broadcasting") NET_NL()		
			ENDIF	
		
		ELSE
			SCRIPT_ASSERT("BROADCAST_MAKE_PLAYERS_PARTNERS - playerID2 not ok")
		ENDIF
	ELSE
		SCRIPT_ASSERT("BROADCAST_MAKE_PLAYERS_PARTNERS - playerID1 not ok")
	ENDIF

ENDPROC



//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Cop Mission Launch Event   										║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════

STRUCT SCRIPT_EVENT_DATA_LAUNCH_TIMED_COP_MISSION
	STRUCT_EVENT_COMMON_DETAILS Details 
	MP_MISSION_DATA CopMission
ENDSTRUCT

//PURPOSE: broadcast a change to the joinable state of a mission
PROC BROADCAST_LAUNCH_TIMED_COP_MISSION_EVENT(MP_MISSION_DATA LaunchTimedCopMissionEventData, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_LAUNCH_TIMED_COP_MISSION Event
	Event.Details.Type = SCRIPT_EVENT_LAUNCH_TIMED_COP_MISSION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.CopMission = LaunchTimedCopMissionEventData
	IF ARE_VECTORS_EQUAL(Event.CopMission.mdSecondaryCoords, <<0.0, 0.0, 0.0>>)
	OR ARE_VECTORS_EQUAL(Event.CopMission.mdPrimaryCoords, <<0.0, 0.0, 0.0>>)
		FILL_IN_LOCATION_MISSION_DATA(Event.CopMission.mdID.idMission, iPlayerFlags, Event.CopMission.mdSecondaryCoords, Event.CopMission.mdPrimaryCoords)
	ENDIF
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_LAUNCH_TIMED_COP_MISSION_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Tell People to swap map object	- bobby wright																					
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_SWAP_MAP_OBJECT
	STRUCT_EVENT_COMMON_DETAILS 	Details 
	enumMP_SWAPPING_MAP_OBJECTS	eObjectToSwap
	BOOL 							bState
	BOOL 							bForce
ENDSTRUCT
/// PURPOSE:Bordcasts the swapping of a map object
/// PARAMS:
///    eObjectToSwap - the object that is to be swapped
///    bSwapState - the state to set of the swapped object
PROC BROADCAST_SWAP_MAP_OBJECT(enumMP_SWAPPING_MAP_OBJECTS eObjectToSwap, BOOL bSwapState = TRUE, BOOL bForce = FALSE) 
	SCRIPT_EVENT_DATA_SWAP_MAP_OBJECT Event
	Event.Details.Type 				= SCRIPT_EVENT_SWAP_MAP_OBJECT
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.eObjectToSwap 			= eObjectToSwap
	Event.bState 					= bSwapState 	
	Event.bForce 					= bForce 		
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					send query to see if start spawn point is ok																						
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_QUERY_SPECIFIC_SPAWN_POINT
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vPos
ENDSTRUCT

PROC BROADCAST_QUERY_SPECIFIC_SPAWN_POINT(VECTOR vPosition)
	SCRIPT_EVENT_DATA_QUERY_SPECIFIC_SPAWN_POINT Event
	Event.Details.Type = SCRIPT_EVENT_QUERY_SPECIFIC_SPAWN_POINT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vPos = vPosition
	#IF IS_DEBUG_BUILD
		NET_PRINT("BROADCAST_QUERY_SPECIFIC_SPAWN_POINT - coords = ") NET_PRINT_VECTOR(vPosition) NET_NL()
	#ENDIF	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Request to server to warp to location																						
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_REQUEST_TO_WARP
	STRUCT_EVENT_COMMON_DETAILS Details
	SPAWN_RESULTS SpawnResults
	INT iRequestToWarpID
	FLOAT fMinEnemyDist
	BOOL bReturnFirstAvailablePoint
	MODEL_NAMES ModelName
ENDSTRUCT


#IF IS_DEBUG_BUILD
PROC PRINT_EVENT_DATA_REQUEST_TO_WARP(SCRIPT_EVENT_DATA_REQUEST_TO_WARP &Data)
	PRINTLN("EVENT_DATA_REQUEST_TO_WARP - details:")
	PRINTLN("   Details.Type = ", ENUM_TO_INT(Data.Details.Type))
	PRINTLN("   Details.FromPlayerIndex = ", NATIVE_TO_INT(Data.Details.FromPlayerIndex))
	INT i
	REPEAT NUM_OF_STORED_SPAWN_RESULTS i
		PRINTLN("   SpawnResults.vCoords[", i, "] = ", Data.SpawnResults.vCoords[i], " SpawnResults.fHeading[", i, "]", Data.SpawnResults.fHeading[i], " SpawnResults.iScore[", i, "] = ", Data.SpawnResults.iScore[i] , " SpawnResults.fNearestEnemy[", i, "] = ", Data.SpawnResults.fNearestEnemy[i])
	ENDREPEAT
	PRINTLN("   iRequestToWarpID = ", Data.iRequestToWarpID)
	PRINTLN("   fMinEnemyDist = ", Data.fMinEnemyDist)
	PRINTLN("	bReturnFirstAvailablePoint = ", Data.bReturnFirstAvailablePoint)
	PRINTLN("   ModelName = ", ENUM_TO_INT(Data.ModelName))
ENDPROC
#ENDIF


FUNC INT GetRequestToWarpID(SPAWN_RESULTS &SpawnResults, FLOAT &fMinEnemyDist, BOOL &bReturnFirstAvailablePoint, MODEL_NAMES &ModelName)
	TEXT_LABEL_63 str
	str = ""
	INT i
	VECTOR vCoordsTotal
	FLOAT fHeadingTotal
	INT iScoreTotal
	REPEAT NUM_OF_STORED_SPAWN_RESULTS i
		vCoordsTotal.x += SpawnResults.vCoords[i].x
		vCoordsTotal.y += SpawnResults.vCoords[i].y
		vCoordsTotal.z += SpawnResults.vCoords[i].z
		fHeadingTotal += SpawnResults.fHeading[i]
		iScoreTotal += SpawnResults.iScore[i]
	ENDREPEAT
	
	str += ROUND(vCoordsTotal.x)
	str += ROUND(vCoordsTotal.y)
	str += ROUND(vCoordsTotal.z)
	str += ROUND(fHeadingTotal)
	str += iScoreTotal
	str += ROUND(fMinEnemyDist)
	IF (bReturnFirstAvailablePoint)
		str += 1
	ELSE
		str += 0
	ENDIF
	str += ENUM_TO_INT(ModelName)

	INT iHash = GET_HASH_KEY(str)
	PRINTLN("[spawning] GetRequestToWarpID - ", str, ", iHash = ", iHash)
	RETURN iHash
ENDFUNC

PROC BROADCAST_REQUEST_TO_WARP(SPAWN_RESULTS SpawnResults, INT &iRequestID, FLOAT fMinEnemyDist, BOOL bReturnFirstAvailablePoint = FALSE, MODEL_NAMES ModelName=DUMMY_MODEL_FOR_SCRIPT)
	
	iRequestID = GetRequestToWarpID(SpawnResults, fMinEnemyDist, bReturnFirstAvailablePoint, ModelName)
	
	SCRIPT_EVENT_DATA_REQUEST_TO_WARP Event
	Event.Details.Type = SCRIPT_EVENT_REQUEST_TO_WARP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	INT i
	REPEAT NUM_OF_STORED_SPAWN_RESULTS i
		Event.SpawnResults.vCoords[i] = SpawnResults.vCoords[i]
		Event.SpawnResults.iScore[i] = SpawnResults.iScore[i]
		Event.SpawnResults.fHeading[i] = SpawnResults.fHeading[i]
		Event.SpawnResults.fNearestEnemy[i] = SpawnResults.fNearestEnemy[i]
	ENDREPEAT
	Event.iRequestToWarpID = iRequestID
	Event.fMinEnemyDist = fMinEnemyDist
	Event.bReturnFirstAvailablePoint = bReturnFirstAvailablePoint
	Event.ModelName = ModelName
	#IF IS_DEBUG_BUILD
		PRINTLN("BROADCAST_REQUEST_TO_WARP:") 
		PRINT_EVENT_DATA_REQUEST_TO_WARP(Event)
	#ENDIF	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC




//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Response from server to warp to location																						
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_RESPONSE_TO_WARP
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bServerSaidYes 
	INT iSlot
	INT iResponseToWarpID
	#IF IS_DEBUG_BUILD
		INT iWarpRequest
	#ENDIF
ENDSTRUCT

PROC BROADCAST_RESPONSE_TO_WARP(PLAYER_INDEX PlayerToSendTo, BOOL bServerSaidYes, INT iSlot, INT iResponseID)

	SCRIPT_EVENT_DATA_RESPONSE_TO_WARP Event
	Event.Details.Type = SCRIPT_EVENT_RESPONSE_TO_WARP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bServerSaidYes = bServerSaidYes
	Event.iSlot = iSlot
	Event.iResponseToWarpID = iResponseID
	#IF IS_DEBUG_BUILD
		Event.iWarpRequest = GlobalServerBD.iWarpRequest		
		IF (bServerSaidYes)
			NET_PRINT("BROADCAST_RESPONSE_TO_WARP - Yes! - Player = ") NET_PRINT_INT(NATIVE_TO_INT(PlayerToSendTo)) NET_NL()
		ELSE
			NET_PRINT("BROADCAST_RESPONSE_TO_WARP - No - Player = ") NET_PRINT_INT(NATIVE_TO_INT(PlayerToSendTo)) NET_NL()
		ENDIF
	#ENDIF

	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerToSendTo))
	
ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Request to server to warp to into vehicle																						
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_REQUEST_TO_WARP_INTO_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iRespawnVehicleID
	INT iSeat
ENDSTRUCT

PROC BROADCAST_REQUEST_TO_WARP_INTO_VEHICLE(VEHICLE_INDEX VehicleID, INT iSeat)

	IF DOES_ENTITY_EXIST(VehicleID)
	AND NOT IS_ENTITY_DEAD(VehicleID)		
		IF DECOR_EXIST_ON(VehicleID, "RespawnVeh")
		
			SCRIPT_EVENT_DATA_REQUEST_TO_WARP_INTO_VEHICLE Event
			Event.Details.Type = SCRIPT_EVENT_REQUEST_TO_WARP_INTO_VEHICLE
			Event.Details.FromPlayerIndex = PLAYER_ID()			
			Event.iRespawnVehicleID = DECOR_GET_INT(VehicleID, "RespawnVeh")
			Event.iSeat = iSeat
			
			#IF IS_DEBUG_BUILD
				PRINTLN("[spawning] BROADCAST_REQUEST_TO_WARP_INTO_VEHICLE - Event.iRespawnVehicleID = ", Event.iRespawnVehicleID, ", Event.iSeat = ", Event.iSeat) 
			#ENDIF	
			
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
		
		ELSE
			ASSERTLN("BROADCAST_REQUEST_TO_WARP_INTO_VEHICLE - vehicle doesn't have respawn decorator. Has SET_VEHICLE_AS_A_SPECIFIC_RESPAWN_VEHICLE been called?")
		ENDIF		
	ENDIF
	

ENDPROC




//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Response from server to warp into vehicle																						
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_RESPONSE_TO_WARP_INTO_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bServerSaidYes 
ENDSTRUCT

PROC BROADCAST_RESPONSE_TO_WARP_INTO_VEHICLE(PLAYER_INDEX PlayerToSendTo, BOOL bServerSaidYes)
	SCRIPT_EVENT_DATA_RESPONSE_TO_WARP_INTO_VEHICLE Event
	Event.Details.Type = SCRIPT_EVENT_RESPONSE_TO_WARP_INTO_VEHICLE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bServerSaidYes = bServerSaidYes
	#IF IS_DEBUG_BUILD		
		IF (bServerSaidYes)
			NET_PRINT("BROADCAST_RESPONSE_TO_WARP_INTO_VEHICLE - Yes! - Player = ") NET_PRINT_INT(NATIVE_TO_INT(PlayerToSendTo)) NET_NL()
		ELSE
			NET_PRINT("BROADCAST_RESPONSE_TO_WARP_INTO_VEHICLE - No - Player = ") NET_PRINT_INT(NATIVE_TO_INT(PlayerToSendTo)) NET_NL()
		ENDIF
	#ENDIF
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerToSendTo))
ENDPROC




//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Request to server to spawn vehicle																						
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_REQUEST_TO_SPAWN_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vPos
	FLOAT fHeading
	MODEL_NAMES VehicleModel
	INT iRequestToSpawnID
ENDSTRUCT

FUNC INT GetRequestToVehicleSpawnID(VECTOR &vCoords, FLOAT &fHeading, MODEL_NAMES &CarModel)
	TEXT_LABEL_63 str
	str = ""
	str += ROUND(vCoords.x)
	str += ROUND(vCoords.y)
	str += ROUND(vCoords.z)
	str += ROUND(fHeading)
	str += ENUM_TO_INT(CarModel)
	INT iHash = GET_HASH_KEY(str)
	PRINTLN("[spawning] GetRequestToVehicleSpawnID - ", str, ", iHash = ", iHash)
	RETURN iHash
ENDFUNC

PROC BROADCAST_REQUEST_TO_SPAWN_SAVED_VEHICLE(VECTOR vPosition, FLOAT fHeading, MODEL_NAMES vehModel, INT &iRequestID)

	iRequestID = GetRequestToVehicleSpawnID(vPosition, fHeading, vehModel)

	SCRIPT_EVENT_DATA_REQUEST_TO_SPAWN_VEHICLE Event
	Event.Details.Type = SCRIPT_EVENT_REQUEST_TO_SPAWN_VEHICLE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vPos = vPosition
	Event.fHeading = fHeading
	Event.VehicleModel = vehModel
	Event.iRequestToSpawnID = iRequestID
	#IF IS_DEBUG_BUILD
		STRING strModel 
		IF IS_MODEL_IN_CDIMAGE(vehModel)
			strModel = GET_SAFE_MODEL_NAME_FOR_DEBUG(vehModel)
			PRINTLN("BROADCAST_REQUEST_TO_SPAWN_SAVED_VEHICLE - ", vPosition, ", ", fHeading, ", ", strModel, ", iRequestID = ", iRequestID)
		ELSE
			PRINTLN("BROADCAST_REQUEST_TO_SPAWN_SAVED_VEHICLE - ", vPosition, ", ", fHeading, ", ", vehModel, ", iRequestID = ", iRequestID)
		ENDIF
		
	#ENDIF
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

FUNC INT GetPlayerVehicleSpawnRequest(PLAYER_INDEX PlayerID, VECTOR vPos, MODEL_NAMES ModelName)
	
	INT iPlayer = NATIVE_TO_INT(PlayerID)
	INT i
	VECTOR vTempPos
	
	PRINTLN("DoesPlayerHaveVehicleSpawnRequest, called with player ", NATIVE_TO_INT(PlayerID), ", vPos = ", vPos, " ModelName = ", ENUM_TO_INT(ModelName))
	
	IF (iPlayer > -1)
		REPEAT NUM_SERVER_STORED_VEH_REQUESTS i
			// is it the same model name?
			IF (GlobalServerBD.g_VehSpawnReqData[iPlayer][i].ModelName = ModelName)			
				vTempPos = vPos			
				// ignore z if diff is less than 2
				IF (ABSF(GlobalServerBD.g_VehSpawnReqData[iPlayer][i].vPos.z - vTempPos.z) < 2.0)
					PRINTLN("DoesPlayerHaveVehicleSpawnRequest, ignoring z diff")
					vTempPos.z = GlobalServerBD.g_VehSpawnReqData[iPlayer][i].vPos.z
				ENDIF				
				IF (VDIST(GlobalServerBD.g_VehSpawnReqData[iPlayer][i].vPos, vTempPos) < 0.5)					
					PRINTLN("DoesPlayerHaveVehicleSpawnRequest, returning ", i)
					RETURN i				
				ENDIF				
			ENDIF			
		ENDREPEAT
	ENDIF
	PRINTLN("DoesPlayerHaveVehicleSpawnRequest, returning -1")
	RETURN -1
ENDFUNC

PROC BROADCAST_CLEAR_SPAWN_VEHICLE_REQUEST(VECTOR vPosition, FLOAT fHeading, MODEL_NAMES vehModel)

	IF (GetPlayerVehicleSpawnRequest(PLAYER_ID(), vPosition, vehModel) > -1)
		SCRIPT_EVENT_DATA_REQUEST_TO_SPAWN_VEHICLE Event
		Event.Details.Type = SCRIPT_EVENT_CLEAR_SPAWN_VEHICLE_REQUEST
		Event.Details.FromPlayerIndex = PLAYER_ID()
		Event.vPos = vPosition
		Event.fHeading = fHeading
		Event.VehicleModel = vehModel
		
		#IF IS_DEBUG_BUILD
			STRING strModel 
			IF IS_MODEL_IN_CDIMAGE(vehModel)
				strModel = GET_SAFE_MODEL_NAME_FOR_DEBUG(vehModel)
				PRINTLN("BROADCAST_CLEAR_SPAWN_VEHICLE_REQUEST - ", vPosition, ", ", fHeading, ", ", strModel)
			ELSE
				PRINTLN("BROADCAST_CLEAR_SPAWN_VEHICLE_REQUEST - ", vPosition, ", ", fHeading, ", ", vehModel)
			ENDIF
			
		#ENDIF
		
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
		
	ELSE
		PRINTLN("BROADCAST_CLEAR_SPAWN_VEHICLE_REQUEST - player does not have a spawn vehicle request here!")
	ENDIF
ENDPROC





//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Response from server to warp to location																						
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_RESPONSE_TO_SPAWN_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bServerSaidYes 
	INT iResponseToSpawnID
ENDSTRUCT

PROC BROADCAST_RESPONSE_TO_SPAWN_VEHICLE(PLAYER_INDEX PlayerToSendTo, BOOL bServerSaidYes, INT iResponseID)
	IF IS_NET_PLAYER_OK(PlayerToSendTo, FALSE, FALSE)
		SCRIPT_EVENT_DATA_RESPONSE_TO_SPAWN_VEHICLE Event
		Event.Details.Type = SCRIPT_EVENT_RESPONSE_TO_SPAWN_VEHICLE
		Event.Details.FromPlayerIndex = PLAYER_ID()
		Event.bServerSaidYes = bServerSaidYes
		Event.iResponseToSpawnID = iResponseID
		#IF IS_DEBUG_BUILD			
			IF (bServerSaidYes)
				PRINTLN("BROADCAST_RESPONSE_TO_SPAWN_VEHICLE - Yes! - Player ", NATIVE_TO_INT(PlayerToSendTo), ", iResponseID ", iResponseID)
			ELSE
				PRINTLN("BROADCAST_RESPONSE_TO_SPAWN_VEHICLE - NO - Player ", NATIVE_TO_INT(PlayerToSendTo), ", iResponseID ", iResponseID)
			ENDIF						
		#ENDIF
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerToSendTo))
	ELSE
		NET_PRINT("BROADCAST_RESPONSE_TO_SPAWN_VEHICLE - player is no longer active = ") NET_PRINT_INT(NATIVE_TO_INT(PlayerToSendTo)) NET_NL()
	ENDIF
ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Personal vehicle has been created																						
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_SET
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iSlot = -1
ENDSTRUCT

PROC BROADCAST_PERSONAL_VEHICLE_SET(INT iSlot)
	SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_SET Event
	Event.Details.Type = SCRIPT_EVENT_PERSONAL_VEHICLE_SET
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iSlot = iSlot
	#IF IS_DEBUG_BUILD
		NET_PRINT("BROADCAST_PERSONAL_VEHICLE_SET - iSlot = ") NET_PRINT_INT(iSlot) NET_NL()
	#ENDIF
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC



//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Invite to join ambient script																		
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_INVITE_TO_AMBIENT_SCRIPT
	STRUCT_EVENT_COMMON_DETAILS Details 
	MP_MISSION_DATA ScriptData
ENDSTRUCT

//PURPOSE: Broadcast for players to join a script. 
PROC BROADCAST_INVITE_TO_JOIN_AMBIENT_SCRIPT(MP_MISSION_DATA JoinScriptData, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_INVITE_TO_AMBIENT_SCRIPT Event
	Event.Details.Type = SCRIPT_EVENT_INVITE_TO_JOIN_AMBIENT_SCRIPT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.ScriptData = JoinScriptData
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_INVITE_TO_JOIN_AMBIENT_SCRIPT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Join script if not on script																		
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_JOIN_SCRIPT_IF_NOT_ON_SCRIPT
	STRUCT_EVENT_COMMON_DETAILS Details 
	MP_MISSION_DATA ScriptData
	BOOL bAskIfPlayerWantsToJoin
	BOOL tempUseMissionTrigger
ENDSTRUCT

//PURPOSE: Broadcast for players to join a script. 
PROC BROADCAST_JOIN_SCRIPT_IF_NOT_ON_SCRIPT(MP_MISSION_DATA JoinScriptData, BOOL bAskIfPlayerWantsToJoin, INT iPlayerFlags, BOOL paramUseMissionTriggering = FALSE)
	SCRIPT_EVENT_DATA_JOIN_SCRIPT_IF_NOT_ON_SCRIPT Event
	Event.Details.Type = SCRIPT_EVENT_JOIN_SCRIPT_IF_NOT_ON_SCRIPT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bAskIfPlayerWantsToJoin = bAskIfPlayerWantsToJoin
	Event.tempUseMissionTrigger = paramUseMissionTriggering
	Event.ScriptData = JoinScriptData
	IF ARE_VECTORS_EQUAL(Event.ScriptData.mdSecondaryCoords, <<0.0, 0.0, 0.0>>)
	OR ARE_VECTORS_EQUAL(Event.ScriptData.mdPrimaryCoords, <<0.0, 0.0, 0.0>>)
		FILL_IN_LOCATION_MISSION_DATA(Event.ScriptData.mdID.idMission, iPlayerFlags, Event.ScriptData.mdSecondaryCoords, Event.ScriptData.mdPrimaryCoords)
	ENDIF
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_JOIN_SCRIPT_IF_NOT_ON_SCRIPT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Off Mission Interaction																		
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_OFF_MISSION_INTERACTION
	STRUCT_EVENT_COMMON_DETAILS Details 
	VECTOR VehicleCoordData
ENDSTRUCT

//PURPOSE: Broadcast for players to join a script. 
PROC BROADCAST_OFF_MISSION_INTERACTION(VECTOR VehicleCoords, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_OFF_MISSION_INTERACTION Event
	Event.Details.Type = SCRIPT_EVENT_OFF_MISSION_INTERACTION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.VehicleCoordData = VehicleCoords
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_OFF_MISSION_INTERACTION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC
//
////╔═════════════════════════════════════════════════════════════════════════════╗
////║							SEND CRANE DATA																	
////╚═════════════════════════════════════════════════════════════════════════════╝
//
//// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
//STRUCT SCRIPT_EVENT_CRANE_DATA
//
//	STRUCT_EVENT_COMMON_DETAILS Details 
//	INT icranedriver = -1
//	BOOL bcontattached
//	FLOAT fcranemain
//	FLOAT fcranecabin
//	FLOAT fcranespreader
//	
//ENDSTRUCT
////PURPOSE: Broadcast for debug spawn map data
//PROC BROADCAST_CRANE_DATA(INT icranedriver,INT iPlayerFlags, BOOL bcontattached, FLOAT fcranemain, FLOAT fcranecabin,FLOAT fcranespreader)
//
//	
//	
//		SCRIPT_EVENT_CRANE_DATA Event
//		Event.Details.Type = SCRIPT_EVENT_PROCESS_CRANE_DATA
//		Event.Details.FromPlayerIndex = PLAYER_ID()
//		
//		Event.icranedriver = icranedriver
//		Event.bcontattached = bcontattached
//		Event.fcranemain = fcranemain
//		Event.fcranecabin = fcranecabin
//		Event.fcranespreader = fcranespreader
//
//		
//		IF NOT (iPlayerFlags = 0)
//			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//		ELSE
//			NET_PRINT("BROADCAST_CRANE_DATA - playerflags = 0 so not broadcasting") NET_NL()		
//		ENDIF	
//	
//	
//	
//ENDPROC
//// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
//STRUCT SCRIPT_EVENT_DATA_TRIGGER_PW
//
//	STRUCT_EVENT_COMMON_DETAILS Details 
//	BOOL blaunchpropertywars
//	
//ENDSTRUCT
////PURPOSE: Broadcast for debug spawn map data
//PROC BROADCAST_PROPERTY_WARS_LAUNCH_STATE(bool blaunchpropertywars,INT iPlayerFlags)
//	
//	SCRIPT_EVENT_DATA_TRIGGER_PW Event
//	Event.Details.Type = SCRIPT_EVENT_PROCESS_PROPERTY_WARS_DATA
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.blaunchpropertywars = blaunchpropertywars
//	
//
//	IF NOT (iPlayerFlags = 0)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_PROPERTY WARS DATA - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF	
//	
//ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║						REMOTE FIREWORKS - CREATE																	
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
//STRUCT SCRIPT_EVENT_DATA_CREATE_REMOTE_FIREWORK
//	STRUCT_EVENT_COMMON_DETAILS Details
//	INT iSlot
//	INT iType
//	VECTOR vLocation
//ENDSTRUCT

////PURPOSE: Broadcast to tell Remote Players the we have placed a Firework
//PROC BROADCAST_CREATE_REMOTE_FIREWORK(INT iSlot, INT iType, VECTOR vLocation, INT iPlayerFlags)
//	SCRIPT_EVENT_DATA_CREATE_REMOTE_FIREWORK Event
//	Event.Details.Type = SCRIPT_EVENT_CREATE_REMOTE_FIREWORK
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.iSlot = iSlot
//	Event.iType = iType
//	Event.vLocation = vLocation
//	IF NOT (iPlayerFlags = 0)
//		NET_PRINT("BROADCAST_CREATE_REMOTE_FIREWORK - SENT") NET_NL()	
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_CREATE_REMOTE_FIREWORK - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF	
//ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║						REMOTE FIREWORKS - REMOVE																	
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
//STRUCT SCRIPT_EVENT_DATA_REMOVE_PLAYERS_REMOTE_FIREWORKS
//	STRUCT_EVENT_COMMON_DETAILS Details
//ENDSTRUCT
//
////PURPOSE: Broadcast to tell Remote Players the we have placed a Firework
//PROC BROADCAST_REMOVE_PLAYERS_REMOTE_FIREWORKS(INT iPlayerFlags)
//	SCRIPT_EVENT_DATA_REMOVE_PLAYERS_REMOTE_FIREWORKS Event
//	Event.Details.Type = SCRIPT_EVENT_REMOVE_PLAYERS_REMOTE_FIREWORKS
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	IF NOT (iPlayerFlags = 0)
//		NET_PRINT("BROADCAST_REMOVE_PLAYERS_REMOTE_FIREWORKS - SENT") NET_NL()	
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_REMOVE_PLAYERS_REMOTE_FIREWORKS - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF	
//ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							HOLD UP	- MAKE ACTIVE																	
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_MAKE_HOLD_UP_ACTIVE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iHoldUp
	BOOL bMakeHoldUpActive
ENDSTRUCT

//PURPOSE: Broadcast to tell Server that the player wants this Hold Up to be active
PROC BROADCAST_MAKE_HOLD_UP_ACTIVE(INT iHoldUp, BOOL bMakeHoldUpActive, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_MAKE_HOLD_UP_ACTIVE Event
	Event.Details.Type = SCRIPT_EVENT_MAKE_HOLD_UP_ACTIVE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iHoldUp = iHoldUp
	Event.bMakeHoldUpActive = bMakeHoldUpActive
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_MAKE_HOLD_UP_ACTIVE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							HOLD UP	- FAKE DONE																	
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_HOLD_UP_FAKE_DONE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iHoldUp
	BOOL bEnable
ENDSTRUCT

//PURPOSE: Broadcast to tell Server that the Hold Up should be marked as done (FAKE - for Tutorial)
PROC BROADCAST_HOLD_UP_FAKE_DONE(INT iHoldUp, BOOL bEnable, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_HOLD_UP_FAKE_DONE Event
	Event.Details.Type = SCRIPT_EVENT_HOLD_UP_FAKE_DONE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iHoldUp = iHoldUp
	Event.bEnable = bEnable
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_HOLD_UP_FAKE_DONE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							HOLD UP	- SET AS DONE																	
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_SET_HOLD_UP_DONE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iHoldUp
	BOOL bSetHoldUpDone
ENDSTRUCT

//PURPOSE: Broadcast to tell Server that the player has just done this Hold Up
PROC BROADCAST_SET_HOLD_UP_DONE(INT iHoldUp, BOOL bSetHoldUpDone, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_SET_HOLD_UP_DONE Event
	Event.Details.Type = SCRIPT_EVENT_SET_HOLD_UP_DONE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iHoldUp = iHoldUp
	Event.bSetHoldUpDone = bSetHoldUpDone
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SET_HOLD_UP_DONE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							HOLD UP	- SET PLAYER INSIDE HOLD UP STORE																	
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_IN_HOLD_UP_STORE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iHoldUp
	BOOL bInStore
ENDSTRUCT

//PURPOSE: Broadcast to tell Server that the player is inside the Hold Up store
PROC BROADCAST_IN_HOLD_UP_STORE(INT iHoldUp, BOOL bInStore, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_IN_HOLD_UP_STORE Event
	Event.Details.Type = SCRIPT_EVENT_IN_HOLD_UP_STORE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iHoldUp = iHoldUp
	Event.bInStore = bInStore
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_IN_HOLD_UP_STORE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//PURPOSE: Broadcast to tell Server that the player is inside the Hold Up store
PROC BROADCAST_IN_HOLD_UP_STORE_STRICT(INT iHoldUp, BOOL bInStore, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_IN_HOLD_UP_STORE Event
	Event.Details.Type = SCRIPT_EVENT_IN_HOLD_UP_STORE_STRICT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iHoldUp = iHoldUp
	Event.bInStore = bInStore
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_IN_HOLD_UP_STORE_STRICT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					HOLD UP	- SET PLAYER HAS TRIGGERED EMPTY REGISTER																	
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_HOLD_UP_TRIGGER_EMPTY_REG
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

//PURPOSE: Broadcast to tell Server that the player is inside the Hold Up store
PROC BROADCAST_HOLD_UP_TRIGGER_EMPTY_REG(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_HOLD_UP_TRIGGER_EMPTY_REG Event
	Event.Details.Type = SCRIPT_EVENT_HOLD_UP_TRIGGER_EMPTY_REG
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_HOLD_UP_TRIGGER_EMPTY_REG - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							INVITE FOR RACE TO POINT																		
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_RACE_TO_POINT_INVITE
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iRaceToPointInstance
	VECTOR vRaceToPointStart
	VECTOR vRaceToPointDestination
	TEXT_LABEL_15 tlDestination
ENDSTRUCT

//PURPOSE: Broadcast to invite team mates to join a Race to Point
PROC BROADCAST_RACE_TO_POINT_INVITE(VECTOR vStartPosition, VECTOR vDestination, TEXT_LABEL_15 tlDestination, INT iInstance, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_RACE_TO_POINT_INVITE Event
	Event.Details.Type = SCRIPT_EVENT_RACE_TO_POINT_INVITE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRaceToPointInstance = iInstance	//NATIVE_TO_INT(NETWORK_GET_PARTICIPANT_INDEX(PLAYER_ID()))
	Event.vRaceToPointStart = vStartPosition
	Event.vRaceToPointDestination = vDestination
	Event.tlDestination = tlDestination
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_RACE_TO_POINT_INVITE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
	SET_PACKED_STAT_BOOL(PACKED_MP_CHALLENGE_IMPROPTURACE, TRUE) 
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							RACE TO POINT - REACHED DESTINATION																		
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_RACE_TO_POINT_REACHED_DESTINATION
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iTime
ENDSTRUCT

//PURPOSE: Broadcast to cancel invite for a Race to Point
PROC BROADCAST_RACE_TO_POINT_REACHED_DESTINATION(INT iTime, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_RACE_TO_POINT_REACHED_DESTINATION Event
	Event.Details.Type = SCRIPT_EVENT_RACE_TO_POINT_REACHED_DESTINATION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTime = iTime
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_RACE_TO_POINT_REACHED_DESTINATION - SENT BY ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex))
		PRINTLN("     ----->    BROADCAST_RACE_TO_POINT_REACHED_DESTINATION - SENT CLOUD TIME = ", iTime)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_RACE_TO_POINT_REACHED_DESTINATION - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							CANCEL INVITE FOR RACE TO POINT																		
//╚═════════════════════════════════════════════════════════════════════════════╝

//PURPOSE: Broadcast to cancel invite for a Race to Point
PROC BROADCAST_RACE_TO_POINT_CANCEL_INVITE(VECTOR vStartPosition, INT iInstance, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_RACE_TO_POINT_INVITE Event
	Event.Details.Type = SCRIPT_EVENT_RACE_TO_POINT_CANCEL_INVITE //** TWH - RLB - (fix for B*1398813 - wrong event type was pasted in here).
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRaceToPointInstance 		= iInstance	//NATIVE_TO_INT(NETWORK_GET_PARTICIPANT_INDEX(PLAYER_ID()))
	Event.vRaceToPointStart			= vStartPosition
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_RACE_TO_POINT_CANCEL_INVITE - SENT BY ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_RACE_TO_POINT_CANCEL_INVITE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							CHECKPOINT COLLECTION - REACHED CHECKPOINT																		
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_CHECKPOINT_COLLECTION_REACHED_CHECKPOINT
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iTime
	INT iCheckpoint
ENDSTRUCT

//PURPOSE: Broadcast to cancel invite for a Race to Point
PROC BROADCAST_CHECKPOINT_COLLECTION_REACHED_CHECKPOINT(INT iTime,INT iCheckpoint, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_CHECKPOINT_COLLECTION_REACHED_CHECKPOINT Event
	Event.Details.Type = SCRIPT_EVENT_CHECKPOINT_COLLECTION_REACHED_CHECKPOINT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTime = iTime
	Event.iCheckpoint = iCheckpoint
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_CHECKPOINT_COLLECTION_REACHED_CHECKPOINT - SENT BY ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex))
		PRINTLN("     ----->    BROADCAST_CHECKPOINT_COLLECTION_REACHED_CHECKPOINT - SENT CLOUD TIME = ", iTime)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CHECKPOINT_COLLECTION_REACHED_CHECKPOINT - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							CHECKPOINT COLLECTION - GIVE REWARD																		
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_CHECKPOINT_COLLECTION_GIVE_REWARD
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iCheckpoint
ENDSTRUCT

//PURPOSE: Broadcast to cancel invite for a Race to Point
PROC BROADCAST_CHECKPOINT_COLLECTION_GIVE_REWARD(INT iCheckpoint, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_CHECKPOINT_COLLECTION_GIVE_REWARD Event
	Event.Details.Type = SCRIPT_EVENT_CHECKPOINT_COLLECTION_GIVE_REWARD
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iCheckpoint = iCheckpoint
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_CHECKPOINT_COLLECTION_GIVE_REWARD - SENT BY ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CHECKPOINT_COLLECTION_GIVE_REWARD - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							PENNED IN - REMOVE CAR BOMB																	
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_PENNED_IN_REMOVE_BOMB
	STRUCT_EVENT_COMMON_DETAILS Details 
ENDSTRUCT

//PURPOSE: Broadcast to remove car bomb from cars used in Penned In
PROC BROADCAST_PENNED_IN_REMOVE_BOMB(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_PENNED_IN_REMOVE_BOMB Event
	Event.Details.Type = SCRIPT_EVENT_PENNED_IN_REMOVE_BOMB
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_PENNED_IN_REMOVE_BOMB - SENT BY ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PENNED_IN_REMOVE_BOMB - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							HUNT THE BEAST - UPDATE GLOBAL																	
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_HUNT_THE_BEAST_UPDATE_GLOBAL
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX piBeastPlayer
ENDSTRUCT

//PURPOSE: Broadcast to remove car bomb from cars used in Penned In
PROC BROADCAST_HUNT_THE_BEAST_UPDATE_GLOBAL(PLAYER_INDEX beastPlayer, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_HUNT_THE_BEAST_UPDATE_GLOBAL Event
	Event.Details.Type = SCRIPT_EVENT_HUNT_THE_BEAST_UPDATE_GLOBAL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.piBeastPlayer = beastPlayer
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_HUNT_THE_BEAST_UPDATE_GLOBAL - SENT BY ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_HUNT_THE_BEAST_UPDATE_GLOBAL - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							BULL SHARK - TURNED ON																		
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_BULL_SHARK
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iUniqueSessionHash0
	INT iUniqueSessionHash1
ENDSTRUCT

//PURPOSE: Broadcast to make other players perform the sound of Bull Shark starting
PROC BROADCAST_RACE_BULL_SHARK_ON(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_BULL_SHARK Event
	Event.Details.Type = SCRIPT_EVENT_BULL_SHARK_ON
	Event.Details.FromPlayerIndex = PLAYER_ID()
	GET_THIS_SESSION_UNIQUE_EVENT_IDS(Event.iUniqueSessionHash0, Event.iUniqueSessionHash1)
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_RACE_BULL_SHARK_ON - SENT BY ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_RACE_BULL_SHARK_ON - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							BULL SHARK - TURNED OFF																		
//╚═════════════════════════════════════════════════════════════════════════════╝

//PURPOSE: Broadcast to make other players perform the sound of Bull Shark starting
PROC BROADCAST_RACE_BULL_SHARK_OFF(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_BULL_SHARK Event
	Event.Details.Type = SCRIPT_EVENT_BULL_SHARK_OFF
	Event.Details.FromPlayerIndex = PLAYER_ID()
	GET_THIS_SESSION_UNIQUE_EVENT_IDS(Event.iUniqueSessionHash0, Event.iUniqueSessionHash1)
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_RACE_BULL_SHARK_OFF - SENT BY ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_RACE_BULL_SHARK_OFF - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					PASSIVE MODE - PAY ANOTHER PLAYERS HOSPITAL BILLS																		
//╚═════════════════════════════════════════════════════════════════════════════╝

//STRUCT SCRIPT_EVENT_DATA_PAY_PLAYERS_HOSPITAL_BILLS
//	STRUCT_EVENT_COMMON_DETAILS Details
//	INT iHospitalBill
//	BOOL bLocalPlayerInPassiveMode
//ENDSTRUCT

////PURPOSE: Broadcast to make the chosen Player pay the local Players Hospital Bills
//PROC BROADCAST_PAY_PLAYERS_HOSPITAL_BILLS(INT iHospitalBill, BOOL bLocalPlayerInPassiveMode, INT iPlayerFlags)
//	SCRIPT_EVENT_DATA_PAY_PLAYERS_HOSPITAL_BILLS Event
//	Event.Details.Type = SCRIPT_EVENT_PAY_PLAYERS_HOSPITAL_BILLS
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.iHospitalBill = iHospitalBill
//	Event.bLocalPlayerInPassiveMode = bLocalPlayerInPassiveMode
//	IF NOT (iPlayerFlags = 0)
//		PRINTLN("     ----->    BROADCAST_PAY_PLAYERS_HOSPITAL_BILLS - SENT BY ", GET_PLAYER_NAME(Event.Details.FromPlayerIndex))
//		PRINTLN("     ----->    BROADCAST_PAY_PLAYERS_HOSPITAL_BILLS - iHospitalBill ", Event.iHospitalBill)
//		PRINTLN("     ----->    BROADCAST_PAY_PLAYERS_HOSPITAL_BILLS - bLocalPlayerInPassiveMode ", Event.bLocalPlayerInPassiveMode)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_PAY_PLAYERS_HOSPITAL_BILLS - playerflags = 0 so not broadcasting") NET_NL()
//	ENDIF
//ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							INVITE TO APARTMENT									
//╚═════════════════════════════════════════════════════════════════════════════╝
CONST_INT SE_INVITE_TO_APARTMENT_YACHT			1
CONST_INT SE_INVITE_TO_APARTMENT_OFFICE			2
CONST_INT SE_INVITE_TO_APARTMENT_CLUBHOUSE		3
CONST_INT SE_INVITE_TO_APARTMENT_OFF_GAR		4
CONST_INT SE_INVITE_TO_APARTMENT_OFF_AUTO_SHOP	5


// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_INVITE_TO_APARTMENT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iInviteType
ENDSTRUCT

//PURPOSE: Send the player an Invite to your Apartment
PROC BROADCAST_INVITE_TO_APARTMENT(INT iPlayerFlags, INT iInviteType = 0)
	SCRIPT_EVENT_DATA_INVITE_TO_APARTMENT Event
	Event.Details.Type = SCRIPT_EVENT_INVITE_TO_APARTMENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
//	IF bIsYacht
//		Event.iInviteType = SE_INVITE_TO_APARTMENT_YACHT
//		PRINTLN("SCRIPT_EVENT_INVITE_TO_APARTMENT - yacht invite sent")
//	#IF FEATURE_EXECUTIVE
//	ELIF bIsOffice
//		PRINTLN("SCRIPT_EVENT_INVITE_TO_APARTMENT - office invite sent")
//		Event.iInviteType = SE_INVITE_TO_APARTMENT_OFFICE	
//	#ENDIF
//	#IF FEATURE_BIKER
//	ELIF bIsClubhouse
//		PRINTLN("SCRIPT_EVENT_INVITE_TO_APARTMENT - clubhouse invite sent")
//		Event.iInviteType = SE_INVITE_TO_APARTMENT_CLUBHOUSE
//	#ENDIF
//	ENDIF
	
	IF iInviteType > 0
		PRINTLN("SCRIPT_EVENT_INVITE_TO_APARTMENT -",iInviteType," invite sent")
		Event.iInviteType = iInviteType
	ENDIF
	
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_INVITE_TO_APARTMENT - SENT BY ", GET_PLAYER_NAME(PLAYER_ID()))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_INVITE_TO_APARTMENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							CANCEL INVITE TO APARTMENT									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CANCEL_INVITE_TO_APARTMENT
	STRUCT_EVENT_COMMON_DETAILS Details 
ENDSTRUCT

//PURPOSE: Cancel an Invite to your Apartment
PROC BROADCAST_CANCEL_INVITE_TO_APARTMENT(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_CANCEL_INVITE_TO_APARTMENT Event
	Event.Details.Type = SCRIPT_EVENT_CANCEL_INVITE_TO_APARTMENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_CANCEL_INVITE_TO_APARTMENT - SENT BY ", GET_PLAYER_NAME(PLAYER_ID()))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CANCEL_INVITE_TO_APARTMENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//Rollercoaster
//╔═════════════════════════════════════════════════════════════════════════════╗
//║							SET ROLLERCOASTER HIDDEN									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_SET_ROLLERCOASTER_HIDDEN
	STRUCT_EVENT_COMMON_DETAILS Details 
ENDSTRUCT

//PURPOSE: Set the rollercoaster map object to be hidden
PROC BROADCAST_SET_ROLLERCOASTER_HIDDEN(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_SET_ROLLERCOASTER_HIDDEN Event
	Event.Details.Type = SCRIPT_EVENT_SET_ROLLERCOASTER_HIDDEN
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_SET_ROLLERCOASTER_HIDDEN - SENT BY ", GET_PLAYER_NAME(PLAYER_ID()))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SCRIPT_EVENT_SET_ROLLERCOASTER_HIDDEN - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							SYNC ROLLERCOASTER DISTANCE								
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_SYNC_ROLLERCOASTER_DIST
	STRUCT_EVENT_COMMON_DETAILS Details 
	FLOAT fDist
	FLOAT fSpeed
	INT iTime
	INT iLapsDone
ENDSTRUCT

//Purpose: Syncs the current distance of the rollercoaster with the server
PROC BROADCAST_SYNC_ROLLERCOASTER_DIST(INT iPlayerFlags,INT iLapsDone)
	SCRIPT_EVENT_DATA_SYNC_ROLLERCOASTER_DIST Event
	Event.Details.Type = SCRIPT_EVENT_SYNC_ROLLERCOASTER_DIST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.fDist = g_fCoasterDist
	Event.fSpeed = g_fCoasterSpeed
	Event.iTime = GET_STREAM_PLAY_TIME()
	Event.iLapsDone = iLapsDone
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_SYNC_ROLLERCOASTER_DIST ",Event.fDist ," - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SYNC_ROLLERCOASTER_DIST - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							REQUEST ROLLERCOASTER DISTANCE									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_REQUEST_ROLLERCOASTER_DIST
	STRUCT_EVENT_COMMON_DETAILS Details 
ENDSTRUCT

//Purpose: Syncs the current distance of the rollercoaster with the server
PROC BROADCAST_REQUEST_ROLLERCOASTER_DIST(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_REQUEST_ROLLERCOASTER_DIST Event
	Event.Details.Type = SCRIPT_EVENT_REQUEST_ROLLERCOASTER_DIST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_REQUEST_ROLLERCOASTER_DIST - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_REQUEST_ROLLERCOASTER_DIST - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							REQUEST ATTACH REMOTE PLAYER TO COASTER									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_REQUEST_ATTACH_REMOTE_PLAYER_TO_COASTER
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

//Purpose: Attach a remote player to the local Ferris wheel car
PROC BROADCAST_REQUEST_ATTACH_REMOTE_PLAYER_TO_COASTER(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_REQUEST_ATTACH_REMOTE_PLAYER_TO_COASTER Event
	Event.Details.Type = SCRIPT_EVENT_REQUEST_ATTACH_REMOTE_PLAYER_TO_COASTER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_REQUEST_ATTACH_REMOTE_PLAYER_TO_COASTER - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_REQUEST_ATTACH_REMOTE_PLAYER_TO_COASTER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							ATTACH REMOTE PLAYER TO COASTER								
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_ATTACH_REMOTE_PLAYER_TO_COASTER
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCarIndex
	VECTOR vOffset
	VECTOR vRotation
ENDSTRUCT

//Purpose: Attach a remote player to the local Ferris wheel car
PROC BROADCAST_ATTACH_REMOTE_PLAYER_TO_COASTER(INT iPlayerFlags,INT iCarIndex,VECTOR vOffset,VECTOR vRotation)
	SCRIPT_EVENT_DATA_ATTACH_REMOTE_PLAYER_TO_COASTER Event
	Event.Details.Type = SCRIPT_EVENT_ATTACH_REMOTE_PLAYER_TO_COASTER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iCarIndex = iCarIndex
	Event.vOffset = vOffset
	Event.vRotation = vRotation
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_ATTACH_REMOTE_PLAYER_TO_COASTER - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_ATTACH_REMOTE_PLAYER_TO_COASTER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							DETACH REMOTE PLAYER FROM COASTER									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_DETACH_REMOTE_PLAYER_FROM_COASTER
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

//Purpose: Detach a remote player from the local rollercoaster 
PROC BROADCAST_DETACH_REMOTE_PLAYER_FROM_COASTER(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DETACH_REMOTE_PLAYER_FROM_COASTER Event
	Event.Details.Type = SCRIPT_EVENT_DETACH_REMOTE_PLAYER_FROM_COASTER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_DETACH_REMOTE_PLAYER_FROM_COASTER - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DETACH_REMOTE_PLAYER_FROM_COASTER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							AUTHORISE COASTER ENTRY									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_AUTHORISE_COASTER_ENTRY
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bAuthorised
	INT iPosition
ENDSTRUCT

//Purpose: Tell the server when a player enter/exits coaster
PROC BROADCAST_AUTHORISE_COASTER_ENTRY(INT iPlayerFlags, BOOL bAuthorised,INT iPosition)
	SCRIPT_EVENT_DATA_AUTHORISE_COASTER_ENTRY Event
	Event.Details.Type = SCRIPT_EVENT_AUTHORISE_COASTER_ENTRY
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bAuthorised = bAuthorised
	Event.iPosition = iPosition
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_AUTHORISE_COASTER_ENTRY - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_AUTHORISE_COASTER_ENTRY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							MODIFY COASTER OCCUPANTS									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_MODIFY_COASTER_OCCUPANTS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iSeatIndex
	BOOL bEntering
ENDSTRUCT

//Purpose: Tell the server when a player enter/exits coaster
PROC BROADCAST_MODIFY_COASTER_OCCUPANTS(INT iPlayerFlags,INT iSeatIndex,BOOL bEntering = FALSE)
	SCRIPT_EVENT_DATA_MODIFY_COASTER_OCCUPANTS Event
	Event.Details.Type = SCRIPT_EVENT_MODIFY_COASTER_OCCUPANTS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iSeatIndex = iSeatIndex
	Event.bEntering = bEntering
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_MODIFY_COASTER_OCCUPANTS - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_MODIFY_COASTER_OCCUPANTS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC


//Ferris Wheel
//╔═════════════════════════════════════════════════════════════════════════════╗
//║							SYNC WHEEL ROTATION									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_SYNC_WHEEL_ROTATION
	STRUCT_EVENT_COMMON_DETAILS Details 
	FLOAT fRotation
ENDSTRUCT

//Purpose: Syncs the current rotation of the Ferris wheel with the server
PROC BROADCAST_SYNC_WHEEL_ROTATION(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_SYNC_WHEEL_ROTATION Event
	Event.Details.Type = SCRIPT_EVENT_SYNC_WHEEL_ROTATION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.fRotation = g_fWheelRotation
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_SYNC_WHEEL_ROTATION ",Event.fRotation ," - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SYNC_WHEEL_ROTATION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							REQUEST WHEEL ROTATION									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_REQUEST_WHEEL_ROTATION
	STRUCT_EVENT_COMMON_DETAILS Details 
ENDSTRUCT

//Purpose: Syncs the current rotation of the Ferris wheel with the server
PROC BROADCAST_REQUEST_WHEEL_ROTATION(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_REQUEST_WHEEL_ROTATION Event
	Event.Details.Type = SCRIPT_EVENT_REQUEST_WHEEL_ROTATION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_REQUEST_WHEEL_ROTATION - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_REQUEST_WHEEL_ROTATION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							REQUEST ATTACH REMOTE PLAYER TO CAR									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_REQUEST_ATTACH_REMOTE_PLAYER_TO_CAR
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

//Purpose: Attach a remote player to the local Ferris wheel car
PROC BROADCAST_REQUEST_ATTACH_REMOTE_PLAYER_TO_CAR(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_REQUEST_ATTACH_REMOTE_PLAYER_TO_CAR Event
	Event.Details.Type = SCRIPT_EVENT_REQUEST_ATTACH_REMOTE_PLAYER_TO_CAR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_REQUEST_ATTACH_REMOTE_PLAYER_TO_CAR - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_REQUEST_ATTACH_REMOTE_PLAYER_TO_CAR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							ATTACH REMOTE PLAYER TO CAR									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_ATTACH_REMOTE_PLAYER_TO_CAR
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCarIndex
	VECTOR vOffset
	FLOAT fAngle
ENDSTRUCT

//Purpose: Attach a remote player to the local Ferris wheel car
PROC BROADCAST_ATTACH_REMOTE_PLAYER_TO_CAR(INT iPlayerFlags,INT iCarIndex,VECTOR vOffset,FLOAT fAngle)
	SCRIPT_EVENT_DATA_ATTACH_REMOTE_PLAYER_TO_CAR Event
	Event.Details.Type = SCRIPT_EVENT_ATTACH_REMOTE_PLAYER_TO_CAR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iCarIndex = iCarIndex
	Event.vOffset = vOffset
	Event.fAngle = fAngle
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_ATTACH_REMOTE_PLAYER_TO_CAR - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_ATTACH_REMOTE_PLAYER_TO_CAR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							DETACH REMOTE PLAYER FROM CAR									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_DETACH_REMOTE_PLAYER_FROM_CAR
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

//Purpose: Detach a remote player from the local Ferris wheel car
PROC BROADCAST_DETACH_REMOTE_PLAYER_FROM_CAR(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DETACH_REMOTE_PLAYER_FROM_CAR Event
	Event.Details.Type = SCRIPT_EVENT_DETACH_REMOTE_PLAYER_FROM_CAR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_DETACH_REMOTE_PLAYER_FROM_CAR - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DETACH_REMOTE_PLAYER_FROM_CAR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							REQUEST INTERACT WITH CAR									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_REQUEST_INTERACT_CAR
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

//Purpose: Check if player can interact with ferris wheel car
PROC BROADCAST_REQUEST_INTERACT_CAR(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_REQUEST_INTERACT_CAR Event
	Event.Details.Type = SCRIPT_EVENT_REQUEST_INTERACT_CAR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_REQUEST_INTERACT_CAR - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_REQUEST_INTERACT_CAR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							INTERACT WITH CAR								
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_INTERACT_CAR
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bBlocked
ENDSTRUCT

//Purpose: Check if player can interact with ferris wheel car
PROC BROADCAST_INTERACT_CAR(INT iPlayerFlags,BOOL bBlocked)
	SCRIPT_EVENT_DATA_INTERACT_CAR Event
	Event.Details.Type = SCRIPT_EVENT_INTERACT_CAR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bBlocked = bBlocked
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_INTERACT_CAR - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_INTERACT_CAR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							CLEAR INTERACT WITH CAR									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CLEAR_INTERACT_CAR
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iSeatIndex
	BOOL bEntering
ENDSTRUCT

//Purpose: Set player done interacting with ferris wheel car
PROC BROADCAST_CLEAR_INTERACT_CAR(INT iPlayerFlags,INT iSeatIndex,BOOL bEntering)
	SCRIPT_EVENT_DATA_CLEAR_INTERACT_CAR Event
	Event.Details.Type = SCRIPT_EVENT_CLEAR_INTERACT_CAR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iSeatIndex = iSeatIndex
	Event.bEntering = bEntering
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_CLEAR_INTERACT_CAR - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CLEAR_INTERACT_CAR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							CLEAR FERRIS WHEEL SERVER DATA								
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CLEAR_WHEEL_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iParticipant
ENDSTRUCT

//Purpose: Set player done interacting with ferris wheel car
PROC BROADCAST_CLEAR_WHEEL_DATA(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_CLEAR_WHEEL_DATA Event
	Event.Details.Type = SCRIPT_EVENT_CLEAR_WHEEL_DATA
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iParticipant = PARTICIPANT_ID_TO_INT()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_CLEAR_WHEEL_DATA - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CLEAR_WHEEL_DATA - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							REMOVE WANTED LEVEL							
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_REMOVE_WANTED_LEVEL
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iUniquePlayersHash
ENDSTRUCT

//Purpose: Removes remote player's wanted level
PROC BROADCAST_REMOVE_WANTED_LEVEL(PLAYER_INDEX PlayerID)
	SCRIPT_EVENT_DATA_REMOVE_WANTED_LEVEL Event
	Event.Details.Type = SCRIPT_EVENT_REMOVE_WANTED_LEVEL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iUniquePlayersHash = GET_THIS_PLAYER_UNIQUE_EVENT_ID(PlayerID)
	INT iPlayerFlags = SPECIFIC_PLAYER(PlayerID)
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_REMOVE_WANTED_LEVEL - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_REMOVE_WANTED_LEVEL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							SET COPS DISABLED						
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_SET_COPS_DISABLED
	STRUCT_EVENT_COMMON_DETAILS Details
	SCRIPT_TIMER timeCopsDisabled
ENDSTRUCT

//Purpose: For Lester's turn a blind eye
PROC BROADCAST_SET_COPS_DISABLED(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_SET_COPS_DISABLED Event
	Event.Details.Type = SCRIPT_EVENT_SET_COPS_DISABLED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.timeCopsDisabled = MPGlobalsAmbience.timeCopsDisabled
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_SET_COPS_DISABLED - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SET_COPS_DISABLED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║				  GANG BOSS - REMOVE WANTED LEVEL & SET COPS DISABLED						
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_BRIBE_POLICE
	STRUCT_EVENT_COMMON_DETAILS Details
	SCRIPT_TIMER timeCopsDisabled
	TIME_DATATYPE timeCopsDisabledJipGang
	BOOL bJipGangMode
	INT iUniquePlayersHash
ENDSTRUCT

//Purpose: Removes remote player's wanted level and set no police for a specified duration.
PROC BROADCAST_GB_BRIBE_POLICE(PLAYER_INDEX PlayerID, BOOL bJipGangMode = FALSE)
	SCRIPT_EVENT_DATA_BRIBE_POLICE Event
	Event.Details.Type = SCRIPT_EVENT_GB_BRIBE_POLICE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.timeCopsDisabled = MPGlobalsAmbience.timeCopsDisabled
	Event.iUniquePlayersHash = GET_THIS_PLAYER_UNIQUE_EVENT_ID(PlayerID)
	
	IF bJipGangMode
		Event.bJipGangMode = bJipGangMode
		Event.timeCopsDisabledJipGang = GET_NETWORK_TIME()
		PRINTLN("[GB][AMEC] - BROADCAST_SET_COPS_DISABLED - Setting cops disabled, bJipGangMode = TRUE")
	ENDIF
	INT iPlayerFlags = SPECIFIC_PLAYER(PlayerID)
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_BRIBE_POLICE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_BRIBE_POLICE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				  GANG BOSS - SET REMOTE PLAYER AS HIT					
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_SET_REMOTE_PLAYER_AS_TERMINATE_TARGET
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bIsTarget
ENDSTRUCT

PROC BROADCAST_GB_SET_REMOTE_PLAYER_AS_TERMINATE_TARGET(INT iPlayerFlags, BOOL bIsTarget = TRUE)
	SCRIPT_EVENT_DATA_SET_REMOTE_PLAYER_AS_TERMINATE_TARGET Event
	Event.Details.Type = SCRIPT_EVENT_GB_SET_REMOTE_PLAYER_AS_TERMINATE_TARGET
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bIsTarget = bIsTarget
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_SET_REMOTE_PLAYER_AS_TERMINATE_TARGET - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_SET_REMOTE_PLAYER_AS_TERMINATE_TARGET - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC



//╔═════════════════════════════════════════════════════════════════════════════╗
//║							REMOVE PLAYER BLIP						
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════

STRUCT SCRIPT_EVENT_DATA_REMOVE_PLAYER_BLIP
	STRUCT_EVENT_COMMON_DETAILS Details
	TIME_DATATYPE timeRemoveBlip
	TIME_DATATYPE timeJIP
	BOOL bGangMode
	BOOL bJipGangMode
	INT iUniquePlayersHash
ENDSTRUCT

//Purpose: For Lester's Remove player blip
PROC BROADCAST_REMOVE_PLAYER_BLIP(PLAYER_INDEX PlayerID, BOOL bGangMode = FALSE, BOOL bJipGangMode = FALSE)
	SCRIPT_EVENT_DATA_REMOVE_PLAYER_BLIP Event
	Event.Details.Type = SCRIPT_EVENT_OFF_THE_RADAR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.timeRemoveBlip = MPGlobals.g_timeOffTheRadar
	Event.bJipGangMode = bJipGangMode
	Event.iUniquePlayersHash = GET_THIS_PLAYER_UNIQUE_EVENT_ID(PlayerID)
	
	IF Event.bJipGangMode
		PRINTLN("     ----->    SCRIPT_EVENT_OFF_THE_RADAR - bJipGangMode = TRUE, saving timestamp for JIP members.")
		Event.timeJIP = GET_NETWORK_TIME()
	ENDIF
	INT iPlayerFlags = SPECIFIC_PLAYER(PlayerID)
	Event.bGangMode = bGangMode
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_OFF_THE_RADAR - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT(), ". bGangMode: ", bGangMode)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("SCRIPT_EVENT_OFF_THE_RADAR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							SET HPV RUNNING		
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════

STRUCT SCRIPT_EVENT_DATA_AML_SET_HPV_RUNNING
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bRunning
ENDSTRUCT

//Purpose: Tell Import/Export to launch/cleanup HPV
PROC BROADCAST_AML_SET_HPV_RUNNING(INT iPlayerFlags,BOOL bRunning)
	SCRIPT_EVENT_DATA_AML_SET_HPV_RUNNING Event
	Event.Details.Type = SCRIPT_EVENT_AML_SET_HPV_RUNNING
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bRunning = bRunning
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_AML_SET_HPV_RUNNING - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("SCRIPT_AML_SET_HPV_RUNNING - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							RUN SPECIAL CRATE DROP		
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════

STRUCT SCRIPT_EVENT_DATA_AML_RUN_SPC_CRATE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bRunning
ENDSTRUCT

//Purpose: Set special crate drop flag
PROC BROADCAST_AML_RUN_SPC_CRATE(INT iPlayerFlags,BOOL bRunning)
	SCRIPT_EVENT_DATA_AML_RUN_SPC_CRATE Event
	Event.Details.Type = SCRIPT_EVENT_AML_RUN_SPC_CRATE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bRunning = bRunning
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_AML_RUN_SPC_CRATE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("SCRIPT_AML_RUN_SPC_CRATE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════

STRUCT SCRIPT_EVENT_DATA_AML_DONE_SPC_CRATE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bRunning
ENDSTRUCT

//Purpose: Set special crate drop flag
PROC BROADCAST_AML_DONE_SPC_CRATE(INT iPlayerFlags,BOOL bRunning)
	SCRIPT_EVENT_DATA_AML_DONE_SPC_CRATE Event
	Event.Details.Type = SCRIPT_EVENT_AML_DONE_SPC_CRATE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bRunning = bRunning
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_AML_DONE_SPC_CRATE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("SCRIPT_AML_DONE_SPC_CRATE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_HEIST_BEGIN_HACK_MINIGAME
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iDialogueCausingHack
ENDSTRUCT

PROC BROADCAST_HEIST_BEGIN_HACK_MINIGAME(INT iPlayerFlags, INT iDialogueCausingHack)
	
	SCRIPT_EVENT_DATA_HEIST_BEGIN_HACK_MINIGAME Event
	
	Event.Details.Type = SCRIPT_EVENT_HEIST_BEGIN_HACK_MINIGAME
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iDialogueCausingHack = iDialogueCausingHack
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_HEIST_BEGIN_HACK_MINIGAME - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("SCRIPT_EVENT_HEIST_BEGIN_HACK_MINIGAME - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_HEIST_END_HACK_MINIGAME
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTeam
	BOOL bPass
ENDSTRUCT

PROC BROADCAST_HEIST_END_HACK_MINIGAME(INT iPlayerFlags, BOOL bPass,INT iTeam)
	SCRIPT_EVENT_DATA_HEIST_END_HACK_MINIGAME Event
	Event.Details.Type = SCRIPT_EVENT_HEIST_END_HACK_MINIGAME
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bPass = bPass
	Event.iTeam = iTeam
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_HEIST_END_HACK_MINIGAME - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("SCRIPT_EVENT_HEIST_END_HACK_MINIGAME - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_HEIST_QUIET_KNOCKING
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bQuiet
ENDSTRUCT

PROC BROADCAST_HEIST_QUIET_KNOCKING(INT iPlayerFlags, BOOL bQuiet)
	
	SCRIPT_EVENT_DATA_HEIST_QUIET_KNOCKING Event
	
	Event.Details.Type = SCRIPT_EVENT_HEIST_QUIET_KNOCKING
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bQuiet = bQuiet
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_HEIST_QUIET_KNOCKING - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("SCRIPT_EVENT_HEIST_QUIET_KNOCKING - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_HEIST_PLAYER_IN_TURRET
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bInTurret
ENDSTRUCT

PROC BROADCAST_HEIST_PLAYER_IN_TURRET(INT iPlayerFlags, BOOL bInTurret)
	
	SCRIPT_EVENT_DATA_HEIST_PLAYER_IN_TURRET Event
	
	Event.Details.Type = SCRIPT_EVENT_HEIST_PLAYER_IN_TURRET
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bInTurret = bInTurret
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_HEIST_PLAYER_IN_TURRET - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("SCRIPT_EVENT_HEIST_PLAYER_IN_TURRET - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							SYNC_SPECTATOR_CELEBRATION_GLOBALS		
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════

STRUCT SCRIPT_EVENT_DATA_SYNC_SPECTATOR_CELEBRATION_GLOBALS_1
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iRpGained 
	INT iRpStarted 
	INT iCurrentLevelStartPoints 
	INT iCurrentLevelEndPoints 
	INT iCurrentLevel 
	INT iNextLevel 
	INT iMaximumTake
	INT iActualTake
	INT iMyCutPercentage
	INT iMyTake
	BOOL bDifficultyHighEnoughForEliteChallenge 
	INT iNumEliteChallengeComponents
	BOOL bEliteChallengeComplete
	INT iEliteChallengeBonusValue
	BOOL bFirstTimeBonusShouldBeShown
	INT iFirstTimeBonusValue
	BOOL bOrderBonusShouldBeShown
	INT iOrderBonusValue
	BOOL bSameTeamBonusShouldBeShown
	INT iSameTeamBonusValue
	BOOL bUltimateBonusShouldBeShown
	INT iUltimateBonusValue
	BOOL bMemberBonusShouldBeShown
	INT iMemberBonusValue
	BOOL bIAmHeistLeader
	INT iNumJobPoints
ENDSTRUCT

//Purpose: Sync data for spectator
PROC BROADCAST_SYNC_SPECTATOR_CELEBRATION_GLOBALS_1(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_SYNC_SPECTATOR_CELEBRATION_GLOBALS_1 Event
	Event.Details.Type = SCRIPT_EVENT_SYNC_SPECTATOR_CELEBRATION_GLOBALS_1
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iRpGained  = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iRpGained 
	Event.iRpStarted  = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iRpStarted 
	Event.iCurrentLevelStartPoints  = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iCurrentLevelStartPoints 
	Event.iCurrentLevelEndPoints = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iCurrentLevelEndPoints
	Event.iCurrentLevel = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iCurrentLevel
	Event.iNextLevel  = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iNextLevel 
	Event.iMaximumTake = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iMaximumTake
	Event.iActualTake = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iActualTake
	Event.iMyCutPercentage = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iMyCutPercentage
	Event.iMyTake = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iMyTake
	Event.bDifficultyHighEnoughForEliteChallenge  = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bDifficultyHighEnoughForEliteChallenge 
	Event.iNumEliteChallengeComponents = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iNumEliteChallengeComponents
	Event.bEliteChallengeComplete = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bEliteChallengeComplete
	Event.iEliteChallengeBonusValue = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iEliteChallengeBonusValue
	Event.bFirstTimeBonusShouldBeShown = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bFirstTimeBonusShouldBeShown
	Event.iFirstTimeBonusValue = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iFirstTimeBonusValue
	Event.bOrderBonusShouldBeShown = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bOrderBonusShouldBeShown
	Event.iOrderBonusValue = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iOrderBonusValue
	Event.bSameTeamBonusShouldBeShown = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bSameTeamBonusShouldBeShown
	Event.iSameTeamBonusValue = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iSameTeamBonusValue
	Event.bUltimateBonusShouldBeShown = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bUltimateBonusShouldBeShown
	Event.iUltimateBonusValue = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iUltimateBonusValue
	Event.bMemberBonusShouldBeShown = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bMemberBonusShouldBeShown
	Event.iMemberBonusValue = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iMemberBonusValue
	Event.bIAmHeistLeader = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bIAmHeistLeader
	Event.iNumJobPoints = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iNumJobPoints
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_SYNC_SPECTATOR_CELEBRATION_GLOBALS_1 - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("SCRIPT_SYNC_SPECTATOR_CELEBRATION_GLOBALS_1 - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_SYNC_SPECTATOR_CELEBRATION_GLOBALS_2
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bShowEliteComponentMissionTime
	INT iTargetMissionTime
	INT iMissionTime
	BOOL bMissionTimeChallengeComplete

	BOOL bShowEliteComponentVehicleDamage
	INT iVehicleDamagePercentageTarget
	INT iVehicleDamagePercentageActual
	BOOL bVehicleDamagePercentagePassed

	BOOL bShowEliteComponentRachDamage
	INT iRachDamagePercentageTarget
	INT iRachDamagePercentageActual
	BOOL bRachDamagePercentagePassed

	BOOL bShowEliteComponentExtractionTime
	INT iTargetExtractionTime
	INT iExtractionTime
	BOOL bExtractionTimeChallengeComplete

	BOOL bShowEliteComponentNumPedKills
	INT iNumPedKillsTarget
	INT iNumPedKills
	BOOL bNumPedKillsChallengeComplete

	BOOL bShowEliteComponentNooseCalled
	BOOL bNooseCalled

	BOOL bShowEliteComponentHealthDamage
	INT iHealthDamagePercentageTarget
	INT iHealthDamagePercentageActual
	BOOL bHealthDamagePercentagePassed

	BOOL bShowEliteComponentLivesLost
	BOOL bNumLivesLostChallengeComplete

	BOOL bShowEliteComponentTripSkip
	BOOL bShowEliteComponentDroppedToDirect
	BOOL bShowEliteComponentDidQuickRestart
	
	BOOL bShowEliteComponentNumPedHeadshots
	INT iNumPedHeadshotsTarget
	INT iNumPedHeadshots
	BOOL bNumPedHeadshotsChallengeComplete

	BOOL bShowEliteComponentHackFailed
	INT iNumHacksFailedTarget
	INT iNumHacksFailed
	BOOL bNumHackFailedChallengeComplete
	
	BOOL bShowEliteComponentLootBagFull
	BOOL bLootBagFullChallengeComplete
	
ENDSTRUCT

//Purpose: Sync data for spectator
PROC BROADCAST_SYNC_SPECTATOR_CELEBRATION_GLOBALS_2(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_SYNC_SPECTATOR_CELEBRATION_GLOBALS_2 Event
	Event.Details.Type = SCRIPT_EVENT_SYNC_SPECTATOR_CELEBRATION_GLOBALS_2
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.bShowEliteComponentMissionTime = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentMissionTime 
	Event.iTargetMissionTime  = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iTargetMissionTime
	Event.iMissionTime  = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iMissionTime
	Event.bMissionTimeChallengeComplete = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bMissionTimeChallengeComplete
	Event.bShowEliteComponentVehicleDamage = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentVehicleDamage
	Event.iVehicleDamagePercentageTarget = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iVehicleDamagePercentageTarget
	Event.iVehicleDamagePercentageActual = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iVehicleDamagePercentageActual
	Event.bVehicleDamagePercentagePassed = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bVehicleDamagePercentagePassed
	Event.bShowEliteComponentRachDamage = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentRachDamage
	Event.iRachDamagePercentageTarget = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iRachDamagePercentageTarget
	Event.iRachDamagePercentageActual = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iRachDamagePercentageActual
	Event.bRachDamagePercentagePassed = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bRachDamagePercentagePassed
	Event.bShowEliteComponentExtractionTime = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentExtractionTime
	Event.iTargetExtractionTime = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iTargetExtractionTime
	Event.iExtractionTime = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iExtractionTime
	Event.bExtractionTimeChallengeComplete = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bExtractionTimeChallengeComplete
	Event.bShowEliteComponentNumPedKills = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentNumPedKills
	Event.iNumPedKillsTarget = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iNumPedKillsTarget
	Event.iNumPedKills = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iNumPedKills
	Event.bNumPedKillsChallengeComplete = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bNumPedKillsChallengeComplete
	Event.bShowEliteComponentNooseCalled = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentNooseCalled
	Event.bNooseCalled = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bNooseCalled
	Event.bShowEliteComponentHealthDamage = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentHealthDamage
	Event.iHealthDamagePercentageTarget = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iHealthDamagePercentageTarget
	Event.iHealthDamagePercentageActual = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iHealthDamagePercentageActual
	Event.bHealthDamagePercentagePassed = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bHealthDamagePercentagePassed
	Event.bShowEliteComponentLivesLost = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentLivesLost
	Event.bNumLivesLostChallengeComplete = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bNumLivesLostChallengeComplete
	Event.bShowEliteComponentTripSkip = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentTripSkip
	Event.bShowEliteComponentDroppedToDirect = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentDroppedToDirect
	Event.bShowEliteComponentDidQuickRestart = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentDidQuickRestart
	
	Event.bShowEliteComponentNumPedHeadshots = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentNumPedHeadshots 
 	Event.iNumPedHeadshotsTarget = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iNumPedHeadshotsTarget 
	Event.iNumPedHeadshots = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iNumPedHeadshots 
	Event.bNumPedHeadshotsChallengeComplete = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bNumPedHeadshotsChallengeComplete 

 	Event.bShowEliteComponentHackFailed = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentHackFailed 
	Event.iNumHacksFailedTarget = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iNumHacksFailedTarget 
	Event.iNumHacksFailed = g_TransitionSessionNonResetVars.sGlobalCelebrationData.iNumHacksFailed
 	Event.bNumHackFailedChallengeComplete = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bNumHackFailedChallengeComplete 
 	
	Event.bShowEliteComponentLootBagFull = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bShowEliteComponentLootBagFull 
 	Event.bLootBagFullChallengeComplete = g_TransitionSessionNonResetVars.sGlobalCelebrationData.bLootBagFullChallengeComplete 
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_SYNC_SPECTATOR_CELEBRATION_GLOBALS_2 - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("SCRIPT_SYNC_SPECTATOR_CELEBRATION_GLOBALS_2 - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║							BROADCAST TEXT MESSAGE																		
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_TEXT_MESSAGE_USING_LITERAL
	STRUCT_EVENT_COMMON_DETAILS Details 
	TEXT_LABEL_63 tlLiteralText
ENDSTRUCT

//PURPOSE: Broadcast to a Text Message
PROC BROADCAST_TEXT_MESSAGE_USING_LITERAL(TEXT_LABEL_63 tlLiteralText, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_TEXT_MESSAGE_USING_LITERAL Event
	Event.Details.Type = SCRIPT_EVENT_TEXT_MESSAGE_USING_LITERAL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.tlLiteralText = tlLiteralText
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_TEXT_MESSAGE_USING_LITERAL - SENT BY ", GET_PLAYER_NAME(PLAYER_ID()))
		PRINTLN("     ----->    SCRIPT_EVENT_TEXT_MESSAGE_USING_LITERAL - MESSAGE = ", tlLiteralText)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_TEXT_MESSAGE_USING_LITERAL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							TELL PLAYERS TO LEAVE VEHICLE																
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_LEAVE_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details 
	FLOAT fStopDistance
	INT iStopTime
	BOOL bStopVehicle
	BOOL bOverrideLocalFlags
	BOOL bTicker
	PLAYER_INDEX OwnerID
	INT iFrameCount
ENDSTRUCT

//PURPOSE: Broadcast for players to leave vehicle
PROC BROADCAST_LEAVE_VEHICLE(INT iPlayerFlags,BOOL bStopVehicle, FLOAT fStopDistance, INT iStopTime, BOOL bOverrideLocalFlags = FALSE, BOOL bTicker = FALSE, INT iOwnerID = -1)
	SCRIPT_EVENT_DATA_LEAVE_VEHICLE Event
	Event.Details.Type = SCRIPT_EVENT_LEAVE_VEHICLE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.OwnerID = INT_TO_NATIVE(PLAYER_INDEX, iOwnerID)
	Event.bStopVehicle = bStopVehicle
	Event.bOverrideLocalFlags = bOverrideLocalFlags
	Event.fStopDistance = fStopDistance
	Event.iStopTime	= iStopTime
	Event.bTicker	= bTicker
	Event.iFrameCount = GET_FRAME_COUNT()
	
	DEBUG_PRINTCALLSTACK()
	PRINTLN("BROADCAST_LEAVE_VEHICLE called with ", iPlayerFlags, ", ", bStopVehicle, ", ", fStopDistance, ", ", iStopTime, ", ", bOverrideLocalFlags, ", ", bTicker, ", ", iOwnerID)
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_LEAVE_VEHICLE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							TELL PLAYERS TO CLEANUP PV															
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CLEANUP_PV
	STRUCT_EVENT_COMMON_DETAILS Details 
	BOOL bDelete 
	BOOL bDoFadeOut
	BOOL bNotDuringRespawn
ENDSTRUCT

//PURPOSE: Broadcast for players to leave vehicle
PROC BROADCAST_CLEANUP_PV(BOOL bDelete, BOOL bDoFadeOut, BOOL bNotDuringRespawn)
	SCRIPT_EVENT_DATA_CLEANUP_PV Event
	Event.Details.Type = SCRIPT_EVENT_CLEANUP_PV
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bDelete = bDelete
	Event.bDoFadeOut = bDoFadeOut
	Event.bNotDuringRespawn = bNotDuringRespawn
	
	#IF IS_DEBUG_BUILD
	PRINTLN("[personal_vehilce] BROADCAST_CLEANUP_PV: called with ", bDelete, ", ", bDoFadeOut)
	DEBUG_PRINTCALLSTACK()
	#ENDIF
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	

ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							TELL PLAYERS TO CLEANUP TRUCK						║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CLEANUP_TRUCK
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bDelete
	BOOL bDoFadeOut
	BOOL bNotDuringRespawn
ENDSTRUCT

//PURPOSE: Broadcast for players to cleanup truck cab
PROC BROADCAST_CLEANUP_TRUCK_CAB(BOOL bDelete, BOOL bDoFadeOut, BOOL bNotDuringRespawn)
	SCRIPT_EVENT_DATA_CLEANUP_TRUCK Event
	Event.Details.Type = SCRIPT_EVENT_CLEANUP_TRUCK_CAB
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bDelete = bDelete
	Event.bDoFadeOut = bDoFadeOut
	Event.bNotDuringRespawn = bNotDuringRespawn
	
	#IF IS_DEBUG_BUILD
	PRINTLN("[personal_vehilce] BROADCAST_CLEANUP_TRUCK_CAB: called with ", bDelete, ", ", bDoFadeOut)
	DEBUG_PRINTCALLSTACK()
	#ENDIF
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

//PURPOSE: Broadcast for players to cleanup truck trailer
PROC BROADCAST_CLEANUP_TRUCK_TRAILER(BOOL bDelete, BOOL bDoFadeOut, BOOL bNotDuringRespawn)
	SCRIPT_EVENT_DATA_CLEANUP_TRUCK Event
	Event.Details.Type = SCRIPT_EVENT_CLEANUP_TRUCK_TRAILER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bDelete = bDelete
	Event.bDoFadeOut = bDoFadeOut
	Event.bNotDuringRespawn = bNotDuringRespawn
	
	#IF IS_DEBUG_BUILD
	PRINTLN("[personal_vehilce] BROADCAST_CLEANUP_TRUCK_TRAILER: called with ", bDelete, ", ", bDoFadeOut)
	DEBUG_PRINTCALLSTACK()
	#ENDIF
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							TELL PLAYERS TO CLEANUP AIRCRAFT					║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CLEANUP_AVENGER
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bDelete
	BOOL bDoFadeOut
	BOOL bNotDuringRespawn
ENDSTRUCT

//PURPOSE: Broadcast for players to cleanup avenger
PROC BROADCAST_CLEANUP_AVENGER(BOOL bDelete, BOOL bDoFadeOut, BOOL bNotDuringRespawn)
	SCRIPT_EVENT_DATA_CLEANUP_AVENGER Event
	Event.Details.Type = SCRIPT_EVENT_CLEANUP_AVENGER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bDelete = bDelete
	Event.bDoFadeOut = bDoFadeOut
	Event.bNotDuringRespawn = bNotDuringRespawn
	
	#IF IS_DEBUG_BUILD
	PRINTLN("[personal_vehilce] BROADCAST_CLEANUP_AVENGER: called with ", bDelete, ", ", bDoFadeOut)
	DEBUG_PRINTCALLSTACK()
	#ENDIF
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							TELL PLAYERS TO CLEANUP HACKER TRUCK				║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CLEANUP_HACKER_TRUCK
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bDelete
	BOOL bDoFadeOut
	BOOL bNotDuringRespawn
ENDSTRUCT

//PURPOSE: Broadcast for players to cleanup Truck_1 cab
PROC BROADCAST_CLEANUP_HACKER_TRUCK_CAB(BOOL bDelete, BOOL bDoFadeOut, BOOL bNotDuringRespawn)
	SCRIPT_EVENT_DATA_CLEANUP_HACKER_TRUCK Event
	Event.Details.Type = SCRIPT_EVENT_CLEANUP_HACKER_TRUCK
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bDelete = bDelete
	Event.bDoFadeOut = bDoFadeOut
	Event.bNotDuringRespawn = bNotDuringRespawn
	
	#IF IS_DEBUG_BUILD
	PRINTLN("[personal_vehilce] BROADCAST_CLEANUP_HACKER_TRUCK_CAB: called with ", bDelete, ", ", bDoFadeOut)
	DEBUG_PRINTCALLSTACK()
	#ENDIF
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					TELL PLAYER TO CREATE HACKER TRUCK UNDER MAP				║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CREATE_HACKER_TRUCK_UNDER_MAP
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bConfirm
ENDSTRUCT

//PURPOSE: Broadcast for property owner to create truck under the map
PROC BROADCAST_CREATE_HACKER_TRUCK_UNDER_MAP(PLAYER_INDEX pOwner, BOOL bCreationConfirmation)
	SCRIPT_EVENT_DATA_CREATE_HACKER_TRUCK_UNDER_MAP Event
	Event.Details.Type = SCRIPT_EVENT_CREATE_HACKER_TRUCK_UNDER_MAP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bConfirm = bCreationConfirmation
	
	INT iPlayerFlag
	IF pOwner != INVALID_PLAYER_INDEX()
		SET_BIT(iPlayerFlag, NATIVE_TO_INT(pOwner))
	ENDIF

	#IF IS_DEBUG_BUILD
	PRINTLN("BROADCAST_CLEANUP_HACKER_TRUCK_CAB: called Sending confirmation: ",  bCreationConfirmation, " , GET_PLAYER_NAME(pOwner)")
	#ENDIF
	
	IF NOT (iPlayerFlag = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlag)
	ELSE
		PRINTLN("BROADCAST_CLEANUP_HACKER_TRUCK_CAB: iPlayerFlag is 0 ")
	ENDIF
ENDPROC

#IF FEATURE_HEIST_ISLAND
//╔═════════════════════════════════════════════════════════════════════════════╗
//║							TELL PLAYERS TO CLEANUP SUBMARINE					║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CLEANUP_SUBMARINE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bDelete
	BOOL bDoFadeOut
	BOOL bNotDuringRespawn
ENDSTRUCT

//PURPOSE: Broadcast for players to cleanup Submarine cab
PROC BROADCAST_CLEANUP_SUBMARINE_CAB(BOOL bDelete, BOOL bDoFadeOut, BOOL bNotDuringRespawn)
	SCRIPT_EVENT_DATA_CLEANUP_SUBMARINE Event
	Event.Details.Type = SCRIPT_EVENT_CLEANUP_SUBMARINE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bDelete = bDelete
	Event.bDoFadeOut = bDoFadeOut
	Event.bNotDuringRespawn = bNotDuringRespawn
	
	#IF IS_DEBUG_BUILD
	PRINTLN("[personal_vehilce] BROADCAST_CLEANUP_SUBMARINE_CAB: called with ", bDelete, ", ", bDoFadeOut)
	DEBUG_PRINTCALLSTACK()
	#ENDIF
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							TELL PLAYERS TO CLEANUP SUBMARINE DINGHY			║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CLEANUP_SUBMARINE_DINGHY
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bDelete
	BOOL bDoFadeOut
	BOOL bNotDuringRespawn
ENDSTRUCT

//PURPOSE: Broadcast for players to cleanup Submarine cab
PROC BROADCAST_CLEANUP_SUBMARINE_DINGHY_CAB(BOOL bDelete, BOOL bDoFadeOut, BOOL bNotDuringRespawn)
	SCRIPT_EVENT_DATA_CLEANUP_SUBMARINE_DINGHY Event
	Event.Details.Type = SCRIPT_EVENT_CLEANUP_SUBMARINE_DINGHY
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bDelete = bDelete
	Event.bDoFadeOut = bDoFadeOut
	Event.bNotDuringRespawn = bNotDuringRespawn
	
	#IF IS_DEBUG_BUILD
	PRINTLN("[personal_vehilce] BROADCAST_CLEANUP_SUBMARINE_DINGHY_CAB: called with ", bDelete, ", ", bDoFadeOut)
	DEBUG_PRINTCALLSTACK()
	#ENDIF
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				BROADCAST CLUB DJ MUSIC DATA BETWEEN SCRIPT HOSTS				║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_DJ_CLUB_MUSIC_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	DJ_SERVER_DATA DJServerData
	CLUB_LOCATIONS eClubLocation
ENDSTRUCT

//PURPOSE: Broadcast club DJ data to freemode host
PROC BROADCAST_DATA_DJ_CLUB_MUSIC_DATA(CLUB_LOCATIONS eClubLocation, DJ_SERVER_DATA &DJServerData)
	SCRIPT_EVENT_DATA_DJ_CLUB_MUSIC_DATA Event
	Event.Details.Type = SCRIPT_EVENT_DJ_CLUB_MUSIC_DATA
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.DJServerData = DJServerData
	Event.eClubLocation = eClubLocation
	
	PLAYER_INDEX pHost = NETWORK_GET_HOST_OF_SCRIPT(FREEMODE_SCRIPT())

	INT iPlayerFlags = SPECIFIC_PLAYER(pHost)
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	
	#IF IS_DEBUG_BUILD
	PRINTLN("[CLUB_MUSIC] BROADCAST_DATA_DJ_CLUB_MUSIC_DATA: called ")
	DEBUG_PRINTCALLSTACK()
	#ENDIF
ENDPROC

#ENDIF

#IF FEATURE_DLC_2_2022

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							TELL PLAYERS TO CLEANUP ACID LAB					║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CLEANUP_ACID_LAB
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bDelete
	BOOL bDoFadeOut
	BOOL bNotDuringRespawn
ENDSTRUCT

//PURPOSE: Broadcast for players to cleanup Truck_1 cab
PROC BROADCAST_CLEANUP_ACID_LAB_CAB(BOOL bDelete, BOOL bDoFadeOut, BOOL bNotDuringRespawn)
	SCRIPT_EVENT_DATA_CLEANUP_ACID_LAB Event
	Event.Details.Type = SCRIPT_EVENT_CLEANUP_ACID_LAB
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bDelete = bDelete
	Event.bDoFadeOut = bDoFadeOut
	Event.bNotDuringRespawn = bNotDuringRespawn
	
	#IF IS_DEBUG_BUILD
	PRINTLN("[personal_vehilce] BROADCAST_CLEANUP_ACID_LAB_CAB: called with ", bDelete, ", ", bDoFadeOut)
	DEBUG_PRINTCALLSTACK()
	#ENDIF
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					TELL PLAYER TO CREATE ACID LAB UNDER MAP					║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CREATE_ACID_LAB_UNDER_MAP
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bConfirm
ENDSTRUCT

//PURPOSE: Broadcast for property owner to create truck under the map
PROC BROADCAST_CREATE_ACID_LAB_UNDER_MAP(PLAYER_INDEX pOwner, BOOL bCreationConfirmation)
	SCRIPT_EVENT_DATA_CREATE_ACID_LAB_UNDER_MAP Event
	Event.Details.Type = SCRIPT_EVENT_CREATE_ACID_LAB_UNDER_MAP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bConfirm = bCreationConfirmation
	
	INT iPlayerFlag
	IF pOwner != INVALID_PLAYER_INDEX()
		SET_BIT(iPlayerFlag, NATIVE_TO_INT(pOwner))
	ENDIF

	#IF IS_DEBUG_BUILD
	PRINTLN("BROADCAST_CREATE_ACID_LAB_UNDER_MAP: called Sending confirmation: ",  bCreationConfirmation, " , GET_PLAYER_NAME(pOwner)")
	#ENDIF
	
	IF NOT (iPlayerFlag = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlag)
	ELSE
		PRINTLN("BROADCAST_CREATE_ACID_LAB_UNDER_MAP: iPlayerFlag is 0 ")
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				 			TELL PLAYERS TO LOCK ACID LAB						║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ══════════════════════════╡  DATA STRUCTURES  ╞═══════════════════════════════
STRUCT SCRIPT_EVENT_DATA_UPDATE_ACID_LAB_LOCKSTATE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iLockState
ENDSTRUCT

PROC BROADCAST_SET_ACID_LAB_LOCK_STATE(INT iLockState)
	SCRIPT_EVENT_DATA_UPDATE_ACID_LAB_LOCKSTATE Event
	Event.Details.Type = SCRIPT_EVENT_UPDATE_ACID_LAB_LOCKSTATE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iLockState = iLockState
	
	PRINTLN("[personal_vehicle] BROADCAST_SET_ACID_LAB_LOCK_STATE - called with ", iLockState)
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							TELL PLAYERS TO CLEANUP SUPPORT BIKE				║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CLEANUP_SUPPORT_BIKE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bDelete
	BOOL bDoFadeOut
	BOOL bNotDuringRespawn
ENDSTRUCT

//PURPOSE: Broadcast for players to cleanup Submarine cab
PROC BROADCAST_CLEANUP_SUPPORT_BIKE(BOOL bDelete, BOOL bDoFadeOut, BOOL bNotDuringRespawn)
	SCRIPT_EVENT_DATA_CLEANUP_SUPPORT_BIKE Event
	Event.Details.Type = SCRIPT_EVENT_CLEANUP_SUPPORT_BIKE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bDelete = bDelete
	Event.bDoFadeOut = bDoFadeOut
	Event.bNotDuringRespawn = bNotDuringRespawn
	
	#IF IS_DEBUG_BUILD
	PRINTLN("[personal_vehilce] BROADCAST_CLEANUP_SUPPORT_BIKE: called with ", bDelete, ", ", bDoFadeOut)
	DEBUG_PRINTCALLSTACK()
	#ENDIF
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

#ENDIF

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							TELL PLAYER TO SET ARRESTABLE STATE ON THEMSELVES																
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_SET_PLAYER_ARRESTABLE
	STRUCT_EVENT_COMMON_DETAILS Details 
	BOOL bArrestable
ENDSTRUCT

//PURPOSE: Broadcast for players to leave vehicle
PROC BROADCAST_SET_PLAYER_ARRESTABLE(INT iPlayerFlags,BOOL bArrestable)
	SCRIPT_EVENT_DATA_SET_PLAYER_ARRESTABLE Event
	Event.Details.Type = SCRIPT_EVENT_SET_PLAYER_ARRESTABLE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bArrestable = bArrestable
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SET_PLAYER_ARRESTABLE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//force conceal vehicle
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_FORCE_CONCEAL_PERSONAL_VEHICLE_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bForceConceal
	INT iUniqueSessionHash0
	INT iUniqueSessionHash1
ENDSTRUCT

PROC BROADCAST_FORCE_CONCEAL_PERSONAL_VEHICLE(INT iPlayerFlags,BOOL bForceConceal)
	SCRIPT_EVENT_FORCE_CONCEAL_PERSONAL_VEHICLE_DATA Event
	Event.Details.Type = SCRIPT_EVENT_FORCE_CONCEAL_PERSONAL_VEHICLE
	Event.bForceConceal = bForceConceal
	Event.Details.FromPlayerIndex = PLAYER_ID()
	GET_THIS_SESSION_UNIQUE_EVENT_IDS(Event.iUniqueSessionHash0, Event.iUniqueSessionHash1)
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_FORCE_CONCEAL_PERSONAL_VEHICLE - broadcasting wih: ",bForceConceal)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		PRINTLN("BROADCAST_FORCE_CONCEAL_PERSONAL_VEHICLE - playerflags = 0 so not broadcasting")	
	ENDIF	
ENDPROC

#IF FEATURE_CASINO
//╔═════════════════════════════════════════════════════════════════════════════╗
//║						TELL PLAYERS TO CREATE BJACK CARD						
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_BJACK_CARD
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCardIndex
	INT iCardEnumID
	BOOL bDealerCard
	BOOL bLastCard
ENDSTRUCT

//PURPOSE: Broadcast for players to create bjack card
PROC BROADCAST_BJACK_CARD(INT iCardIndex, INT iCardEnumID, BOOL bDealerCard, BOOL bLastCard = FALSE)
	SCRIPT_EVENT_DATA_BJACK_CARD Event
	Event.Details.Type = SCRIPT_EVENT_BJACK_CARD
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iCardIndex = iCardIndex
	Event.iCardEnumID = iCardEnumID
	Event.bDealerCard = bDealerCard
	Event.bLastCard = bLastCard
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC
#ENDIF

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							BOUNTY EVENT																
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_BOUNTY
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerID
	INT iResultBS
	INT iBountyValue
	INT iTimeSinceBountyStart
	INT iVariation
	GAMER_HANDLE bountyPlacer
	INT iUniqueSessionHash0
	INT iUniqueSessionHash1
ENDSTRUCT

PROC BROADCAST_SET_BOUNTY_ON_PLAYER(INT iPlayerFlags,PLAYER_INDEX targetedPlayer,INT iBountyValue, INT iVariation= 0, BOOL bFirstSet = TRUE)
	SCRIPT_EVENT_DATA_BOUNTY Event
	Event.Details.Type = SCRIPT_EVENT_SET_BOUNTY_ON_PLAYER
	Event.iBountyValue =  iBountyValue
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.playerID = targetedPlayer
	Event.iVariation = iVariation
	GET_THIS_SESSION_UNIQUE_EVENT_IDS(Event.iUniqueSessionHash0, Event.iUniqueSessionHash1)
	IF bFirstSet
		SET_BIT(Event.iResultBS,0)
	ENDIF
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SET_PLAYER_TARGET_OF_BOUNTY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//PROC BROADCAST_JOIN_BOUNTY_ON_PLAYER(INT iPlayerFlags,PLAYER_INDEX targetedPlayer)
//	SCRIPT_EVENT_DATA_BOUNTY Event
//	SET_BIT(MPGlobalsAmbience.playerBounty.iPlayersYouAreTargettingBS,NATIVE_TO_INT(targetedPlayer))
//	Event.Details.Type = SCRIPT_EVENT_JOIN_BOUNTY_ON_PLAYER
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.playerID = targetedPlayer
//	NET_PRINT("BROADCAST_JOIN_BOUNTY_ON_PLAYER") NET_NL()		
//	IF NOT (iPlayerFlags = 0)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_JOIN_BOUNTY_ON_PLAYER - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF	
//ENDPROC

PROC BROADCAST_BOUNTY_OVER(INT iPlayerFlags,PLAYER_INDEX killer, GAMER_HANDLE bountyPlacer, INT iResultBS, INT iTimeSinceBountyStart, INT iValue, BOOL bCheckSave)
	
	IF NOT bCheckSave
		SCRIPT_EVENT_DATA_BOUNTY Event
		Event.Details.Type = SCRIPT_EVENT_BOUNTY_OVER
		Event.Details.FromPlayerIndex = PLAYER_ID()
		Event.iResultBS = iResultBS
		Event.playerID = killer
		Event.iTimeSinceBountyStart = iTimeSinceBountyStart
		Event.iBountyValue = iValue
		Event.bountyPlacer = bountyPlacer
		GET_THIS_SESSION_UNIQUE_EVENT_IDS(Event.iUniqueSessionHash0, Event.iUniqueSessionHash1)
		IF IS_GAMER_HANDLE_VALID(bountyPlacer)
			IF NOT NETWORK_IS_GAMER_IN_MY_SESSION(bountyPlacer)
				scrBountyInboxMsg_Data bountyMessage
				
				bountyMessage.tl31FromGamerTag = 	GET_PLAYER_NAME(PLAYER_ID())
				IF IS_NET_PLAYER_OK(killer,FALSE)
					bountyMessage.tl31TargetGamerTag = GET_PLAYER_NAME(killer)
				ENDIF
				bountyMessage.iOutcome = iResultBS
				bountyMessage.iCash = iValue
				bountyMessage.iRank = GlobalplayerBD_FM[NATIVE_TO_INT(PLAYER_ID())].scoreData.iRank
				bountyMessage.iTime = iTimeSinceBountyStart
				PRINTLN("----BOUNTY OVER MESSAGE INBOX SEND------")
				PRINTLN("Target: ",bountyMessage.tl31FromGamerTag )
				PRINTLN("Killer: ",bountyMessage.tl31TargetGamerTag )
				PRINTLN("Outcome: ",bountyMessage.iOutcome )
				PRINTLN("Cash: ",bountyMessage.iCash )
				PRINTLN("Rank: ",bountyMessage.iRank )
				PRINTLN("Time: ",bountyMessage.iTime )
				SC_INBOX_MESSAGE_PUSH_GAMER_T0_RECIP_LIST(bountyPlacer)
				SC_INBOX_SEND_BOUNTY_TO_RECIP_LIST(bountyMessage)
			ENDIF
		ELSE
			PRINTLN("Bounty placer not valid!")
		ENDIF
		GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].iBountyValue = iValue
		IF IS_BIT_SET(Event.iResultBS,BOUNTY_RESULT_TIME_UP)
			GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].bountyClaimer = PLAYER_ID()
		ELSE
			GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].bountyClaimer = Event.playerID
		ENDIF
		PRINTLN("Bounty over value: ",GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].iBountyValue)
		IF NOT (iPlayerFlags = 0)
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
		ELSE
			NET_PRINT("BROADCAST_SET_PLAYER_TARGET_OF_ASSASSINATION - playerflags = 0 so not broadcasting") NET_NL()		
		ENDIF
		
		MPGlobalsAmbience.playerBounty.iBountyOnLocalPlayer = 0
		PRINTLN("BROADCAST_BOUNTY_OVER() - send event data")
	ELSE
		SET_BIT(MPGlobalsAmbience.BountySaveCheck.iBS,BOUNTY_SAVE_CHECK_BS_TRIGGERED)
		MPGlobalsAmbience.BountySaveCheck.iPlayerFlags = iPlayerFlags
		MPGlobalsAmbience.BountySaveCheck.killer = killer
		MPGlobalsAmbience.BountySaveCheck.bountyPlacer = bountyPlacer
		MPGlobalsAmbience.BountySaveCheck.iResultBS = iResultBS
		MPGlobalsAmbience.BountySaveCheck.iTimeSinceBountyStart = iTimeSinceBountyStart
		MPGlobalsAmbience.BountySaveCheck.iValue = iValue
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.iTimePassedSoFar = 0
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.iBountyValue = 0

		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.gh_BountyPlacer.Data1 = 0
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.gh_BountyPlacer.Data2 = 0
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.gh_BountyPlacer.Data3 = 0
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.gh_BountyPlacer.Data4 = 0
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.gh_BountyPlacer.Data5 = 0
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.gh_BountyPlacer.Data6 = 0
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.gh_BountyPlacer.Data7 = 0
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.gh_BountyPlacer.Data8 = 0
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.gh_BountyPlacer.Data9 = 0
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.gh_BountyPlacer.Data10 = 0
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.gh_BountyPlacer.Data11 = 0
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.gh_BountyPlacer.Data12 = 0
		g_savedMPGlobalsNew.g_savedMPGlobals[GET_SAVE_GAME_ARRAY_SLOT()].MpSavedBounty.gh_BountyPlacer.Data13 = 0
		#IF IS_DEBUG_BUILD
			DEBUG_PRINTCALLSTACK()
			NET_NL()NET_PRINT("REQUEST_SAVE: requested by ")NET_PRINT(GET_THIS_SCRIPT_NAME()) NET_NL()
		#ENDIF
	//	g_bPrivate_SaveRequested[0] = TRUE
		REQUEST_SAVE(SSR_REASON_FM_PLAYER_BOUNTY, STAT_SAVETYPE_SCRIPT_MP_GLOBALS)			
		PRINTLN("BROADCAST_BOUNTY_OVER() - check save")
	ENDIF
ENDPROC
//
//// PURPOSE:
////	For sending a bounty completed notification message to the gamer's in teh recipiant 
////		list, as created with SC_INBOX_MESSAGE_PUSH_GAMER_T0_RECIP_LIST
//// PARAMS:
////	A filled out scrBountyInboxMsg_Data object to be serialized and sent
//NATIVE FUNC BOOL SC_INBOX_SEND_BOUNTY_TO_RECIP_LIST(scrBountyInboxMsg_Data& pBountyData)
//		ENDIF
//	ENDIF
//	NET_PRINT("BROADCAST_BOUNTY_OVER()") NET_NL()
//	IF NOT (iPlayerFlags = 0)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_SET_PLAYER_TARGET_OF_ASSASSINATION - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF
//ENDPROC

STRUCT SCRIPT_EVENT_DATA_SEND_POSIX_AND_HASHED_MAC
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iHeistHashedMac
	INT iHeistPosixTime
ENDSTRUCT

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							PERSONAL VEHICLE DOORS														
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_DOOR
	STRUCT_EVENT_COMMON_DETAILS Details
	SC_DOOR_LIST eDoor
	INT vehObjID
	BOOL bIgnoreIfDriver
	INT iOpenShutRequest
	BOOL bSwingFree
	BOOL bInstant
ENDSTRUCT

PROC BROADCAST_PERSONAL_VEHICLE_DOOR_OPEN(VEHICLE_INDEX theVeh,SC_DOOR_LIST eDoor, BOOL bSwingFree=FALSE, BOOL bInstant=FALSE, BOOL bIgnoreIfDriver = FALSE)
	SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_DOOR Event
	Event.Details.Type = SCRIPT_EVENT_OPEN_SHUT_PV_DOOR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vehObjID = NETWORK_ENTITY_GET_OBJECT_ID(theVeh)
	Event.eDoor =  eDoor
	Event.bIgnoreIfDriver = bIgnoreIfDriver
	Event.iOpenShutRequest = 1 // 0 = do nothing, 1 = open, 2 = shut
	Event.bSwingFree = bSwingFree
	Event.bInstant = bInstant
	NET_PRINT("BROADCAST_PERSONAL_VEHICLE_DOOR_OPEN - called by local player" ) NET_NL()	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC

PROC BROADCAST_PERSONAL_VEHICLE_DOOR_SHUT(VEHICLE_INDEX theVeh,SC_DOOR_LIST eDoor, BOOL bShutInstantly=FALSE, BOOL bIgnoreIfDriver = FALSE)
	SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_DOOR Event
	Event.Details.Type = SCRIPT_EVENT_OPEN_SHUT_PV_DOOR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vehObjID = NETWORK_ENTITY_GET_OBJECT_ID(theVeh)
	Event.eDoor =  eDoor
	Event.bIgnoreIfDriver = bIgnoreIfDriver
	Event.iOpenShutRequest = 2 // 0 = do nothing, 1 = open, 2 = shut
	Event.bInstant = bShutInstantly
	NET_PRINT("BROADCAST_PERSONAL_VEHICLE_DOOR_SHUT - called by local player" ) NET_NL()	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC
//╔═════════════════════════════════════════════════════════════════════════════╗
//║							PERSONAL VEHICLE NEON LIGHTS														
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_NEON
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bTurnOn
ENDSTRUCT

PROC BROADCAST_PERSONAL_VEHICLE_SET_NEON_LIGHTS(BOOL bTurnOn)
	SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_NEON Event
	Event.Details.Type = SCRIPT_EVENT_SET_PV_NEON_LIGHTS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bTurnOn = bTurnOn
	NET_PRINT("BROADCAST_PERSONAL_VEHICLE_SET_RADIO_STATION - called by local player" ) NET_NL()	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC
//╔═════════════════════════════════════════════════════════════════════════════╗
//║							CLUBHOUSE MISSION 														
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_CLUBHOUSE_MISSION
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iSelectedMission
ENDSTRUCT

//used by players to notify everyone that they launched a mission (with values 0,1,2 corresponding to mission wall slots)
PROC BROADCAST_CLUBHOUSE_MISSION_MISSION_LAUNCHED(INT iSelectedMission)
	SCRIPT_EVENT_DATA_CLUBHOUSE_MISSION Event
	Event.Details.Type = SCRIPT_EVENT_UPDATE_CLUBHOUSE_MISSION_LIST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iSelectedMission = iSelectedMission
	NET_PRINT("BROADCAST_CLUBHOUSE_MISSION_MISSION_LAUNCHED - called by local player, iSelectedMission:")NET_PRINT_INT(iSelectedMission)NET_NL()
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC

PROC BROADCAST_CLUBHOUSE_MISSION_WALL_REFRESHED()
	SCRIPT_EVENT_DATA_CLUBHOUSE_MISSION Event
	Event.Details.Type = SCRIPT_EVENT_UPDATE_CLUBHOUSE_MISSION_LIST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iSelectedMission = -1
	NET_PRINT("BROADCAST_CLUBHOUSE_MISSION_WALL_REFRESHED - called by local player, iSelectedMission:")NET_NL()
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							PERSONAL VEHICLE RADIO STATION														
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_RADIO
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bTurnOn
	INT iRadioStation
	BOOL bLoud
ENDSTRUCT

PROC BROADCAST_PERSONAL_VEHICLE_SET_RADIO_STATION(BOOL bTurnOn, INT iRadioStationID = 0, BOOL bLoud=TRUE)
	SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_RADIO Event
	Event.Details.Type = SCRIPT_EVENT_SET_PV_RADIO_STATION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRadioStation = iRadioStationID
	Event.bTurnOn = bTurnOn
	Event.bLoud = bLoud
	NET_PRINT("BROADCAST_PERSONAL_VEHICLE_SET_RADIO_STATION - called by local player" ) NET_NL()	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							PERSONAL VEHICLE ENGINE RUNNING													
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_ENGINE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bSet
	BOOL bNoDelay
ENDSTRUCT

PROC BROADCAST_PERSONAL_VEHICLE_SET_ENGINE_RUNNING(BOOL bSet, BOOL bNoDelay = TRUE)
	SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_ENGINE Event
	Event.Details.Type = SCRIPT_EVENT_LEAVE_PV_ENGINE_RUNNING
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bSet = bSet
	Event.bNoDelay = bNoDelay
	NET_PRINT("BROADCAST_PERSONAL_VEHICLE_SET_ENGINE_RUNNING - called by local player" ) NET_NL()	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							PERSONAL VEHICLE LIGHTS													
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_LIGHTS
	STRUCT_EVENT_COMMON_DETAILS Details
	VEHICLE_LIGHT_SETTING LightSetting
ENDSTRUCT

PROC BROADCAST_PERSONAL_VEHICLE_SET_LIGHTS(VEHICLE_LIGHT_SETTING LightSetting)
	SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_LIGHTS Event
	Event.Details.Type = SCRIPT_EVENT_SET_PV_LIGHTS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.LightSetting = LightSetting
	NET_PRINT("BROADCAST_PERSONAL_VEHICLE_SET_LIGHTS - called by local player" ) NET_NL()	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							PERSONAL VEHICLE STANCE													
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_STANCE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bSet
ENDSTRUCT

PROC BROADCAST_PERSONAL_VEHICLE_SET_STANCE(BOOL bSet)
	SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_STANCE Event
	Event.Details.Type = SCRIPT_EVENT_SET_PV_STANCE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bSet = bSet
	NET_PRINT("BROADCAST_PERSONAL_VEHICLE_SET_STANCE - called by local player" ) NET_NL()	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							PERSONAL VEHICLE ROOF													
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_ROOF
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bSet
ENDSTRUCT

PROC BROADCAST_PERSONAL_VEHICLE_SET_ROOF(BOOL bSet)
	SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_ROOF Event
	Event.Details.Type = SCRIPT_EVENT_SET_PV_ROOF
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bSet = bSet
	NET_PRINT("BROADCAST_PERSONAL_VEHICLE_SET_ROOF - called by local player" ) NET_NL()	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							PERSONAL VEHICLE HYDRAULICS													
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_HYDRAULICS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iSetting
ENDSTRUCT

PROC BROADCAST_PERSONAL_VEHICLE_SET_HYDRAULICS(INT iSetting)
	SCRIPT_EVENT_DATA_PERSONAL_VEHICLE_HYDRAULICS Event
	Event.Details.Type = SCRIPT_EVENT_SET_PV_HYDRAULICS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iSetting = iSetting
	NET_PRINT("BROADCAST_PERSONAL_VEHICLE_SET_HYDRAULICS - called by local player" ) NET_NL()	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							FW Weapon Pickup														
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_FM_PICKUP
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iLocation
	PLAYER_INDEX PlayerCollector
ENDSTRUCT

//PROC BROADCAST_COLLECTED_FM_WEAPON_PICKUP(INT iLocation)
//	SCRIPT_EVENT_DATA_FM_PICKUP Event
//	Event.Details.Type = SCRIPT_EVENT_COLLECTED_FM_PICKUP
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.iLocation =  iLocation
//	CPRINTLN(DEBUG_FMPICKUPS, "BROADCAST_COLLECTED_FM_WEAPON_PICKUP - called by local player, location ", iLocation)
//	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
//ENDPROC

PROC BROADCAST_REQUEST_TO_CLAIM_FM_WEAPON_PICKUP(INT iLocation)
	SCRIPT_EVENT_DATA_FM_PICKUP Event
	Event.Details.Type = SCRIPT_EVENT_CLAIM_FM_PICKUP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.PlayerCollector = PLAYER_ID() // use this to tell everyone which player is getting the pickup. 
	Event.iLocation = iLocation
	CPRINTLN(DEBUG_FMPICKUPS, "BROADCAST_REQUEST_TO_CLAIM_FM_WEAPON_PICKUP - called by local player, iGlobalPickupArrayPosition ", iLocation)
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC

PROC BROADCAST_RESPONSE_TO_CLAIM_FM_WEAPON_PICKUP(INT iLocation, PLAYER_INDEX PlayerID)
	SCRIPT_EVENT_DATA_FM_PICKUP Event
	Event.Details.Type = SCRIPT_EVENT_RESPONSE_TO_CLAIM_FM_PICKUP
	Event.Details.FromPlayerIndex = PLAYER_ID() 
	Event.PlayerCollector = PlayerID // use this to tell everyone which player is getting the pickup. 
	Event.iLocation = iLocation
	CPRINTLN(DEBUG_FMPICKUPS, "BROADCAST_RESPONSE_TO_CLAIM_FM_WEAPON_PICKUP - called by local player, location ", iLocation)
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerID))	
ENDPROC



//╔═════════════════════════════════════════════════════════════════════════════╗
//║							private yacht re-assignment														
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_REASSIGN_PRIVATE_YACHT
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vDesiredCoords
	YACHT_APPEARANCE Appearance
ENDSTRUCT

PROC BROADCAST_REASSIGN_MY_PRIVATE_YACHT_NEAR_COORDS(VECTOR vDesiredCoords, YACHT_APPEARANCE Appearance)
	SCRIPT_EVENT_DATA_REASSIGN_PRIVATE_YACHT Event
	Event.Details.Type = SCRIPT_EVENT_REASSIGN_PRIVATE_YACHT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vDesiredCoords = vDesiredCoords
	Event.Appearance = Appearance
	CPRINTLN(DEBUG_YACHT, "BROADCAST_REASSIGN_MY_PRIVATE_YACHT_NEAR_COORDS - called by local player, vDesiredCoords ", vDesiredCoords)
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC

PROC BROADCAST_RESERVE_PRIVATE_YACHT_NEAR_COORDS(VECTOR vDesiredCoords)
	SCRIPT_EVENT_DATA_REASSIGN_PRIVATE_YACHT Event
	Event.Details.Type = SCRIPT_EVENT_RESERVE_PRIVATE_YACHT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vDesiredCoords = vDesiredCoords
	CPRINTLN(DEBUG_YACHT, "BROADCAST_RESERVE_PRIVATE_YACHT_NEAR_COORDS - called by local player, vDesiredCoords ", vDesiredCoords)
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC



//╔═════════════════════════════════════════════════════════════════════════════╗
//║							private yacht air defence														
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_AIRDEF_EXPLOSION_PRIVATE_YACHT
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vCoordsExplosion
	VECTOR vCoordsGun
	INT iSphereIndex
	INT iYachtID
ENDSTRUCT

PROC BROADCAST_PRIVATE_YACHT_AIRDEF_EXPLOSION(VECTOR vCoordsExplosion, VECTOR vCoordsGun, INT iSphereIndex, INT iYachtID, BOOL bIncludeSendingPlayer = FALSE)
	SCRIPT_EVENT_DATA_AIRDEF_EXPLOSION_PRIVATE_YACHT Event
	Event.Details.Type = SCRIPT_EVENT_AIRDEF_EXPLOSION_PRIVATE_YACHT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vCoordsExplosion = vCoordsExplosion
	Event.vCoordsGun = vCoordsGun
	Event.iSphereIndex = iSphereIndex
	Event.iYachtID = iYachtID
	
	IF PLAYER_ID() != INVALID_PLAYER_INDEX()
		IF IS_BIT_SET(GlobalplayerBD_FM[NATIVE_TO_INT(PLAYER_ID())].propertyDetails.iHackerTruckModBS, PROPERTY_BROADCAST_HACKER_TRUCK_USING_DRONE) AND GlobalplayerBD_FM_4[NATIVE_TO_INT(PLAYER_ID())].eDroneType = DRONE_TYPE_SUBMARINE_MISSILE
			bIncludeSendingPlayer = TRUE
			CPRINTLN(DEBUG_YACHT, "[AIRDEF] BROADCAST_PRIVATE_YACHT_AIRDEF_EXPLOSION - player using submarine missile bIncludeSendingPlayer = TRUE")
		ENDIF
	ENDIF	
	
	CPRINTLN(DEBUG_YACHT, "[AIRDEF] BROADCAST_PRIVATE_YACHT_AIRDEF_EXPLOSION - called by local player, vCoordsExplosion ", vCoordsExplosion," vCoordsGun ", vCoordsGun, " iSphereIndex = ", iSphereIndex, " iYachtID = ", iYachtID, " ")
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(bIncludeSendingPlayer))	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							private yacht air defence dialogue														
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_AIRDEF_DIALOGUE_PRIVATE_YACHT
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL GentleChat
	BOOL AggroChat
	BOOL WarningFire
	INT ActiveForYachtId
ENDSTRUCT

PROC BROADCAST_PRIVATE_YACHT_AIRDEF_DIALOGUE(VEHICLE_INDEX aVeh, BOOL Gentle, BOOL AggroChat, BOOL Warning, INT ActiveForYachtId = -1)
	SCRIPT_EVENT_DATA_AIRDEF_DIALOGUE_PRIVATE_YACHT Event
	Event.Details.Type = SCRIPT_EVENT_AIRDEF_DIALOGUE_PRIVATE_YACHT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.GentleChat = Gentle
	Event.WarningFire = Warning
	Event.AggroChat = AggroChat
	Event.ActiveForYachtId = ActiveForYachtId
	
	IF aVeh = NULL
	AND ActiveForYachtId > -1
		IF ALL_PLAYERS(FALSE) > 0
			CPRINTLN(DEBUG_YACHT, "[AIRDEF] BROADCAST_PRIVATE_YACHT_AIRDEF_DIALOGUE - called by local player, Gentle ", Gentle," Warning ", Warning, "  AggroChat ", AggroChat, " ActiveForYachtId ", ActiveForYachtId," ")
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(FALSE))
		ELSE
			CPRINTLN(DEBUG_YACHT, "[AIRDEF] BROADCAST_PRIVATE_YACHT_AIRDEF_DIALOGUE - Skip broadcase as ALL_PLAYERS = 0 ")
		ENDIF
	ELSE
		IF ALL_PLAYERS_IN_VEHICLE(aVeh, FALSE) > 0
			CPRINTLN(DEBUG_YACHT, "[AIRDEF] BROADCAST_PRIVATE_YACHT_AIRDEF_DIALOGUE - called by local player, Gentle ", Gentle," Warning ", Warning, "  AggroChat ", AggroChat, " ")
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS_IN_VEHICLE(aVeh, FALSE))
		ELSE
			CPRINTLN(DEBUG_YACHT, "[AIRDEF] BROADCAST_PRIVATE_YACHT_AIRDEF_DIALOGUE - Skip broadcase as ALL_PLAYERS_IN_VEHICLE = 0 ")
		ENDIF
	ENDIF
ENDPROC



//╔═════════════════════════════════════════════════════════════════════════════╗
//║							private yacht delete vehicles														
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_DELETE_YACHT_VEHICLES_NOW
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iYacht
ENDSTRUCT

PROC BROADCAST_DELETE_YACHT_VEHICLES_NOW(INT iYachtID)
	SCRIPT_EVENT_DATA_DELETE_YACHT_VEHICLES_NOW Event
	Event.Details.Type = SCRIPT_EVENT_DELETE_YACHT_VEHICLES_NOW
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iYacht = iYachtID
	CPRINTLN(DEBUG_YACHT, " BROADCAST_DELETE_YACHT_VEHICLES_NOW - called by local player, iYachtID ", iYachtID)
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							disable recording sphere													
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_DISABLE_RECORDING_FOR_SPHERE
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vCoords
	FLOAT fRadius
	FLOAT fMaxDist
	INT iTimeMS
ENDSTRUCT

PROC BROADCAST_DISABLE_RECORDING_FOR_SPHERE(VECTOR vCoords, FLOAT fRadius, FLOAT fMaxDist, INT iTimeMS)
	SCRIPT_EVENT_DATA_DISABLE_RECORDING_FOR_SPHERE Event
	Event.Details.Type = SCRIPT_EVENT_DISABLE_RECORDING_FOR_SPHERE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vCoords = vCoords
	Event.fRadius = fRadius
	Event.fMaxDist = fMaxDist
	Event.iTimeMS = iTimeMS
	CPRINTLN(DEBUG_YACHT, " BROADCAST_DISABLE_RECORDING_FOR_SPHERE - called by local player, vCoords ", vCoords, " fRadius ", fRadius, " fMaxDist ", fMaxDist, " iTimeMS ", iTimeMS)
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║					delete abandoned vehicles on yacht														
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_DELETE_ABANDONED_VEHICLES_ON_YACHT_NOW
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iYacht
ENDSTRUCT

PROC BROADCAST_DELETE_ABANDONED_VEHICLES_ON_YACHT_NOW(INT iYachtID)
	SCRIPT_EVENT_DATA_DELETE_ABANDONED_VEHICLES_ON_YACHT_NOW Event
	Event.Details.Type = SCRIPT_EVENT_DELETE_ABANDONED_VEHICLES_ON_YACHT_NOW
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iYacht = iYachtID
	CPRINTLN(DEBUG_YACHT, " BROADCAST_DELETE_ABANDONED_VEHICLES_ON_YACHT_NOW - called by local player, iYachtID ", iYachtID)
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
ENDPROC



//╔═════════════════════════════════════════════════════════════════════════════╗
//║				set someones private vehicle as destroyed.														
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_SET_PERSONAL_VEHICLE_AS_DESTROYED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iHashOwner = -1
	INT iSlot = -1
	BOOL bPayInsurance
ENDSTRUCT

PROC BROADCAST_SET_PERSONAL_VEHICLE_AS_DESTROYED(VEHICLE_INDEX VehicleID, BOOL bShouldPayForInsurance=FALSE)
	
	IF DECOR_EXIST_ON(VehicleID,"Player_Vehicle")
	
		SCRIPT_EVENT_DATA_SET_PERSONAL_VEHICLE_AS_DESTROYED Event
		Event.Details.Type = SCRIPT_EVENT_SET_PERSONAL_VEHICLE_AS_DESTROYED
		Event.Details.FromPlayerIndex = PLAYER_ID()
		IF DECOR_EXIST_ON(VehicleID,"Player_Vehicle")
			Event.iHashOwner = DECOR_GET_INT(VehicleID, "Player_Vehicle")
		ENDIF
		IF DECOR_EXIST_ON(VehicleID,"PV_Slot")
			Event.iSlot = DECOR_GET_INT(VehicleID, "PV_Slot")
		ENDIF
		Event.bPayInsurance = bShouldPayForInsurance
			
		PRINTLN("[personal_vehicle] BROADCAST_SET_PERSONAL_VEHICLE_AS_DESTROYED - called by local player, iHashOwner ", Event.iHashOwner," iSlot ", Event.iSlot, " bPayInsurance", Event.bPayInsurance)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
		
	ELSE
		SCRIPT_ASSERT("[personal_vehicle] BROADCAST_SET_PERSONAL_VEHICLE_AS_DESTROYED - not a personal vehicle, use IS_VEHICLE_A_PERSONAL_VEHICLE to check")
	ENDIF
	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							PROPERTY MESS EVENT															
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_PROPERTY_MESS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iSmokes
	INT iDrinks
	INT iStrippers
	
	INT iPropertySlot
	
ENDSTRUCT

PROC BROADCAST_PROPERTY_MESS_EVENT(INT iPlayerFlags,INT iSmokes, INT iDrinks,INT iStrippers, INT iPropertySlot)//,INT iSmokesSecond, INT iDrinksSecond,INT iStrippersSecond,INT iSmokes3, INT iDrinks3,INT iStrippers3,INT iSmokes4, INT iDrinks4,INT iStrippers4)
	SCRIPT_EVENT_DATA_PROPERTY_MESS Event
	Event.Details.Type = SCRIPT_EVENT_PROPERTY_MESS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iSmokes =  iSmokes
	Event.iDrinks =  iDrinks
	Event.iStrippers =  iStrippers
	Event.iPropertySlot = iPropertySlot
	
	IF NOT (iPlayerFlags = 0)
		NET_PRINT("BROADCAST_PROPERTY_MESS_EVENT - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PROPERTY_MESS_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							PROPERTY NEARBY PLAYERS INVITE														
//╚═════════════════════════════════════════════════════════════════════════════╝

CONST_INT BS_SCRIPT_EVENT_PROPERTY_NEARBY_PLAYERS_INVITE_FROM_HELICOPTER 	0
CONST_INT BS_SCRIPT_EVENT_PROPERTY_NEARBY_PLAYERS_INVITE_FROM_FM_DELIVERY 	1

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_PROPERTY_NEARBY_PLAYERS_INVITE
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX ownerPlayerIndex
	INT iYacht = -1
	INT iVariation
	INT iProperty
	INT iEntrance
	BOOL bHeistForcedApt
	BOOL bHeistForcedGar
	INT iBS
ENDSTRUCT

PROC BROADCAST_PROPERTY_NEARBY_PLAYERS_INVITE_EVENT(INT iPlayerFlags,INT iProperty    ,INT iVariation = -1,INT iYacht = -1  ,BOOL bHeistForcedApt = FALSE,BOOL bHeistForcedGar = FALSE,INT iOverridePlayerID = -1, BOOL bSentFromHelicopter = FALSE, INT iEntrance = 0 #IF FEATURE_DLC_1_2022 , BOOL bSentFromFMDelivery = FALSE #ENDIF)
	SCRIPT_EVENT_DATA_PROPERTY_NEARBY_PLAYERS_INVITE Event
	Event.Details.Type = SCRIPT_EVENT_INVITE_NEARBY_PLAYERS_INTO_APARTMENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF iOverridePlayerID < 0
		Event.ownerPlayerIndex = PLAYER_ID()
	ELSE
		Event.ownerPlayerIndex = INT_TO_PLAYERINDEX(iOverridePlayerID)
	ENDIF
	Event.iProperty =  iProperty
	Event.bHeistForcedApt = bHeistForcedApt
	Event.bHeistForcedGar = bHeistForcedGar
	Event.iYacht = iYacht
	Event.iVariation = iVariation
	Event.iEntrance = iEntrance
	IF bSentFromHelicopter
		SET_BIT(Event.iBS, BS_SCRIPT_EVENT_PROPERTY_NEARBY_PLAYERS_INVITE_FROM_HELICOPTER)
	ENDIF
	#IF FEATURE_DLC_1_2022
	IF bSentFromFMDelivery
		PRINTLN("BROADCAST_PROPERTY_NEARBY_PLAYERS_INVITE_EVENT - Tigger entry from FM delivery")
		SET_BIT(Event.iBS, BS_SCRIPT_EVENT_PROPERTY_NEARBY_PLAYERS_INVITE_FROM_FM_DELIVERY)
	ENDIF
	#ENDIF
	
	IF NOT (iPlayerFlags = 0)
		NET_PRINT("BROADCAST_PROPERTY_NEARBY_PLAYERS_INVITE_EVENT - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PROPERTY_NEARBY_PLAYERS_INVITE_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				 		OFFICE LANDING/WARPING/TAKEOFF EVENTS													
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
ENUM QUICK_TRAVEL_DESINATION_TYPE
	DESTINATION_OFFICE,
	DESTINATION_WAREHOUSE
ENDENUM

STRUCT SCRIPT_EVENT_DATA_WARP_TO_QUICK_TRAVEL_DESTINATION
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerOwner
	QUICK_TRAVEL_DESINATION_TYPE eDestinationType
	INT iDestinationID
	INT iInvolvedPlayersFlags
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_GANG_LEAVE_OFFICE_IN_HELI
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerDriver
	PLAYER_INDEX playerOwner
	INT iInvolvedPlayers
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_LAND_ON_OFFICE_ROOFTOP
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerOwner
	INT iInvolvedPlayers
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_TAKEOFF_WARP_DONE
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerOwner
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_HELI_DOCK_DRIVER_CHANGE
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerOwner
ENDSTRUCT

PROC BROADCAST_WARP_TO_QUICK_TRAVEL_DESINATION(INT iPlayerFlags, PLAYER_INDEX playerOwner, QUICK_TRAVEL_DESINATION_TYPE eDestinationType, INT iDestinationID)
	SCRIPT_EVENT_DATA_WARP_TO_QUICK_TRAVEL_DESTINATION Event
	Event.Details.Type = SCRIPT_EVENT_WARP_TO_QUICK_TRAVEL_DESTINATION
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.playerOwner = playerOwner
	Event.iDestinationID = iDestinationID
	Event.iInvolvedPlayersFlags = iPlayerFlags
	Event.eDestinationType = eDestinationType
	
	#IF IS_DEBUG_BUILD
	PRINTLN("BROADCAST_WARP_TO_QUICK_TRAVEL_DESINATION: playerOwner = ", NATIVE_TO_INT(playerOwner))
	SWITCH eDestinationType
		CASE DESTINATION_OFFICE
			PRINTLN("BROADCAST_WARP_TO_QUICK_TRAVEL_DESINATION: Destination is DESTINATION_OFFICE")
		BREAK
		CASE DESTINATION_WAREHOUSE
			PRINTLN("BROADCAST_WARP_TO_QUICK_TRAVEL_DESINATION: Destination is DESTINATION_WAREHOUSE")
		BREAK
	ENDSWITCH
	PRINTLN("BROADCAST_WARP_TO_QUICK_TRAVEL_DESINATION: iDestinationID = ", iDestinationID)
	PRINTLN("BROADCAST_WARP_TO_QUICK_TRAVEL_DESINATION: iInvolvedPlayersFlags = ", iPlayerFlags)
	#ENDIF
	
	IF NOT (iPlayerFlags = 0)
		NET_PRINT("BROADCAST_WARP_TO_QUICK_TRAVEL_DESINATION - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_WARP_TO_QUICK_TRAVEL_DESINATION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_GANG_LEAVE_OFFICE_IN_HELI(INT iPlayersFlag, PLAYER_INDEX playerOwner, PLAYER_INDEX playerDriver)
	SCRIPT_EVENT_DATA_GANG_LEAVE_OFFICE_IN_HELI Event
	Event.Details.Type = SCRIPT_EVENT_GANG_LEAVE_OFFICE_IN_HELI
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	#IF IS_DEBUG_BUILD
		CDEBUG1LN(DEBUG_SPAWN_ACTIVITIES, "[HELI_DOCK_TAKEOFF] BROADCAST_GANG_LEAVE_OFFICE_IN_HELI - doing this to players ", iPlayersFlag)
	#ENDIF

	Event.playerDriver = playerDriver
	CDEBUG1LN(DEBUG_SPAWN_ACTIVITIES, "BROADCAST_GANG_LEAVE_OFFICE_IN_HELI: playerDriver = ", NATIVE_TO_INT(playerDriver))
	Event.playerOwner = playerOwner
	CDEBUG1LN(DEBUG_SPAWN_ACTIVITIES, "BROADCAST_GANG_LEAVE_OFFICE_IN_HELI: playerOwner = ", NATIVE_TO_INT(playerOwner))
	Event.iInvolvedPlayers = iPlayersFlag
	CDEBUG1LN(DEBUG_SPAWN_ACTIVITIES, "BROADCAST_GANG_LEAVE_OFFICE_IN_HELI: iInvolvedPlayers = ", iPlayersFlag)
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_GANG_LEAVE_OFFICE_IN_HELI - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_GANG_LEAVE_OFFICE_IN_HELI - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_LAND_ON_OFFICE_ROOFTOP(INT iPlayersFlag, PLAYER_INDEX playerOwner)
	
	SCRIPT_EVENT_DATA_LAND_ON_OFFICE_ROOFTOP Event
	Event.Details.Type = SCRIPT_EVENT_LAND_ON_OFFICE_ROOFTOP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	#IF IS_DEBUG_BUILD
		CDEBUG1LN(DEBUG_SPAWN_ACTIVITIES, "[HELI_DOCK_TAKEOFF] BROADCAST_LAND_ON_OFFICE_ROOFTOP - doing this to players ", iPlayersFlag)
	#ENDIF
	
	Event.playerOwner = playerOwner
	PRINTLN("BROADCAST_LAND_ON_OFFICE_ROOFTOP: playerOwner = ", NATIVE_TO_INT(playerOwner))
	Event.iInvolvedPlayers = iPlayersFlag
	PRINTLN("BROADCAST_LAND_ON_OFFICE_ROOFTOP: iInvolvedPlayers = ", iPlayersFlag)
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_LAND_ON_OFFICE_ROOFTOP - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_LAND_ON_OFFICE_ROOFTOP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

PROC BROADCAST_TAKEOFF_WARP_DONE(INT iPlayersFlag, PLAYER_INDEX playerOwner)
	SCRIPT_EVENT_DATA_TAKEOFF_WARP_DONE Event
	Event.Details.Type = SCRIPT_EVENT_TAKEOFF_WARP_DONE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	#IF IS_DEBUG_BUILD
		CDEBUG1LN(DEBUG_SPAWN_ACTIVITIES, "[HELI_DOCK_TAKEOFF] BROADCAST_TAKEOFF_WARP_DONE - doing this to players ", iPlayersFlag)
	#ENDIF
	
	Event.playerOwner = playerOwner
	PRINTLN("BROADCAST_TAKEOFF_WARP_DONE: playerOwner = ", GET_PLAYER_NAME(playerOwner))
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_TAKEOFF_WARP_DONE - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_TAKEOFF_WARP_DONE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				 			  SIMPLE INTERIOR EVENTS													
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════

STRUCT SCRIPT_EVENT_DATA_TRIGGER_EXIT_ALL_FROM_SIMPLE_INTERIOR
	STRUCT_EVENT_COMMON_DETAILS Details
	SIMPLE_INTERIORS eSimpleInteriorID
	INT iInstance
	INT iExitUsed
	BOOL bExitForOwnershipChange 		= FALSE	//Set to true when triggering an exit because the owner has traded in a property
	BOOL bUsedAllExitToDifferentFloor 	= FALSE	//Set to true when triggering an exit to a different floor in the same property e.g. Apartment to Garage
	INT iForceEntranceID 				= -1	//Set to ensure which entry point a local player uses when transitioning with bUsedAllExitToDifferentFloor
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_REQUEST_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerOwner
	SIMPLE_INTERIORS eSimpleInteriorID
	INT iPlayersToJoinBS
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_CONFIRM_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE_USED
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerConfirming
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FREE_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerFreeing
ENDSTRUCT

//STRUCT SCRIPT_EVENT_DATA_AUTOWARP_TO_SIMPLE_INTERIOR
//	STRUCT_EVENT_COMMON_DETAILS Details
//	SIMPLE_INTERIORS eSimpleInteriorID
//	BOOL bOverrideSpawnCoords
//	VECTOR vSpawnPoint
//	FLOAT fSpawnHeading
//ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_ASYNC_GRID_WARP_REQUEST
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerRequesting
	ASYNC_GRID_SPAWN_LOCATIONS location
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_ASYNC_GRID_WARP_REQUEST_CONFIRM
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX pRequesting
	ASYNC_GRID_SPAWN_LOCATIONS location
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_ASYNC_GRID_WARP_FINISH
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerFinishing
	ASYNC_GRID_SPAWN_LOCATIONS location
	INT iPointUsed
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_ASYNC_GRID_WARP_FINISH_CONFIRM
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX pFinishing
	ASYNC_GRID_SPAWN_LOCATIONS location
ENDSTRUCT

//STRUCT SCRIPT_EVENT_DATA_DO_ASYNC_GRID_WARP
//	STRUCT_EVENT_COMMON_DETAILS Details
//	ASYNC_GRID_SPAWN_LOCATIONS location
//ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR
	STRUCT_EVENT_COMMON_DETAILS Details
	SIMPLE_INTERIORS eSimpleInteriorID
	PLAYER_INDEX pOwner
	BOOL bInviteOnlyGangMembers
	BOOL bAllowInteriorInstanceOverride = TRUE
	VECTOR vOverrideEntryCoord
	BOOL bMovingFromBunkerToTruck = FALSE
	INT iInteriorInstance
	INT iEntranceUsed
	INT iOverrideDistance
	BOOL bEnteringFromCutscene = FALSE
	INT iFloorIndexOverride = NO_FLOOR_INDEX_OVERRIDE
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_OWNER_WARPING_FROM_HUB_TO_TRUCK
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_OK_TO_CLEANUP_GUNRUN_ENTITY
	STRUCT_EVENT_COMMON_DETAILS Details
	FREEMODE_DELIVERABLE_ID eDeliverable
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FM_DELIVERABLE_DELIVERY
	STRUCT_EVENT_COMMON_DETAILS Details
	FREEMODE_DELIVERABLE_ID eDeliverable
	FREEMODE_DELIVERY_DROPOFFS eDropoffDeliverdTo
	FREEMODE_DELIVERABLE_TYPE eType
	FM_DELIVERY_EVENT_POST_EVENT_ACTION ePostEventAct
	INT iQuantityRemaining
	
	BOOL bStolen = FALSE
	INT iRivalVariation = -1
	INT iRivalFMMCType = -1
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FM_MUTLTIPLE_DELIVERABLE_DELIVERY
	STRUCT_EVENT_COMMON_DETAILS Details
	FREEMODE_DELIVERABLE_ID eDeliverable[FREEMODE_DELIVERY_MAX_HELD_DELIVERABLES]
	FREEMODE_DELIVERY_DROPOFFS eDropoffDeliverdTo
	FM_DELIVERY_EVENT_POST_EVENT_ACTION ePostEventAct
	FREEMODE_DELIVERABLE_TYPE eType[FREEMODE_DELIVERY_MAX_HELD_DELIVERABLES]
	INT iQuantityRemaining[FREEMODE_DELIVERY_MAX_HELD_DELIVERABLES]
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_OK_TO_CLEANUP_SMUGGLER_ENTITY
	STRUCT_EVENT_COMMON_DETAILS Details
	FREEMODE_DELIVERABLE_ID eDeliverable
ENDSTRUCT

CONST_INT SI_EVENT_INVITE_NORMAL	0
CONST_INT SI_EVENT_INVITE_PRIVATE	1

STRUCT SCRIPT_EVENT_DATA_INVITE_TO_SIMPLE_INTERIOR
	STRUCT_EVENT_COMMON_DETAILS Details
	SIMPLE_INTERIORS eSimpleInteriorID
	PLAYER_INDEX pInvitee
	INT iExtraInt = SI_EVENT_INVITE_NORMAL
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_NPC_INVITE_TO_SIMPLE_INTERIOR
	STRUCT_EVENT_COMMON_DETAILS Details
	enumCharacterList eFromCharacter
	SIMPLE_INTERIORS eSimpleInteriorID
	PLAYER_INDEX pInvitee
	INT iExtraInt = SI_EVENT_INVITE_NORMAL
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_INVITE_TO_HEIST_ISLAND_BEACH_PARTY
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX pInvitee
	BOOL bIsInvite
	BOOL bIsTagAlong
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_HEIST_ISLAND_WARP_TRANSITION
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX pInvitee
	BOOL bIsTagAlong
	INT iTransitionType
	BOOL bIsIslandJoin
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_ISLAND_BACKUP_HELI_LAUNCH
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iScriptInstance = -1
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_BASIC_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_TRIGGER_CASINO_ROOF_CELEB_MOCAP(INT iPlayers)
	SCRIPT_EVENT_DATA_BASIC_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_TRIGGER_CASINO_ROOF_CELEB_MOCAP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	PRINTLN("BROADCAST_TRIGGER_CASINO_ROOF_CELEB_MOCAP: Sending to players = ", iPlayers)
	
	IF NOT (iPlayers = 0)
		PRINTLN("BROADCAST_TRIGGER_CASINO_ROOF_CELEB_MOCAP - called by local player")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayers)	
	ELSE
		NET_PRINT("BROADCAST_TRIGGER_CASINO_ROOF_CELEB_MOCAP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_TRIGGER_EXIT_ALL_FROM_SIMPLE_INTERIOR(INT iPlayersFlag, SIMPLE_INTERIORS eSimpleInteriorID, INT iInstance, INT iExitUsed  , BOOL bExitForOwnershipChange = FALSE, BOOL bUsedAllExitToDifferentFloor = FALSE, INT iForceEntranceID = -1)
	SCRIPT_EVENT_DATA_TRIGGER_EXIT_ALL_FROM_SIMPLE_INTERIOR Event
	Event.Details.Type = SCRIPT_EVENT_TRIGGER_EXIT_ALL_FROM_SIMPLE_INTERIOR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.eSimpleInteriorID = eSimpleInteriorID
	PRINTLN("BROADCAST_TRIGGER_EXIT_ALL_FROM_SIMPLE_INTERIOR: eSimpleInteriorID = ", eSimpleInteriorID)
	Event.iInstance = iInstance
	PRINTLN("BROADCAST_TRIGGER_EXIT_ALL_FROM_SIMPLE_INTERIOR: iInstance = ", iInstance)
	Event.iExitUsed = iExitUsed
	PRINTLN("BROADCAST_TRIGGER_EXIT_ALL_FROM_SIMPLE_INTERIOR: iExitUsed = ", iExitUsed)
	Event.bUsedAllExitToDifferentFloor = bUsedAllExitToDifferentFloor
	PRINTLN("BROADCAST_TRIGGER_EXIT_ALL_FROM_SIMPLE_INTERIOR: bUsedAllExitToDifferentFloor = ", bUsedAllExitToDifferentFloor)
	Event.bExitForOwnershipChange = bExitForOwnershipChange
	PRINTLN("BROADCAST_TRIGGER_EXIT_ALL_FROM_SIMPLE_INTERIOR: bExitForOwnershipChange = ", bExitForOwnershipChange)
	Event.iForceEntranceID = iForceEntranceID
	PRINTLN("BROADCAST_TRIGGER_EXIT_ALL_FROM_SIMPLE_INTERIOR: iForceEntranceID = ", iForceEntranceID)
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_TRIGGER_EXIT_ALL_FROM_SIMPLE_INTERIOR - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_TRIGGER_EXIT_ALL_FROM_SIMPLE_INTERIOR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_REQUEST_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE(SIMPLE_INTERIORS eSimpleInteriorID, INT iPlayersToJoinBS, PLAYER_INDEX propertyOwner)
	SCRIPT_EVENT_DATA_REQUEST_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE Event
	Event.Details.Type = SCRIPT_EVENT_REQUEST_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.eSimpleInteriorID = eSimpleInteriorID
	PRINTLN("BROADCAST_REQUEST_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE: eSimpleInteriorID = ", eSimpleInteriorID)
	Event.iPlayersToJoinBS = iPlayersToJoinBS
	PRINTLN("BROADCAST_REQUEST_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE: iPlayersToJoinBS = ", iPlayersToJoinBS)
	IF propertyOwner != INVALID_PLAYER_INDEX()
		Event.playerOwner = propertyOwner
		PRINTLN("BROADCAST_REQUEST_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE: owner = ", GET_PLAYER_NAME(propertyOwner))
	ELSE
		Event.playerOwner = INVALID_PLAYER_INDEX()
		PRINTLN("BROADCAST_REQUEST_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE: No owner set so server will rely on iPlayersToJoinBS")
	ENDIF
	
	PLAYER_INDEX playerServer = NETWORK_GET_HOST_OF_SCRIPT(FREEMODE_SCRIPT())
	
	INT iPlayersFlag
	
	IF playerServer != INVALID_PLAYER_INDEX()
		SET_BIT(iPlayersFlag, NATIVE_TO_INT(playerServer))
	ELSE
		NET_PRINT("BROADCAST_REQUEST_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE - unable to find valid freemode host" ) NET_NL()	
	ENDIF
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_REQUEST_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_REQUEST_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_CONFIRM_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE_USED()
	SCRIPT_EVENT_DATA_CONFIRM_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE_USED Event
	Event.Details.Type = SCRIPT_EVENT_CONFIRM_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE_USED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.playerConfirming = PLAYER_ID()
	
	PLAYER_INDEX playerServer = NETWORK_GET_HOST_OF_SCRIPT(FREEMODE_SCRIPT())
	
	INT iPlayersFlag
	SET_BIT(iPlayersFlag, NATIVE_TO_INT(playerServer))
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_CONFIRM_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE_USED - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_CONFIRM_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE_USED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_FREE_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE()
	SCRIPT_EVENT_DATA_CONFIRM_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE_USED Event
	Event.Details.Type = SCRIPT_EVENT_FREE_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.playerConfirming = PLAYER_ID()
	
	//PLAYER_INDEX playerServer = NETWORK_GET_HOST_OF_SCRIPT(FREEMODE_SCRIPT())
	
	INT iPlayersFlag = ALL_PLAYERS() // send to all, it happened that freemode died before this event and server would be invalid
	//SET_BIT(iPlayersFlag, NATIVE_TO_INT(playerServer))
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_FREE_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_FREE_SIMPLE_INTERIOR_INT_SCRIPT_INSTANCE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//PROC BROADCAST_AUTOWARP_TO_SIMPLE_INTERIOR(PLAYER_INDEX playerToWarp, SIMPLE_INTERIORS eSimpleInteriorID, BOOL bOverrideSpawnPoint, FLOAT fSpawnPointX = 0.0, FLOAT fSpawnPointY = 0.0, FLOAT fSpawnPointZ = 0.0, FLOAT fSpawnHeading = 0.0)
//	SCRIPT_EVENT_DATA_AUTOWARP_TO_SIMPLE_INTERIOR Event
//	Event.Details.Type = SCRIPT_EVENT_AUTOWARP_TO_SIMPLE_INTERIOR
//	
//	Event.eSimpleInteriorID = eSimpleInteriorID
//	PRINTLN("BROADCAST_AUTOWARP_TO_SIMPLE_INTERIOR: eSimpleInteriorID = ", eSimpleInteriorID)
//	Event.bOverrideSpawnCoords = bOverrideSpawnPoint
//	PRINTLN("BROADCAST_AUTOWARP_TO_SIMPLE_INTERIOR: bOverrideSpawnPoint = ", bOverrideSpawnPoint)
//	
//	IF bOverrideSpawnPoint
//		Event.vSpawnPoint = <<fSpawnPointX, fSpawnPointY, fSpawnPointZ>>
//		PRINTLN("BROADCAST_AUTOWARP_TO_SIMPLE_INTERIOR: vSpawnPoint = ", Event.vSpawnPoint)
//		Event.fSpawnHeading = fSpawnHeading
//		PRINTLN("BROADCAST_AUTOWARP_TO_SIMPLE_INTERIOR: fSpawnHeading = ", Event.fSpawnHeading)
//	ENDIF
//	
//	INT iPlayersFlag
//	SET_BIT(iPlayersFlag, NATIVE_TO_INT(playerToWarp))
//	
//	IF NOT (iPlayersFlag = 0)
//		PRINTLN("BROADCAST_AUTOWARP_TO_SIMPLE_INTERIOR - called by local player, sending to ", GET_PLAYER_NAME(playerToWarp))
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
//	ELSE
//		PRINTLN("BROADCAST_AUTOWARP_TO_SIMPLE_INTERIOR - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF
//ENDPROC

PROC BROADCAST_ASYNC_GRID_WARP_REQUEST(PLAYER_INDEX playerRequesting, ASYNC_GRID_SPAWN_LOCATIONS location)
	SCRIPT_EVENT_DATA_ASYNC_GRID_WARP_REQUEST Event
	Event.Details.Type = SCRIPT_EVENT_ASYNC_GRID_WARP_REQUEST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.playerRequesting = playerRequesting
	PRINTLN("BROADCAST_ASYNC_GRID_WARP_REQUEST: playerRequesting = ", GET_PLAYER_NAME(playerRequesting))
	Event.location = location
	PRINTLN("BROADCAST_ASYNC_GRID_WARP_REQUEST: location = ", GET_ASYNC_GRID_SPAWN_LOCATION_NAME(location))
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("BROADCAST_ASYNC_GRID_WARP_REQUEST - called by local player, sending to everyone")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		PRINTLN("BROADCAST_ASYNC_GRID_WARP_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_ASYNC_GRID_WARP_REQUEST_CONFIRM(PLAYER_INDEX pRequesting, ASYNC_GRID_SPAWN_LOCATIONS location)
	SCRIPT_EVENT_DATA_ASYNC_GRID_WARP_REQUEST_CONFIRM Event
	Event.Details.Type = SCRIPT_EVENT_ASYNC_GRID_WARP_REQUEST_CONFIRM
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.pRequesting = pRequesting
	PRINTLN("BROADCAST_ASYNC_GRID_WARP_REQUEST_CONFIRM: pRequesting = ", GET_PLAYER_NAME(pRequesting))
	Event.location = location
	PRINTLN("BROADCAST_ASYNC_GRID_WARP_REQUEST_CONFIRM: location = ", GET_ASYNC_GRID_SPAWN_LOCATION_NAME(location))
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("BROADCAST_ASYNC_GRID_WARP_REQUEST_CONFIRM - called by local player, sending to everyone")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		PRINTLN("BROADCAST_ASYNC_GRID_WARP_REQUEST_CONFIRM - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_ASYNC_GRID_WARP_FINISH(PLAYER_INDEX playerFinishing, ASYNC_GRID_SPAWN_LOCATIONS location, INT iPointUsed)
	SCRIPT_EVENT_DATA_ASYNC_GRID_WARP_FINISH Event
	Event.Details.Type = SCRIPT_EVENT_ASYNC_GRID_WARP_FINISH
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.playerFinishing = playerFinishing
	PRINTLN("BROADCAST_ASYNC_GRID_WARP_FINISH: playerFinishing = ", GET_PLAYER_NAME(playerFinishing))
	Event.location = location
	PRINTLN("BROADCAST_ASYNC_GRID_WARP_FINISH: location = ", GET_ASYNC_GRID_SPAWN_LOCATION_NAME(location))
	Event.iPointUsed = iPointUsed
	PRINTLN("BROADCAST_ASYNC_GRID_WARP_FINISH: iPointUsed = ", iPointUsed)
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("BROADCAST_ASYNC_GRID_WARP_FINISH - called by local player, sending to everyone")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		PRINTLN("BROADCAST_ASYNC_GRID_WARP_FINISH - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_ASYNC_GRID_WARP_FINISH_CONFIRM(PLAYER_INDEX pFinishing, ASYNC_GRID_SPAWN_LOCATIONS location)
	SCRIPT_EVENT_DATA_ASYNC_GRID_WARP_FINISH_CONFIRM Event
	Event.Details.Type = SCRIPT_EVENT_ASYNC_GRID_WARP_FINISH_CONFIRM
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.pFinishing = pFinishing
	PRINTLN("BROADCAST_ASYNC_GRID_WARP_FINISH_CONFIRM: pFinishing = ", GET_PLAYER_NAME(pFinishing))
	Event.location = location
	PRINTLN("BROADCAST_ASYNC_GRID_WARP_FINISH_CONFIRM: location = ", GET_ASYNC_GRID_SPAWN_LOCATION_NAME(location))
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("BROADCAST_ASYNC_GRID_WARP_FINISH_CONFIRM - called by local player, sending to everyone")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		PRINTLN("BROADCAST_ASYNC_GRID_WARP_FINISH_CONFIRM - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_OWNER_WARPING_FROM_HUB_TO_TRUCK()
	SCRIPT_EVENT_DATA_OWNER_WARPING_FROM_HUB_TO_TRUCK Event
	Event.Details.Type = SCRIPT_EVENT_OWNER_WARPING_FROM_HUB_TO_TRUCK
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("BROADCAST_OWNER_WARPING_FROM_HUB_TO_TRUCK - called by local player, sending to everyone")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		PRINTLN("BROADCAST_OWNER_WARPING_FROM_HUB_TO_TRUCK - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//PROC BROADCAST_DO_ASYNC_GRID_WARP(PLAYER_INDEX pWarper, ASYNC_GRID_SPAWN_LOCATIONS location)
//	SCRIPT_EVENT_DATA_DO_ASYNC_GRID_WARP Event
//	Event.Details.Type = SCRIPT_EVENT_DO_ASYNC_GRID_WARP
//	
//	Event.location = location
//	PRINTLN("BROADCAST_DO_ASYNC_GRID_WARP: location = ", GET_ASYNC_GRID_SPAWN_LOCATION_NAME(location))
//	
//	INT iPlayersFlag = SPECIFIC_PLAYER(pWarper)
//	
//	IF NOT (iPlayersFlag = 0)
//		PRINTLN("BROADCAST_DO_ASYNC_GRID_WARP - called by local player, sending to ", GET_PLAYER_NAME(pWarper))
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
//	ELSE
//		PRINTLN("BROADCAST_DO_ASYNC_GRID_WARP - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF
//ENDPROC

FUNC BOOL IS_SIMPLE_INTERIOR_EXTERIOR_LOCATION_MOBILE(SIMPLE_INTERIORS eInterior, BOOL bIncludeActivitySessionInts = TRUE)
	SIMPLE_INTERIOR_TYPE eType = GET_SIMPLE_INTERIOR_TYPE(eInterior)
	
	IF eType = SIMPLE_INTERIOR_TYPE_ARMORY_TRUCK
	OR eType = SIMPLE_INTERIOR_TYPE_ARMORY_AIRCRAFT
	OR eType = SIMPLE_INTERIOR_TYPE_HACKER_TRUCK
	#IF FEATURE_HEIST_ISLAND
	OR eType = SIMPLE_INTERIOR_TYPE_SUBMARINE
	#ENDIF
		RETURN TRUE
	ELIF eType = SIMPLE_INTERIOR_TYPE_CREATOR_TRAILER
	OR eType = SIMPLE_INTERIOR_TYPE_CREATOR_AIRCRAFT
		RETURN bIncludeActivitySessionInts
	ENDIF
	
	RETURN FALSE
ENDFUNC

/// PURPOSE:
///    Sends an event for nearby players to warp into a simple interior with the owner
/// PARAMS:
///    pOwner - owners player ID
///    eSimpleInteriorID - The simple interior to warp to
///    bOnlyInviteGangMembers - Is this an interior that only allows gang members?
///    bInvitePlayersInVeh - Invite players in the same vehicle as the local player
PROC BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR(PLAYER_INDEX pOwner, SIMPLE_INTERIORS eSimpleInteriorID, VECTOR vOverrideEntryCoord,  BOOL bOnlyInviteGangMembers = TRUE, BOOL bInvitePlayersInVeh = FALSE, BOOL bFriendsAndCrew = FALSE , BOOL bFromBunkerToTruck = FALSE, INT iInteriorInstance = NO_INSTANCE_OVERRIDE, INT iOverrideDistance = -1, INT iFloor = NO_FLOOR_INDEX_OVERRIDE)
	SCRIPT_EVENT_DATA_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR Event
	
	Event.Details.Type 				= SCRIPT_EVENT_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR	
	Event.Details.FromPlayerIndex 	= PLAYER_ID()	
	Event.pOwner 					= pOwner
	Event.eSimpleInteriorID 		= eSimpleInteriorID
	Event.vOverrideEntryCoord 		= vOverrideEntryCoord
	Event.bMovingFromBunkerToTruck 	= bFromBunkerToTruck		// also using this for base to aircraft
	Event.iEntranceUsed 			= GET_SIMPLE_INTERIOR_ENTRY_POINT_LOCAL_PLAYER_USED()
	Event.iOverrideDistance 		= iOverrideDistance
	Event.bInviteOnlyGangMembers 	= bOnlyInviteGangMembers
	Event.iFloorIndexOverride		= iFloor
	
	IF iInteriorInstance = BLOCK_INSTANCE_OVERRIDE
		Event.bAllowInteriorInstanceOverride = FALSE
		Event.iInteriorInstance	= NO_INSTANCE_OVERRIDE
	ELSE
		Event.bAllowInteriorInstanceOverride = TRUE
		Event.iInteriorInstance = iInteriorInstance
	ENDIF
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR: pOwner = ", GET_PLAYER_NAME(pOwner))
	PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR: eSimpleInteirorID = ", ENUM_TO_INT(eSimpleInteriorID))
	PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR: bOnlyInviteGangMembers = ", bOnlyInviteGangMembers)
	PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR: bInvitePlayersInVeh = ", bInvitePlayersInVeh)
	PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR: bFriendsAndCrew = ", bFriendsAndCrew)
	PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR: bFromBunkerToTruck = ", bFromBunkerToTruck)
	PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR: iInteriorInstance = ", iInteriorInstance)
	PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR: iEntranceUsed = ", GET_SIMPLE_INTERIOR_ENTRY_POINT_LOCAL_PLAYER_USED())
	PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR: vOverrideEntryCoord = ", vOverrideEntryCoord)
	PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR: iPlayersFlag after calling ALL_PLAYERS = ", iPlayersFlag)
	
	IF bInvitePlayersInVeh
		IF NOT IS_ENTITY_DEAD(PLAYER_PED_ID())
			IF IS_PED_IN_ANY_VEHICLE(PLAYER_PED_ID())
				iPlayersFlag = ALL_PLAYERS_IN_VEHICLE(GET_VEHICLE_PED_IS_IN(PLAYER_PED_ID()))
				PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR: iPlayersFlag = ALL_PLAYERS_IN_VEHICLE")
			ELSE
				ASSERTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR bInvitePlayersInVeh is true but player is not in any vehicle")
			ENDIF
		ENDIF
	ELIF bFriendsAndCrew
		IF IS_SIMPLE_INTERIOR_EXTERIOR_LOCATION_MOBILE(Event.eSimpleInteriorID, FALSE)
			iPlayersFlag = ALL_FREINDS_OR_CREW_MEMBERS(TRUE, TRUE)
			PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR: iPlayersFlag = skip part check")
		ELSE
			iPlayersFlag = ALL_FREINDS_OR_CREW_MEMBERS()
			PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR: Call ALL_FREINDS_OR_CREW_MEMBERS")
		ENDIF
	ENDIF
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR - called by local player. Bitset = ", iPlayersFlag)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		PRINTLN("BROADCAST_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

/// PURPOSE:
///    Sends an event for the specified players to warp into a simple interior
/// PARAMS:
///    pOwner - owners player ID
///    eSimpleInteriorID - The simple interior to warp to
///    iPlayers - The bitset INT for the players we want to invite
PROC BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR(PLAYER_INDEX pOwner, SIMPLE_INTERIORS eSimpleInteriorID, INT iPlayersBS, BOOL bOverrideInteriorInstance, VECTOR vOverrideEntryCoord, BOOL bEnteringFromCutscene = FALSE)
	SCRIPT_EVENT_DATA_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR Event
	Event.Details.Type = SCRIPT_EVENT_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.pOwner = pOwner
	PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR: pOwner = ", GET_PLAYER_NAME(pOwner))
	Event.eSimpleInteriorID = eSimpleInteriorID
	PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR: eSimpleInteirorID = ", ENUM_TO_INT(eSimpleInteriorID))	
	Event.bInviteOnlyGangMembers = FALSE
	PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR: bAllowInteriorInstanceOverride = ", bOverrideInteriorInstance)
	Event.bAllowInteriorInstanceOverride = bOverrideInteriorInstance
	PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR: iEntranceUsed = ", GET_SIMPLE_INTERIOR_ENTRY_POINT_LOCAL_PLAYER_USED())
	Event.iEntranceUsed = GET_SIMPLE_INTERIOR_ENTRY_POINT_LOCAL_PLAYER_USED()
	PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR: vOverrideEntryCoord = ", vOverrideEntryCoord)
	Event.vOverrideEntryCoord = vOverrideEntryCoord
	PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR: bEnteringFromCutscene = ", bEnteringFromCutscene)
	Event.bEnteringFromCutscene = bEnteringFromCutscene
	
	IF NOT (iPlayersBS = 0)
		PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR - called by local player, sending to everyone")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersBS)	
	ELSE
		PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

#IF FEATURE_DLC_1_2022
/// PURPOSE:
///    Sends an event for the specified players to warp into a simple interior upon delivery of mission goods
/// PARAMS:
///    pOwner - owners player ID
///    eSimpleInteriorID - The simple interior to warp to
///    iPlayers - The bitset INT for the players we want to invite
PROC BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR_ON_DELIVERY(PLAYER_INDEX pOwner, SIMPLE_INTERIORS eSimpleInteriorID, INT iPlayersBS)
	SCRIPT_EVENT_DATA_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR Event
	Event.Details.Type = SCRIPT_EVENT_PLAYERS_WARP_INSIDE_SIMPLE_INTERIOR_ON_DELIVERY	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.pOwner = pOwner
	PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR_ON_DELIVERY: pOwner = ", GET_PLAYER_NAME(pOwner))
	Event.eSimpleInteriorID = eSimpleInteriorID
	PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR_ON_DELIVERY: eSimpleInteirorID = ", ENUM_TO_INT(eSimpleInteriorID))	
	Event.bAllowInteriorInstanceOverride = FALSE
	PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR_ON_DELIVERY: bAllowInteriorInstanceOverride = FALSE")
	Event.bEnteringFromCutscene = FALSE
	PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR_ON_DELIVERY: bEnteringFromCutscene = FALSE")
	
	IF NOT (iPlayersBS = 0)
		PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR - called by local player, sending to everyone")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersBS)	
	ELSE
		PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_SIMPLE_INTERIOR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_SKYDIVING_JUMP
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iDayOrderJump
	INT iSubvariation
	BOOL bAllCheckpoints
	BOOL bParTime
	BOOL bAccurateLanding
ENDSTRUCT

PROC BROADCAST_SKYDIVING_JUMP_COMPLETED(INT iDayOrderJump, INT iSubvariation , BOOL bAllCheckpoints, BOOL bParTime, BOOL bAccurateLanding)

	SCRIPT_EVENT_DATA_SKYDIVING_JUMP Event
	Event.Details.Type = SCRIPT_EVENT_SKYDIVING_JUMP_COMPLETED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iDayOrderJump = iDayOrderJump
	PRINTLN("BROADCAST_SKYDIVING_JUMP_COMPLETED: iDayOrderJump = ", iDayOrderJump)
	Event.iSubvariation = iSubvariation
	PRINTLN("BROADCAST_SKYDIVING_JUMP_COMPLETED: iSubvariation = ", iSubvariation)
	Event.bAllCheckpoints = bAllCheckpoints
	PRINTLN("BROADCAST_SKYDIVING_JUMP_COMPLETED: bAllCheckpoints = ", bAllCheckpoints)
	Event.bParTime = bParTime
	PRINTLN("BROADCAST_SKYDIVING_JUMP_COMPLETED: bParTime = ", bParTime)
	Event.bAccurateLanding = bAccurateLanding
	PRINTLN("BROADCAST_SKYDIVING_JUMP_COMPLETED: bAccurateLanding = ", bAccurateLanding)

	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS_ON_SCRIPT())	
ENDPROC

PROC BROADCAST_SKYDIVING_ALL_JUMPS_COMPLETED()
	SCRIPT_EVENT_DATA_SKYDIVING_JUMP Event
	Event.Details.Type = SCRIPT_EVENT_SKYDIVING_ALL_JUMPS_COMPLETED
	Event.Details.FromPlayerIndex = PLAYER_ID()

	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS_ON_SCRIPT())	
ENDPROC

PROC BROADCAST_SKYDIVING_ALL_JUMPS_GOLD()
	SCRIPT_EVENT_DATA_SKYDIVING_JUMP Event
	Event.Details.Type = SCRIPT_EVENT_SKYDIVING_ALL_JUMPS_GOLD
	Event.Details.FromPlayerIndex = PLAYER_ID()

	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS_ON_SCRIPT())	
ENDPROC
#ENDIF

/// PURPOSE:
///    Sends an event for the specified players to warp into the music studio smoking room
/// PARAMS:
///    pOwner - owners player ID
///    eSimpleInteriorID - The simple interior to warp to
///    iPlayers - The bitset INT for the players we want to invite
PROC BROADCAST_WARP_THESE_PLAYERS_TO_MUSIC_STUDIO_SMOKING_ROOM(INT iPlayersBS)
	STRUCT_EVENT_COMMON_DETAILS Event
	Event.Type = SCRIPT_EVENT_WARP_THESE_PLAYERS_TO_MUSIC_STUDIO_SMOKING_ROOM	
	Event.FromPlayerIndex = PLAYER_ID()
	
	PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_MUSIC_STUDIO_SMOKING_ROOM: pOwner = ", GET_PLAYER_NAME(Event.FromPlayerIndex))
	
	IF NOT (iPlayersBS = 0)
		PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_MUSIC_STUDIO_SMOKING_ROOM - called by local player, sending to everyone")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersBS)	
	ELSE
		PRINTLN("BROADCAST_WARP_THESE_PLAYERS_TO_MUSIC_STUDIO_SMOKING_ROOM - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_JOIN_OWNER_IN_SIMPLE_INTERIOR_LIMO_SERVICE
	STRUCT_EVENT_COMMON_DETAILS Details
	SIMPLE_INTERIORS eInteriorID
	SMPL_INT_VEH_EXIT_TYPE eExitVeh
ENDSTRUCT

PROC BROADCAST_JOIN_OWNER_IN_SIMPLE_INTERIOR_VEH_EXIT_SERVICE(SIMPLE_INTERIORS eInteriorID, INT iPlayersBS, SMPL_INT_VEH_EXIT_TYPE eExitVeh)
	SCRIPT_EVENT_DATA_JOIN_OWNER_IN_SIMPLE_INTERIOR_LIMO_SERVICE Event
	Event.Details.Type = SCRIPT_EVENT_JOIN_OWNER_IN_SIMPLE_INTERIOR_LIMO_SERVICE
	
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.eInteriorID 				= eInteriorID
	Event.eExitVeh					= eExitVeh
	PRINTLN("BROADCAST_JOIN_OWNER_IN_SIMPLE_INTERIOR_VEH_EXIT_SERVICE: eInteriorID ID = ", Event.eInteriorID, " Exit vehicle = ", eExitVeh)
	
	IF iPlayersBS != 0
		PRINTLN("BROADCAST_JOIN_OWNER_IN_SIMPLE_INTERIOR_VEH_EXIT_SERVICE - called by local player, sending to ", iPlayersBS)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersBS)	
	ELSE
		PRINTLN("BROADCAST_JOIN_OWNER_IN_SIMPLE_INTERIOR_VEH_EXIT_SERVICE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_OK_TO_CLEANUP_DELIVERABLE_ENTITY(FREEMODE_DELIVERABLE_ID eDeliverable)
	SCRIPT_EVENT_DATA_OK_TO_CLEANUP_GUNRUN_ENTITY Event
	Event.Details.Type = SCRIPT_EVENT_OK_TO_CLEANUP_DELIVERABLE_ENTITY
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_OK_TO_CLEANUP_DELIVERABLE_ENTITY: pOwner = ", NATIVE_TO_INT(Event.eDeliverable.pOwner))
	Event.eDeliverable = eDeliverable
	PRINTLN("BROADCAST_OK_TO_CLEANUP_DELIVERABLE_ENTITY: deliverable ID = ", Event.eDeliverable.iIndex)
	
	INT iPlayersBS = ALL_PLAYERS()
	
	IF NOT (iPlayersBS = 0)
		PRINTLN("BROADCAST_OK_TO_CLEANUP_DELIVERABLE_ENTITY - called by local player, sending to everyone")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersBS)	
	ELSE
		PRINTLN("BROADCAST_OK_TO_CLEANUP_DELIVERABLE_ENTITY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_OK_TO_KICK_PLAYERS_FROM_DELIVERABLE_ENTITY(FREEMODE_DELIVERABLE_ID eDeliverable)
	SCRIPT_EVENT_DATA_OK_TO_CLEANUP_GUNRUN_ENTITY Event
	Event.Details.Type = SCRIPT_EVENT_OK_TO_KICK_ALL_PLAYERS_FROM_DELIVERABLE_ENTITY
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_OK_TO_KICK_PLAYERS_FROM_DELIVERABLE_ENTITY: pOwner = ", NATIVE_TO_INT(Event.eDeliverable.pOwner))
	Event.eDeliverable = eDeliverable
	PRINTLN("BROADCAST_OK_TO_KICK_PLAYERS_FROM_DELIVERABLE_ENTITY: deliverable ID = ", Event.eDeliverable.iIndex)
	
	INT iPlayersBS = ALL_PLAYERS()
	
	IF NOT (iPlayersBS = 0)
		PRINTLN("BROADCAST_OK_TO_KICK_PLAYERS_FROM_DELIVERABLE_ENTITY - called by local player, sending to everyone")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersBS)	
	ELSE
		PRINTLN("BROADCAST_OK_TO_KICK_PLAYERS_FROM_DELIVERABLE_ENTITY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

ENUM NIGHTCLUB_POPULARITY_UPDATE_REASON
	NPUR_DANCING_IN_CLUB

#IF IS_DEBUG_BUILD
	,NPUR_UNSPECIFIED
	,NPUR_AWARD_GANG_BOSS
#ENDIF //IS_DEBUG_BUILD
ENDENUM

STRUCT SCRIPT_EVENT_DATA_NIGHTCLUB_POPULARITY_UPDATE
	STRUCT_EVENT_COMMON_DETAILS Details
	FLOAT fPopularity
	NIGHTCLUB_POPULARITY_UPDATE_REASON eReason
ENDSTRUCT

//PURPOSE: sends an event telling a remote player to modify their nightclub popularity total
PROC BROADCAST_UPDATE_NIGHTCLUB_POPULARITY_DATA(PLAYER_INDEX piTarget, FLOAT fPopularity, NIGHTCLUB_POPULARITY_UPDATE_REASON eReason)
	// Ensure parget player is acceptable
	INT iPlayerFlags
	IF piTarget != INVALID_PLAYER_INDEX()
	AND NETWORK_IS_PLAYER_ACTIVE(piTarget)
		SET_BIT(iPlayerFlags, NATIVE_TO_INT(piTarget))
	ELSE
		PRINTLN("BROADCAST_UPDATE_NIGHTCLUB_POPULARITY_DATA - piTarget (",NATIVE_TO_INT(piTarget), ") either invalid (0>x>31) or not active.")
		EXIT
	ENDIF

	//Common data
	SCRIPT_EVENT_DATA_NIGHTCLUB_POPULARITY_UPDATE Event
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_NIGHTCLUB_POPULARITY
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	
	//Nightclub popularity data
	Event.fPopularity 	= fPopularity
	Event.eReason		= eReason
		
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DANCE_ACTION
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INTERACTIONS eInteraction
ENDSTRUCT

PROC BROADCAST_DANCE_ACTION(PLAYER_INTERACTIONS eInteraction)
	SCRIPT_EVENT_DATA_DANCE_ACTION Event
	Event.Details.Type 				= SCRIPT_EVENT_DANCE_ACTION
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.eInteraction				= eInteraction
	
	// Only participants in the script of the dancing minigame should recieve events
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT(FALSE)
	IF iPlayerFlags > 0
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		PRINTLN("BROADCAST_DANCE_ACTION - Event not sent because no other players in session")
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_VEHICLE_EXISTENCE_STRUCT
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bMOC, bAvenger, bHackerTruck, bExist
	BOOL bSubmarine
	#IF FEATURE_DLC_2_2022
	BOOL bAcidLab
	#ENDIF
	PLAYER_INDEX pPropertyOwner
ENDSTRUCT

/// PURPOSE:
///    Broadcast to all players to set the vehicle to be exit for local player(Sender)
/// PARAMS:
///    pPropertyOwner - owner of property that we are entring/exiting
///    bExist - True to set exist, False set to not exist
///    bMOC - need to set MOC vehicle index to exist 
///    bAvenger - need to set Avenger vehicle index to exist 
///    bHackerTruck - need to set Hacker truck vehicle index to exist  
PROC BROADCAST_REQUEST_VEHICLE_EXISTENCE(PLAYER_INDEX pPropertyOwner, BOOL bExist, BOOL bMOC, BOOL bAvenger, BOOL bHackerTruck, BOOL bSubmarine #IF FEATURE_DLC_2_2022 , BOOL bAcidLab = FALSE #ENDIF )
	SCRIPT_EVENT_VEHICLE_EXISTENCE_STRUCT Event
	Event.Details.Type 				= SCRIPT_EVENT_VEHICLE_EXISTENCE
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bExist					= bExist
	Event.bMOC						= bMOC
	Event.bAvenger					= bAvenger
	Event.bHackerTruck				= bHackerTruck
	Event.pPropertyOwner			= pPropertyOwner
	Event.bSubmarine				= bSubmarine
	#IF FEATURE_DLC_2_2022
	Event.bAcidLab					= bAcidLab
	#ENDIF
	
	IF pPropertyOwner = INVALID_PLAYER_INDEX()
		PRINTLN("BROADCAST_REQUEST_VEHICLE_EXISTENCE - pPropertyOwner is invalid skip event")
		EXIT
	ELSE
		#IF IS_DEBUG_BUILD
		IF IS_NET_PLAYER_OK(pPropertyOwner,FALSE,FALSE)
			PRINTLN("BROADCAST_REQUEST_VEHICLE_EXISTENCE - pPropertyOwner: ", GET_PLAYER_NAME(pPropertyOwner), " bExist: ", bExist, " bMOC: ", bMOC, " bAvenger: ", bAvenger, " bHackerTruck: ", bHackerTruck," bSubmarine: ", bSubmarine #IF FEATURE_DLC_2_2022 ," bAcidLab: ", bAcidLab #ENDIF)
		ELSE
			PRINTLN("BROADCAST_REQUEST_VEHICLE_EXISTENCE - pPropertyOwner does not exist")
		ENDIF
		#ENDIF
	ENDIF	
	
	INT iPlayerFlags = ALL_PLAYERS()
	IF iPlayerFlags > 0
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		PRINTLN("BROADCAST_REQUEST_VEHICLE_EXISTENCE - Event not sent because no other players in session")
	ENDIF
ENDPROC

//PURPOSE: sends an event telling a property owner that we used drone station
STRUCT SCRIPT_EVENT_DATA_DRONE_STATION
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bHitTarget
	#IF FEATURE_HEIST_ISLAND
	INT iType, iSeat
	#ENDIF
ENDSTRUCT

PROC BROADCAST_USED_DRONE_STATION(PLAYER_INDEX pPropertyOwner, BOOL bHitTarget #IF FEATURE_HEIST_ISLAND , INT iType, INT iSeat #ENDIF )
	
	//Common data
	SCRIPT_EVENT_DATA_DRONE_STATION Event
	Event.Details.Type 				= SCRIPT_EVENT_USED_DRONE_STATION
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bHitTarget 				= bHitTarget
	#IF FEATURE_HEIST_ISLAND
	Event.iType = iType
	Event.iSeat = iSeat
	#ENDIF
	
	INT iPlayerFlags = 0
	
	IF pPropertyOwner != INVALID_PLAYER_INDEX()
		SET_BIT(iPlayerFlags, NATIVE_TO_INT(pPropertyOwner))
	ENDIF
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_USED_DRONE_STATION - pPropertyOwner is: ",NATIVE_TO_INT(pPropertyOwner), " pPropertyOwner name: ", GET_PLAYER_NAME(pPropertyOwner), " hit target: ", bHitTarget)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_UPDATE_NIGHTCLUB_POPULARITY_DATA - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC
 //FEATURE_BUSINESS_BATTLES

STRUCT SCRIPT_EVENT_DATA_TRUCK_RENOVATE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bRenovateCab
ENDSTRUCT

PROC BROADCAST_OWNER_RENOVATED_TRUCK(BOOL bRenovateCab = FALSE)
	SCRIPT_EVENT_DATA_TRUCK_RENOVATE Event
	Event.Details.Type = SCRIPT_EVENT_TRUCK_RENOVATE
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_OWNER_RENOVATED_TRUCK: player renovating truck = ", GET_PLAYER_NAME(PLAYER_ID()), " (", NATIVE_TO_INT(PLAYER_ID()), ")")
	
	Event.bRenovateCab = bRenovateCab
	PRINTLN("BROADCAST_OWNER_RENOVATED_TRUCK: renovate cab = ", bRenovateCab)
	
	INT iPlayersBS = ALL_PLAYERS()
	
	IF NOT (iPlayersBS = 0)
		PRINTLN("BROADCAST_OWNER_RENOVATED_TRUCK - called by local player, sending to everyone")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersBS)	
	ELSE
		PRINTLN("BROADCAST_OWNER_RENOVATED_TRUCK - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_NPC_INVITE_TO_SIMPLE_INTERIOR(PLAYER_INDEX pInvitee, SIMPLE_INTERIORS eSimpleInteriorID, enumCharacterList eFromCharacter, INT iAdditionalInt = SI_EVENT_INVITE_NORMAL)
	SCRIPT_EVENT_DATA_NPC_INVITE_TO_SIMPLE_INTERIOR Event
	Event.Details.Type = SCRIPT_EVENT_NPC_INVITE_TO_SIMPLE_INTERIOR
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_NPC_INVITE_TO_SIMPLE_INTERIOR: FromPlayerIndex = ", GET_PLAYER_NAME(PLAYER_ID()))
	Event.pInvitee = pInvitee
	PRINTLN("BROADCAST_NPC_INVITE_TO_SIMPLE_INTERIOR: pInvitee = ", GET_PLAYER_NAME(pInvitee))
	Event.eSimpleInteriorID =  eSimpleInteriorID
	PRINTLN("BROADCAST_NPC_INVITE_TO_SIMPLE_INTERIOR: eSimpleInteriorID = ", GET_SIMPLE_INTERIOR_DEBUG_NAME(eSimpleInteriorID))
	Event.iExtraInt = iAdditionalInt
	PRINTLN("BROADCAST_NPC_INVITE_TO_SIMPLE_INTERIOR: iAdditionalInt = ", iAdditionalInt)
	Event.eFromCharacter = eFromCharacter
	PRINTLN("BROADCAST_NPC_INVITE_TO_SIMPLE_INTERIOR: eFromCharacter = ", eFromCharacter)
	INT iPlayersFlag = SPECIFIC_PLAYER(pInvitee)
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("BROADCAST_NPC_INVITE_TO_SIMPLE_INTERIOR - called by local player, sending to ", GET_PLAYER_NAME(pInvitee))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)
	ELSE
		PRINTLN("BROADCAST_NPC_INVITE_TO_SIMPLE_INTERIOR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_INVITE_TO_SIMPLE_INTERIOR(PLAYER_INDEX pInvitee, SIMPLE_INTERIORS eSimpleInteriorID, INT iAdditionalInt = SI_EVENT_INVITE_NORMAL)
	SCRIPT_EVENT_DATA_INVITE_TO_SIMPLE_INTERIOR Event
	Event.Details.Type = SCRIPT_EVENT_INVITE_TO_SIMPLE_INTERIOR
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_INVITE_TO_SIMPLE_INTERIOR: FromPlayerIndex = ", GET_PLAYER_NAME(PLAYER_ID()))
	Event.pInvitee = pInvitee
	PRINTLN("BROADCAST_INVITE_TO_SIMPLE_INTERIOR: pInvitee = ", GET_PLAYER_NAME(pInvitee))
	Event.eSimpleInteriorID = eSimpleInteriorID
	PRINTLN("BROADCAST_INVITE_TO_SIMPLE_INTERIOR: eSimpleInteriorID = ", GET_SIMPLE_INTERIOR_DEBUG_NAME(eSimpleInteriorID))
	Event.iExtraInt = iAdditionalInt
	PRINTLN("BROADCAST_INVITE_TO_SIMPLE_INTERIOR: iAdditionalInt = ", iAdditionalInt)
	
	INT iPlayersFlag = SPECIFIC_PLAYER(pInvitee)
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("BROADCAST_INVITE_TO_SIMPLE_INTERIOR - called by local player, sending to ", GET_PLAYER_NAME(pInvitee))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)
	ELSE
		PRINTLN("BROADCAST_INVITE_TO_SIMPLE_INTERIOR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_INVITE_ALL_TO_SIMPLE_INTERIOR(SIMPLE_INTERIORS eSimpleInteriorID, INT iPlayersBS = HIGHEST_INT)
	SCRIPT_EVENT_DATA_INVITE_TO_SIMPLE_INTERIOR Event
	Event.Details.Type = SCRIPT_EVENT_INVITE_TO_SIMPLE_INTERIOR
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_INVITE_ALL_TO_SIMPLE_INTERIOR: FromPlayerIndex = ", GET_PLAYER_NAME(PLAYER_ID()))
	Event.eSimpleInteriorID = eSimpleInteriorID
	PRINTLN("BROADCAST_INVITE_ALL_TO_SIMPLE_INTERIOR: eSimpleInteriorID = ", GET_SIMPLE_INTERIOR_DEBUG_NAME(eSimpleInteriorID))
	
	INT iPlayersFlag = ALL_PLAYERS(FALSE, FALSE)
	
	iPlayersFlag = iPlayersFlag & iPlayersBS
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("BROADCAST_INVITE_ALL_TO_SIMPLE_INTERIOR - called by local player, iPlayersFlag = ", iPlayersFlag)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)
	ELSE
		PRINTLN("BROADCAST_INVITE_ALL_TO_SIMPLE_INTERIOR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_INVITE_GANG_TO_SIMPLE_INTERIOR(SIMPLE_INTERIORS eSimpleInteriorID, INT iAdditionalInt = SI_EVENT_INVITE_NORMAL)
	SCRIPT_EVENT_DATA_INVITE_TO_SIMPLE_INTERIOR Event
	Event.Details.Type = SCRIPT_EVENT_INVITE_TO_SIMPLE_INTERIOR
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_INVITE_GANG_TO_SIMPLE_INTERIOR: FromPlayerIndex = ", GET_PLAYER_NAME(PLAYER_ID()))
	Event.eSimpleInteriorID = eSimpleInteriorID
	PRINTLN("BROADCAST_INVITE_GANG_TO_SIMPLE_INTERIOR: eSimpleInteriorID = ", GET_SIMPLE_INTERIOR_DEBUG_NAME(eSimpleInteriorID))
	Event.iExtraInt = iAdditionalInt
	PRINTLN("BROADCAST_INVITE_GANG_TO_SIMPLE_INTERIOR: iAdditionalInt = ", iAdditionalInt)
	
	INT iPlayersFlag = ALL_GANG_MEMBERS(FALSE, FALSE)
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("BROADCAST_INVITE_GANG_TO_SIMPLE_INTERIOR - called by local player, iPlayersFlag = ", iPlayersFlag)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)
	ELSE
		PRINTLN("BROADCAST_INVITE_GANG_TO_SIMPLE_INTERIOR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_CANCEL_INVITE_TO_SIMPLE_INTERIOR(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_BASIC_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_CANCEL_INVITE_TO_SIMPLE_INTERIOR
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_CANCEL_INVITE_TO_SIMPLE_INTERIOR - SENT BY ", GET_PLAYER_NAME(PLAYER_ID()))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CANCEL_INVITE_TO_SIMPLE_INTERIOR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

#IF FEATURE_CASINO_NIGHTCLUB
ENUM CASINO_NIGHTCLUB_ANIM_EVENT
	CNAE_ACKNOWLEDGE_PAYMENT
ENDENUM
	
STRUCT SCRIPT_EVENT_DATA_CASINO_NIGHTCLUB_ANIM_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	CASINO_NIGHTCLUB_ANIM_EVENT eAnimEvent
ENDSTRUCT

PROC BROADCAST_CASINO_NIGHTCLUB_ANIM_EVENT(CASINO_NIGHTCLUB_ANIM_EVENT eAnimEvent, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_CASINO_NIGHTCLUB_ANIM_EVENT  Event
	Event.Details.Type 				= SCRIPT_EVENT_CASINO_NIGHTCLUB_ANIM_EVENT
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.eAnimEvent 				= eAnimEvent
	
	IF iPlayerFlags != 0
		PRINTLN("BROADCAST_CASINO_NIGHTCLUB_ANIM_EVENT - sending event. Flag: ", iPlayerFlags)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		PRINTLN("BROADCAST_SUBMARINE_MISSILE_LAUNCH_VFX - iPlayerFlags is invalid")
	ENDIF
ENDPROC
#ENDIF

#IF FEATURE_HEIST_ISLAND
STRUCT SCRIPT_EVENT_DATA_SUBMARINE_MISSILE_LAUNCH_VFX
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iLaunchHatch
ENDSTRUCT

PROC BROADCAST_SUBMARINE_MISSILE_LAUNCH_VFX(INT iLaunchHatch)
	SCRIPT_EVENT_DATA_SUBMARINE_MISSILE_LAUNCH_VFX  Event
	Event.Details.Type 				= SCRIPT_EVENT_SUBMARINE_MISSLIE_LAUNCH_VFX
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iLaunchHatch = iLaunchHatch

	INT iPlayerFlags = ALL_PLAYERS(FALSE)
	
	IF iPlayerFlags != 0
		PRINTLN("BROADCAST_SUBMARINE_MISSILE_LAUNCH_VFX - sending event")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		PRINTLN("BROADCAST_SUBMARINE_MISSILE_LAUNCH_VFX - iPlayerFlags is invalid")
	ENDIF
ENDPROC

PROC BROADCAST_LAUNCH_ISLAND_BACKUP_HELI(INT iInstance, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_ISLAND_BACKUP_HELI_LAUNCH sEvent
	sEvent.Details.Type 			= SCRIPT_EVENT_ISLAND_BACKUP_HELI_LAUNCH
	sEvent.Details.FromPlayerIndex 	= PLAYER_ID()
	sEvent.iScriptInstance = iInstance
	
	IF iPlayerFlags != 0
		PRINTLN("BROADCAST_LAUNCH_ISLAND_BACKUP_HELI - sending event")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, sEvent, SIZE_OF(sEvent), iPlayerFlags)
	ELSE
		PRINTLN("BROADCAST_LAUNCH_ISLAND_BACKUP_HELI - iPlayerFlags is invalid")
	ENDIF
ENDPROC

PROC BROADCAST_INVITE_TO_HEIST_ISLAND_BEACH_PARTY(PLAYER_INDEX pInvitee, BOOL bInvite = TRUE, BOOL bIsTagAlong = FALSE)
	SCRIPT_EVENT_DATA_INVITE_TO_HEIST_ISLAND_BEACH_PARTY Event
	Event.Details.Type = SCRIPT_EVENT_INVITE_TO_HEIST_ISLAND_BEACH_PARTY
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_INVITE_TO_HEIST_ISLAND_BEACH_PARTY: FromPlayerIndex = ", GET_PLAYER_NAME(PLAYER_ID()))
	Event.pInvitee = pInvitee
	PRINTLN("BROADCAST_INVITE_TO_HEIST_ISLAND_BEACH_PARTY: pInvitee = ", GET_PLAYER_NAME(pInvitee))
	
	Event.bIsInvite = bInvite
	PRINTLN("BROADCAST_INVITE_TO_HEIST_ISLAND_BEACH_PARTY: bIsInvite = ", bInvite)
	
	Event.bIsTagAlong = bIsTagAlong
	PRINTLN("BROADCAST_INVITE_TO_HEIST_ISLAND_BEACH_PARTY: bIsTagAlong = ", bIsTagAlong)
	
	INT iPlayersFlag = SPECIFIC_PLAYER(pInvitee)
	
	IF NOT (iPlayersFlag = 0)	
		PRINTLN("BROADCAST_INVITE_TO_HEIST_ISLAND_BEACH_PARTY - called by local player, sending to ", GET_PLAYER_NAME(pInvitee))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)
	ELSE
		PRINTLN("BROADCAST_INVITE_TO_HEIST_ISLAND_BEACH_PARTY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_INVITE_ALL_TO_HEIST_ISLAND_BEACH_PARTY(INT iExludedPlayersBS = HIGHEST_INT, BOOL bIsInvite = TRUE, BOOL bIsTagAlong = FALSE)
	SCRIPT_EVENT_DATA_INVITE_TO_HEIST_ISLAND_BEACH_PARTY Event
	Event.Details.Type = SCRIPT_EVENT_INVITE_TO_HEIST_ISLAND_BEACH_PARTY
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_INVITE_ALL_TO_HEIST_ISLAND_BEACH_PARTY: FromPlayerIndex = ", GET_PLAYER_NAME(PLAYER_ID()))
	
	Event.bIsInvite = bIsInvite
	PRINTLN("BROADCAST_INVITE_ALL_TO_HEIST_ISLAND_BEACH_PARTY: bIsInvite = ", bIsInvite)
	
	Event.bIsTagAlong = bIsTagAlong
	PRINTLN("BROADCAST_INVITE_ALL_TO_HEIST_ISLAND_BEACH_PARTY: bIsTagAlong = ", bIsTagAlong)
	
	INT iPlayersFlag = ALL_PLAYERS(FALSE, FALSE)
	
	iPlayersFlag = iPlayersFlag & iExludedPlayersBS
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("BROADCAST_INVITE_ALL_TO_HEIST_ISLAND_BEACH_PARTY - called by local player, iPlayersFlag = ", iPlayersFlag)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)
	ELSE
		PRINTLN("BROADCAST_INVITE_ALL_TO_HEIST_ISLAND_BEACH_PARTY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_INVITE_PLAYERS_TO_HEIST_ISLAND_BEACH_PARTY(INT iPlayersBS = 0, BOOL bIsInvite = TRUE, BOOL bIsTagAlong = FALSE)
	SCRIPT_EVENT_DATA_INVITE_TO_HEIST_ISLAND_BEACH_PARTY Event
	Event.Details.Type = SCRIPT_EVENT_INVITE_TO_HEIST_ISLAND_BEACH_PARTY
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_INVITE_ALL_TO_HEIST_ISLAND_BEACH_PARTY: FromPlayerIndex = ", GET_PLAYER_NAME(PLAYER_ID()))
	
	Event.bIsInvite = bIsInvite
	PRINTLN("BROADCAST_INVITE_ALL_TO_HEIST_ISLAND_BEACH_PARTY: bIsInvite = ", bIsInvite)
	
	Event.bIsTagAlong = bIsTagAlong
	PRINTLN("BROADCAST_INVITE_ALL_TO_HEIST_ISLAND_BEACH_PARTY: bIsTagAlong = ", bIsTagAlong)

	IF NOT (iPlayersBS = 0)
		PRINTLN("BROADCAST_INVITE_ALL_TO_HEIST_ISLAND_BEACH_PARTY - called by local player, iPlayersBS = ", iPlayersBS)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersBS)
	ELSE
		PRINTLN("BROADCAST_INVITE_ALL_TO_HEIST_ISLAND_BEACH_PARTY - iPlayersBS = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_HEIST_ISLAND_WARP_TRANSITION_TO_ALL(ENUM_TO_INT eTransitionType, BOOL bIsIslandJoin, INT iExludedPlayersBS = HIGHEST_INT)
	SCRIPT_EVENT_DATA_HEIST_ISLAND_WARP_TRANSITION Event
	Event.Details.Type = SCRIPT_EVENT_HEIST_ISLAND_WARP_TRANSITION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bIsIslandJoin = bIsIslandJoin
	Event.iTransitionType = ENUM_TO_INT(eTransitionType)

	INT iPlayersFlag = ALL_PLAYERS(TRUE, FALSE)
	iPlayersFlag = iPlayersFlag & iExludedPlayersBS
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("BROADCAST_HEIST_ISLAND_WARP_TRANSITION_TO_ALL - called by local player, iPlayersFlag = ", iPlayersFlag)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)
	ELSE
		PRINTLN("BROADCAST_HEIST_ISLAND_WARP_TRANSITION_TO_ALL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_HEIST_ISLAND_WARP_TRANSITION_TO_PLAYERS(ENUM_TO_INT eTransitionType, BOOL bIsIslandJoin, INT iPlayersBS = 0)
	SCRIPT_EVENT_DATA_HEIST_ISLAND_WARP_TRANSITION Event
	Event.Details.Type = SCRIPT_EVENT_HEIST_ISLAND_WARP_TRANSITION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bIsIslandJoin = bIsIslandJoin
	Event.iTransitionType = ENUM_TO_INT(eTransitionType)

	IF NOT (iPlayersBS = 0)
		PRINTLN("BROADCAST_HEIST_ISLAND_WARP_TRANSITION_TO_PLAYERS - called by local player, iPlayersBS = ", iPlayersBS)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersBS)
	ELSE
		PRINTLN("BROADCAST_HEIST_ISLAND_WARP_TRANSITION_TO_PLAYERS - iPlayersBS = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC BROADCAST_CANCEL_INVITE_TO_HEIST_ISLAND_BEACH_PARTY(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_BASIC_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_CANCEL_INVITE_TO_HEIST_ISLAND_BEACH_PARTY
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_CANCEL_INVITE_TO_HEIST_ISLAND_BEACH_PARTY - SENT BY ", GET_PLAYER_NAME(PLAYER_ID()))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CANCEL_INVITE_TO_HEIST_ISLAND_BEACH_PARTY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC
#ENDIF

#IF FEATURE_GEN9_EXCLUSIVE
PROC BROADCAST_PURCHASED_REMOTE_PLAYER_VEHICLE(PLAYER_INDEX remoteOwner)
	SCRIPT_EVENT_DATA_BASIC_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_PURCHASED_REMOTE_PLAYER_VEHICLE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	IF IS_NET_PLAYER_OK(remoteOwner, FALSE, TRUE)
		INT iPlayersFlag = 0
		SET_BIT(iPlayersFlag , NATIVE_TO_INT(remoteOwner))
		
		IF NOT (iPlayersFlag = 0)
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)
		ENDIF		
	ELSE
		PRINTLN("BROADCAST_PURCHASED_REMOTE_PLAYER_VEHICLE - sender  ", GET_PLAYER_NAME(remoteOwner) , " left session!" )
	ENDIF	
ENDPROC
#ENDIF

STRUCT SCRIPT_EVENT_DATA_SCRIPT_EVENT_BOOS_POACH_METRIC
	STRUCT_EVENT_COMMON_DETAILS Details
	INT bossId1
	INT bossId2
	BOOL isVip
ENDSTRUCT

PROC BROADCAST_SCRIPT_EVENT_BOOS_POACH_METRIC(PLAYER_INDEX piPlayer, INT bossId1, INT bossId2, BOOL isVip)
	SCRIPT_EVENT_DATA_SCRIPT_EVENT_BOOS_POACH_METRIC Event
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.Details.Type = SCRIPT_EVENT_BOOS_POACH_METRIC
	Event.bossId1 = bossId1
	Event.bossId2 = bossId2
	Event.isVip = isVip
	
	INT iPlayersFlag
	SET_BIT(iPlayersFlag, NATIVE_TO_INT(piPlayer))
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("[MAGNATE_GANG_BOSS] GB_GOON_CHANGE_GANG - BROADCAST_SCRIPT_EVENT_BOOS_POACH_METRIC - Event.Details.FromPlayerIndex = ", 
				GET_PLAYER_NAME(Event.Details.FromPlayerIndex), " - Event.bossId1 = ", Event.bossId1,
				" - Event.bossId2 = ", Event.bossId2, " - Event.isVip = ", Event.isVip) 
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		PRINTLN("[MAGNATE_GANG_BOSS] GB_GOON_CHANGE_GANG - BROADCAST_SCRIPT_EVENT_BOOS_POACH_METRIC - playerflags = 0 so not broadcasting")	
	ENDIF	
ENDPROC


PROC PROCESS_SCRIPT_EVENT_BOOS_POACH_METRIC(INT iEventID)
	PRINTLN("[MAGNATE_GANG_BOSS] GB_GOON_CHANGE_GANG - PROCESS_SCRIPT_EVENT_BOOS_POACH_METRIC") 
	
	SCRIPT_EVENT_DATA_SCRIPT_EVENT_BOOS_POACH_METRIC Event
	
	IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iEventID, Event, SIZE_OF(Event))
		PRINTLN("[MAGNATE_GANG_BOSS] GB_GOON_CHANGE_GANG - PROCESS_SCRIPT_EVENT_BOOS_POACH_METRIC - Event.Details.FromPlayerIndex = ", 
				GET_PLAYER_NAME(Event.Details.FromPlayerIndex), " - Event.bossId1 = ", Event.bossId1,
				" - Event.bossId2 = ", Event.bossId2, " - Event.isVip = ", Event.isVip) 
				
		SEND_METRIC_VIP_POACH(Event.bossId1, Event.bossId2, Event.isVip)
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				 		  BIKER RESUPPLY EVENTS												
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_BIKER_FACTORY_SUPPLY_DELIVERED
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerDoingDelivery
	INT iSupplyIndex = -1
ENDSTRUCT

PROC BROADCAST_EVENT_BIKER_FACTORY_SUPPLY_DELIVERED(PLAYER_INDEX playerDoingDelivery, INT iSupplyIndex)
	
	SCRIPT_EVENT_DATA_BIKER_FACTORY_SUPPLY_DELIVERED Event
	Event.Details.Type = SCRIPT_EVENT_BIKER_FACTORY_SUPPLY_DELIVERED
	
	Event.playerDoingDelivery = playerDoingDelivery
	PRINTLN("BROADCAST_EVENT_BIKER_FACTORY_SUPPLY_DELIVERED: playerDoingDelivery = ", GET_PLAYER_NAME(Event.playerDoingDelivery))
	
	Event.iSupplyIndex = iSupplyIndex
	PRINTLN("BROADCAST_EVENT_BIKER_FACTORY_SUPPLY_DELIVERED: iSupplyIndex = ", iSupplyIndex)
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF iPlayersFlag != 0
		NET_PRINT("BROADCAST_EVENT_BIKER_FACTORY_SUPPLY_DELIVERED - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_EVENT_BIKER_FACTORY_SUPPLY_DELIVERED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_BIKER_PLAY_BLOOD_EFFECT
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR Rotation
	VECTOR Offset
ENDSTRUCT


PROC BROADCAST_EVENT_BIKER_PLAY_BLOOD_EFFECT(VECTOR Offset, VECTOR Rotation)
	
	SCRIPT_EVENT_DATA_BIKER_PLAY_BLOOD_EFFECT Event
	Event.Details.Type = SCRIPT_EVENT_BIKER_PLAY_BLOOD_EFFECT
	
	Event.Offset = Offset
	PRINTLN("BROADCAST_EVENT_BIKER_PLAY_BLOOD_EFFECT: Offset = ", Offset)
	
	Event.Rotation = Rotation
	PRINTLN("BROADCAST_EVENT_BIKER_PLAY_BLOOD_EFFECT: Rotation = ", Rotation)
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF iPlayersFlag != 0
		NET_PRINT("BROADCAST_EVENT_BIKER_PLAY_BLOOD_EFFECT - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_EVENT_BIKER_PLAY_BLOOD_EFFECT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║				 		  IMPORT/EXPORT DELIVERY EVENTS												
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════

STRUCT SCRIPT_EVENT_DATA_LAUNCH_DELIVERY_SCRIPT
	STRUCT_EVENT_COMMON_DETAILS Details
	IE_DROPOFF eDropoffID
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_START_DELIVERY_CUTSCENE
	STRUCT_EVENT_COMMON_DETAILS Details
	IE_DROPOFF eDropoffID
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_PLAYER_DELIVERED_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iDeliveryRewardValue
	INT iRepairCost
	PLAYER_INDEX playerDoingDelivery
	PLAYER_INDEX playerOriginalOwner
	MODEL_NAMES vehicleModel
	IE_DROPOFF eDropoffID
	INT iVehicleIndex // This is index from buy/sell mission, set from 0 to 3 to mark which vehicle is being delivered
	IE_VEHICLE_ENUM eIEVehicle
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_OK_TO_CLEANUP_EXPORT_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerOriginalOwner
	MODEL_NAMES vehicleModel
	INT iVehicleIndex
	BOOL bSentByServer
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_START_PRE_SELL_VEHICLE_MOD
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerModdingVeh[ciMaxIESellMissionVehicles]
	INT iVehiclesToMod[ciMaxIESellMissionVehicles]
	VEHICLE_EXPORT_DROPOFF_TYPE eDropOffLocation
	BOOL bCollectionOfVehicles
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_MOVE_BETWEEN_OFFICE_GARAGE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iInteriorToMove
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_REQUEST_SVM_START_HELI
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iBuildingID
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_GET_IN_SVM_START_HELI
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_REQUEST_SERVER_PERMISSION_TO_CLEANUP_EXPORT_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerDoingDelivery
	PLAYER_INDEX playerOriginalOwner
	MODEL_NAMES vehicleModel
	INT iVehicleIndex
ENDSTRUCT

PROC BROADCAST_LAUNCH_DELIVERY_SCRIPT(IE_DROPOFF eDropoffID)
	SCRIPT_EVENT_DATA_LAUNCH_DELIVERY_SCRIPT Event
	Event.Details.Type = SCRIPT_EVENT_LAUNCH_DELIVERY_SCRIPT
	
	Event.eDropoffID = eDropoffID
	PRINTLN("BROADCAST_LAUNCH_DELIVERY_SCRIPT: eDropoffID = ", ENUM_TO_INT(eDropoffID))
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_LAUNCH_DELIVERY_SCRIPT - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_LAUNCH_DELIVERY_SCRIPT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_START_DELIVERY_CUTSCENE(IE_DROPOFF eDropoffID)
	SCRIPT_EVENT_DATA_START_DELIVERY_CUTSCENE Event
	Event.Details.Type = SCRIPT_EVENT_START_DELIVERY_CUTSCENE
	
	Event.eDropoffID = eDropoffID
	PRINTLN("BROADCAST_START_DELIVERY_CUTSCENE: eDropoffID = ", ENUM_TO_INT(eDropoffID))
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_START_DELIVERY_CUTSCENE - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_START_DELIVERY_CUTSCENE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

FUNC BOOL SHOULD_SEND_VEH_WH_EVENT(IE_DROPOFF eDropoffID = IE_DROPOFF_INVALID)
	SWITCH eDropoffID
		CASE IE_DROPOFF_WAREHOUSE_1
		CASE IE_DROPOFF_WAREHOUSE_2
		CASE IE_DROPOFF_WAREHOUSE_3
		CASE IE_DROPOFF_WAREHOUSE_4
		CASE IE_DROPOFF_WAREHOUSE_5
		CASE IE_DROPOFF_WAREHOUSE_6
		CASE IE_DROPOFF_WAREHOUSE_7
		CASE IE_DROPOFF_WAREHOUSE_8
		CASE IE_DROPOFF_WAREHOUSE_9
		CASE IE_DROPOFF_WAREHOUSE_10
			RETURN TRUE
	ENDSWITCH
	
	RETURN FALSE
ENDFUNC

FUNC BOOL SHOULD_SEND_VEH_SCR_EVENT(IE_DROPOFF eDropoffID = IE_DROPOFF_INVALID)
	SWITCH eDropoffID
		CASE IE_DROPOFF_POLICE_STATION_1
		CASE IE_DROPOFF_POLICE_STATION_2
		CASE IE_DROPOFF_POLICE_STATION_3
		CASE IE_DROPOFF_POLICE_STATION_4
		CASE IE_DROPOFF_POLICE_STATION_5
		CASE IE_DROPOFF_POLICE_STATION_6
		CASE IE_DROPOFF_POLICE_STATION_7
		CASE IE_DROPOFF_POLICE_STATION_8
		CASE IE_DROPOFF_POLICE_STATION_9
		CASE IE_DROPOFF_SCRAPYARD_1
		CASE IE_DROPOFF_SCRAPYARD_2
		CASE IE_DROPOFF_SCRAPYARD_3
			RETURN TRUE
	ENDSWITCH
	
	RETURN FALSE
ENDFUNC

PROC BROADCAST_PLAYER_DELIVERED_VEHICLE(PLAYER_INDEX playerDeliverer, PLAYER_INDEX playerVehicleOwner, MODEL_NAMES vehicleModel, INT iVehicleIndex, IE_VEHICLE_ENUM eIEVeh, INT iDeliveryRewardValue, INT iRepairCost = 0, IE_DROPOFF eDropoffID = IE_DROPOFF_INVALID)
	
	SCRIPT_EVENT_DATA_PLAYER_DELIVERED_VEHICLE Event
	
	IF SHOULD_SEND_VEH_WH_EVENT(eDropoffID)		
		PRINTLN("BROADCAST_PLAYER_DELIVERED_VEHICLE - Sending SCRIPT_EVENT_PLAYER_DELIVERED_VEHICLE_WH")
		Event.Details.Type = SCRIPT_EVENT_PLAYER_DELIVERED_VEHICLE_WH

	ELIF SHOULD_SEND_VEH_SCR_EVENT(eDropoffID)
	
		PRINTLN("BROADCAST_PLAYER_DELIVERED_VEHICLE - Sending SCRIPT_EVENT_PLAYER_DELIVERED_VEHICLE_SCR")
		Event.Details.Type = SCRIPT_EVENT_PLAYER_DELIVERED_VEHICLE_SCR
	
	ELIF eDropoffID = IE_DROPOFF_INVALID
	OR eDropoffID = IE_DROPOFF_COUNT
	
		SCRIPT_ASSERT("BROADCAST_PLAYER_DELIVERED_VEHICLE - Passed invalid dropoff!")
		PRINTLN("BROADCAST_PLAYER_DELIVERED_VEHICLE - Passed invalid dropoff: ", eDropoffID)
		EXIT
		
	ELSE		
		PRINTLN("BROADCAST_PLAYER_DELIVERED_VEHICLE - Sending SCRIPT_EVENT_PLAYER_DELIVERED_VEHICLE_BUYER")
		Event.Details.Type = SCRIPT_EVENT_PLAYER_DELIVERED_VEHICLE_BUYER
	ENDIF
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.playerDoingDelivery = playerDeliverer
	PRINTLN("BROADCAST_PLAYER_DELIVERED_VEHICLE: playerDoingDelivery = ", GET_PLAYER_NAME(playerDeliverer))
	
	Event.playerOriginalOwner = playerVehicleOwner
	PRINTLN("BROADCAST_PLAYER_DELIVERED_VEHICLE: playerOriginalOwner = ", GET_PLAYER_NAME(playerVehicleOwner))
	
	Event.vehicleModel = vehicleModel
	PRINTLN("BROADCAST_PLAYER_DELIVERED_VEHICLE: vehicleModel = ", vehicleModel)
	
	Event.iVehicleIndex = iVehicleIndex
	PRINTLN("BROADCAST_PLAYER_DELIVERED_VEHICLE: iVehicleIndex = ", iVehicleIndex)
	
	Event.iDeliveryRewardValue = iDeliveryRewardValue
	PRINTLN("BROADCAST_PLAYER_DELIVERED_VEHICLE: iDeliveryRewardValue = ", iDeliveryRewardValue)
	
	Event.eDropoffID = eDropoffID
	PRINTLN("BROADCAST_PLAYER_DELIVERED_VEHICLE: eDropoffID = ", ENUM_TO_INT(eDropoffID))
	
	Event.eIEVehicle = eIEVeh
	PRINTLN("BROADCAST_PLAYER_DELIVERED_VEHICLE: eIEVehicle = ", ENUM_TO_INT(eIEVeh))
	
	Event.iRepairCost = iRepairCost
	PRINTLN("BROADCAST_PLAYER_DELIVERED_VEHICLE: iRepairCost = ", iRepairCost)
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_PLAYER_DELIVERED_VEHICLE - called by local player" ) NET_NL()
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_PLAYER_DELIVERED_VEHICLE - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF	
	
ENDPROC

PROC BROADCAST_REQUEST_SERVER_PERMISSION_TO_CLEANUP_EXPORT_VEHICLE(PLAYER_INDEX playerVehicleOwner,PLAYER_INDEX playerDoingDelivery, MODEL_NAMES vehicleModel, INT iVehicleIndex)
	SCRIPT_EVENT_DATA_REQUEST_SERVER_PERMISSION_TO_CLEANUP_EXPORT_VEHICLE Event
	
	Event.Details.Type = SCRIPT_EVENT_REQUEST_SERVER_PERMISSION_TO_CLEANUP_EXPORT_VEHICLE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.playerOriginalOwner = playerVehicleOwner
	PRINTLN("BROADCAST_REQUEST_SERVER_PERMISSION_TO_CLEANUP_EXPORT_VEHICLE: playerOriginalOwner = ", GET_PLAYER_NAME(playerVehicleOwner))
	
	Event.playerDoingDelivery = playerDoingDelivery
	PRINTLN("BROADCAST_REQUEST_SERVER_PERMISSION_TO_CLEANUP_EXPORT_VEHICLE: playerDoingDelivery = ", GET_PLAYER_NAME(playerDoingDelivery))
	
	Event.vehicleModel = vehicleModel
	PRINTLN("BROADCAST_REQUEST_SERVER_PERMISSION_TO_CLEANUP_EXPORT_VEHICLE: vehicleModel = ", vehicleModel)
	
	Event.iVehicleIndex = iVehicleIndex
	PRINTLN("BROADCAST_REQUEST_SERVER_PERMISSION_TO_CLEANUP_EXPORT_VEHICLE: iVehicleIndex = ", iVehicleIndex)
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_REQUEST_SERVER_PERMISSION_TO_CLEANUP_EXPORT_VEHICLE - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_REQUEST_SERVER_PERMISSION_TO_CLEANUP_EXPORT_VEHICLE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

/// PURPOSE:
///    
/// PARAMS:
///    playerVehicleOwner - 
///    vehicleModel - 
///    iVehicleIndex - 
///    bSentByServer - set to TRUE if this is broadcast sent by server when player fails to do it
PROC BROADCAST_OK_TO_CLEANUP_EXPORT_VEHICLE(PLAYER_INDEX playerVehicleOwner, MODEL_NAMES vehicleModel, INT iVehicleIndex, BOOL bSentByServer = FALSE)

	IF playerVehicleOwner = INVALID_PLAYER_INDEX()
	OR NOT IS_NET_PLAYER_OK(playerVehicleOwner, FALSE)
		PRINTLN("BROADCAST_OK_TO_CLEANUP_EXPORT_VEHICLE - not doing this because playerVehicleOwner is invalid!")
		EXIT
	ENDIF

	SCRIPT_EVENT_DATA_OK_TO_CLEANUP_EXPORT_VEHICLE Event
	
	Event.Details.Type = SCRIPT_EVENT_OK_TO_CLEANUP_EXPORT_VEHICLE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.playerOriginalOwner = playerVehicleOwner
	PRINTLN("BROADCAST_OK_TO_CLEANUP_EXPORT_VEHICLE: playerDoingDelivery = ", GET_PLAYER_NAME(playerVehicleOwner))
	
	Event.vehicleModel = vehicleModel
	PRINTLN("BROADCAST_OK_TO_CLEANUP_EXPORT_VEHICLE: vehicleModel = ", vehicleModel)
	
	Event.iVehicleIndex = iVehicleIndex
	PRINTLN("BROADCAST_OK_TO_CLEANUP_EXPORT_VEHICLE: iVehicleIndex = ", iVehicleIndex)
	
	Event.bSentByServer = bSentByServer
	PRINTLN("BROADCAST_OK_TO_CLEANUP_EXPORT_VEHICLE: bSentByServer = ", GET_STRING_FROM_BOOL(bSentByServer))
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_OK_TO_CLEANUP_EXPORT_VEHICLE - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_OK_TO_CLEANUP_EXPORT_VEHICLE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_REQUEST_SVM_START_HELI(INT iBuildingID)
	SCRIPT_EVENT_DATA_REQUEST_SVM_START_HELI Event
	Event.Details.Type = SCRIPT_EVENT_REQUEST_SVM_START_HELI
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_REQUEST_SVM_START_HELI: FromPlayerIndex = ", GET_PLAYER_NAME(PLAYER_ID()))
	
	Event.iBuildingID = iBuildingID
	PRINTLN("BROADCAST_REQUEST_SVM_START_HELI: iBuildingID = ", iBuildingID)
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_REQUEST_SVM_START_HELI - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_REQUEST_SVM_START_HELI - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_GET_IN_SVM_START_HELI()
	SCRIPT_EVENT_DATA_GET_IN_SVM_START_HELI Event
	Event.Details.Type = SCRIPT_EVENT_GET_IN_SVM_HELI
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_GET_IN_SVM_START_HELI: FromPlayerIndex = ", GET_PLAYER_NAME(PLAYER_ID()))
	
	INT iPlayersFlag = ALL_PLAYERS(DEFAULT, FALSE)
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_GET_IN_SVM_START_HELI - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_GET_IN_SVM_START_HELI - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_EXPORT_VEHICLE_UPDATE_CURRENT_CHECKPOINT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCheckpointOnRouteTo
	INT iPed
ENDSTRUCT

PROC BROADCAST_EVENT_EXPORT_VEHICLE_UPDATE_CURRENT_CHECKPOINT(INT iCheckpointOnRouteTo, INT iPed)
	
	SCRIPT_EVENT_DATA_EXPORT_VEHICLE_UPDATE_CURRENT_CHECKPOINT Event
	Event.Details.Type = SCRIPT_EVENT_EXPORT_VEHICLE_UPDATE_CURRENT_CHECKPOINT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iCheckpointOnRouteTo = iCheckpointOnRouteTo
	PRINTLN("BROADCAST_EVENT_EXPORT_VEHICLE_UPDATE_CURRENT_CHECKPOINT: iCheckpointOnRouteTo = ", iCheckpointOnRouteTo)
	
	Event.iPed = iPed
	PRINTLN("BROADCAST_EVENT_EXPORT_VEHICLE_UPDATE_CURRENT_CHECKPOINT: iPed = ", iPed)
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF iPlayersFlag != 0
		NET_PRINT("BROADCAST_EVENT_EXPORT_VEHICLE_UPDATE_CURRENT_CHECKPOINT - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_EVENT_EXPORT_VEHICLE_UPDATE_CURRENT_CHECKPOINT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCheckpointOnRouteTo
	INT iPed
	INT iFrameCount
ENDSTRUCT

PROC BROADCAST_EVENT_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT(INT iCheckpointOnRouteTo, INT iPed)
	
	SCRIPT_EVENT_DATA_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT Event
	Event.Details.Type = SCRIPT_EVENT_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iCheckpointOnRouteTo = iCheckpointOnRouteTo
	PRINTLN("BROADCAST_EVENT_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT: iCheckpointOnRouteTo = ", iCheckpointOnRouteTo)
	
	Event.iPed = iPed
	PRINTLN("BROADCAST_EVENT_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT: iPed = ", iPed)
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF iPlayersFlag != 0
		NET_PRINT("BROADCAST_EVENT_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_EVENT_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

PROC BROADCAST_EVENT_SMUGGLER_VEHICLE_UPDATE_CURRENT_CHECKPOINT(INT iCheckpointOnRouteTo, INT iPed)
	
	SCRIPT_EVENT_DATA_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT Event
	Event.Details.Type = SCRIPT_EVENT_SMUGGLER_VEHICLE_UPDATE_CURRENT_CHECKPOINT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iCheckpointOnRouteTo = iCheckpointOnRouteTo
	PRINTLN("BROADCAST_EVENT_SMUGGLER_VEHICLE_UPDATE_CURRENT_CHECKPOINT: iCheckpointOnRouteTo = ", iCheckpointOnRouteTo)
	
	Event.iPed = iPed
	PRINTLN("BROADCAST_EVENT_SMUGGLER_VEHICLE_UPDATE_CURRENT_CHECKPOINT: iPed = ", iPed)
	
	Event.iFrameCount = GET_FRAME_COUNT()
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF iPlayersFlag != 0
		NET_PRINT("BROADCAST_EVENT_SMUGGLER_VEHICLE_UPDATE_CURRENT_CHECKPOINT - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_EVENT_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

PROC BROADCAST_EVENT_BUSINESS_VEHICLE_UPDATE_CURRENT_CHECKPOINT(INT iCheckpointOnRouteTo, INT iPed)
	
	SCRIPT_EVENT_DATA_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT Event
	Event.Details.Type = SCRIPT_EVENT_BUSINESS_VEHICLE_UPDATE_CURRENT_CHECKPOINT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iCheckpointOnRouteTo = iCheckpointOnRouteTo
	PRINTLN("BROADCAST_EVENT_BUSINESS_VEHICLE_UPDATE_CURRENT_CHECKPOINT: iCheckpointOnRouteTo = ", iCheckpointOnRouteTo)
	
	Event.iPed = iPed
	PRINTLN("BROADCAST_EVENT_BUSINESS_VEHICLE_UPDATE_CURRENT_CHECKPOINT: iPed = ", iPed)
	
	Event.iFrameCount = GET_FRAME_COUNT()
	
	INT iPlayersFlag = ALL_PLAYERS_ON_SCRIPT()
	
	IF iPlayersFlag != 0
		NET_PRINT("BROADCAST_EVENT_BUSINESS_VEHICLE_UPDATE_CURRENT_CHECKPOINT - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_EVENT_BUSINESS_VEHICLE_UPDATE_CURRENT_CHECKPOINT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

PROC BROADCAST_EVENT_FMEVENT_VEHICLE_UPDATE_CURRENT_CHECKPOINT(INT iCheckpointOnRouteTo, INT iPed)
	
	SCRIPT_EVENT_DATA_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT Event
	Event.Details.Type = SCRIPT_EVENT_FMEVENT_VEHICLE_UPDATE_CURRENT_CHECKPOINT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iCheckpointOnRouteTo = iCheckpointOnRouteTo
	PRINTLN("BROADCAST_EVENT_FMEVENT_VEHICLE_UPDATE_CURRENT_CHECKPOINT: iCheckpointOnRouteTo = ", iCheckpointOnRouteTo)
	
	Event.iPed = iPed
	PRINTLN("BROADCAST_EVENT_FMEVENT_VEHICLE_UPDATE_CURRENT_CHECKPOINT: iPed = ", iPed)
	
	INT iPlayersFlag = ALL_PLAYERS_ON_SCRIPT()
	
	IF iPlayersFlag != 0
		NET_PRINT("BROADCAST_EVENT_FMEVENT_VEHICLE_UPDATE_CURRENT_CHECKPOINT - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_EVENT_FMEVENT_VEHICLE_UPDATE_CURRENT_CHECKPOINT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

STRUCT SCRIPT_EVENT_CONTROL_AVENGER_AUTOPILOT_STRUCT
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bActivateAutoPilot
ENDSTRUCT

PROC BROADCAST_EVENT_CONTROL_AVENGER_AUTOPILOT(BOOL bActivate)
	
	SCRIPT_EVENT_CONTROL_AVENGER_AUTOPILOT_STRUCT Event
	Event.Details.Type = SCRIPT_EVENT_CONTROL_AVENGER_AUTOPILOT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.bActivateAutoPilot = bActivate
	PRINTLN("BROADCAST_EVENT_CONTROL_AVENGER_AUTOPILOT: iCheckpointOnRouteTo = ", bActivate)
	
	INT iPlayersFlag
	IF NOT IS_PED_IN_ANY_VEHICLE(PLAYER_PED_ID())
		PRINTLN("BROADCAST_EVENT_CONTROL_AVENGER_AUTOPILOT: player not in vehicle")
		EXIT
	ELSE	
		IF !NETWORK_IS_ACTIVITY_SESSION()
			iPlayersFlag = ALL_PLAYERS_IN_VEHICLE(GET_VEHICLE_PED_IS_IN(PLAYER_PED_ID()))
		ELSE
			SET_BIT(iPlayersFlag, NATIVE_TO_INT(PLAYER_ID()))
		ENDIF
	ENDIF	
	
	IF iPlayersFlag != 0
		NET_PRINT("BROADCAST_EVENT_CONTROL_AVENGER_AUTOPILOT - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_EVENT_CONTROL_AVENGER_AUTOPILOT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				 			TELL BOSS TO SAVE VEHCILE COLOURS					║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ══════════════════════════╡  DATA STRUCTURES  ╞═══════════════════════════════
STRUCT SCRIPT_EVENT_DATA_CAR_COLLECTOR_VEHICLE_COLOURS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCol1, iCol2, iColExtra1, iColExtra2, missionVeh
ENDSTRUCT

PROC BROADCAST_CAR_COLLECTOR_VEHICLE_COLOURS(INT iCol1, INT iCol2, INT iColExtra1, INT iColExtra2, VEHICLE_INDEX pedVeh)
	SCRIPT_EVENT_DATA_CAR_COLLECTOR_VEHICLE_COLOURS Event
	Event.Details.Type = SCRIPT_EVENT_CAR_COLLECTOR_VEHICLE_COLOURS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iCol1 = iCol1
	Event.iCol2 = iCol2
	Event.iColExtra1 = iColExtra1
	Event.iColExtra2 = iColExtra2
	Event.missionVeh = NATIVE_TO_INT(pedVeh)
	INT iPlayerFlags			
	INT iPlayer = NATIVE_TO_INT(GB_GET_THIS_PLAYER_GANG_BOSS(PLAYER_ID()))
	SET_BIT(iPlayerFlags, iPlayer)
	
	PRINTLN("[personal_vehicle] BROADCAST_CAR_COLLECTOR_VEHICLE_COLOURS - called with iCol1: ", iCol1, " iCol2: ", iCol2, " iColExtra1: ", iColExtra1, " iColExtra2: ", iColExtra2, " vehicleIndex: ",Event.missionVeh," sending to: ", GET_PLAYER_NAME(GB_GET_THIS_PLAYER_GANG_BOSS(PLAYER_ID())))
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
ENDPROC


// player who processed auto pilot sends event to avenger owner to notify that auto pilot is activated 
STRUCT SCRIPT_EVENT_AVENGER_AUTOPILOT_STRUCT
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bActivatedAutoPilot
ENDSTRUCT

PROC BROADCAST_EVENT_AVENGER_AUTOPILOT_ACTIVATED(PLAYER_INDEX avengerOwner, BOOL bActivated)
	
	SCRIPT_EVENT_AVENGER_AUTOPILOT_STRUCT Event
	Event.Details.Type = SCRIPT_EVENT_AVENGER_AUTOPILOT_ACTIVATED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.bActivatedAutoPilot = bActivated
	PRINTLN("BROADCAST_EVENT_AVENGER_AUTOPILOT_ACTIVATED: bActivated = ", bActivated)
	
	INT iPlayersFlag
	IF !NETWORK_IS_ACTIVITY_SESSION()
		SET_BIT(iPlayersFlag, NATIVE_TO_INT(avengerOwner))	
	ELSE
		iPlayersFlag = ALL_GANG_MEMBERS()
	ENDIF
	
	IF iPlayersFlag != 0
		NET_PRINT("BROADCAST_EVENT_AVENGER_AUTOPILOT_ACTIVATED - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_EVENT_AVENGER_AUTOPILOT_ACTIVATED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_WARP_BUYSELL_SCRIPT_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iVehicleArray
	INT iPosix
	BOOL bFinishedWarp
ENDSTRUCT

PROC BROADCAST_EVENT_WARP_BUYSELL_SCRIPT_VEHICLE(INT iVehicleArray, BOOL bFinishedWarp, INT iPosix)
	
	SCRIPT_EVENT_DATA_WARP_BUYSELL_SCRIPT_VEHICLE Event
	Event.Details.Type = SCRIPT_EVENT_WARP_BUYSELL_SCRIPT_VEHICLE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iVehicleArray = iVehicleArray
	Event.bFinishedWarp = bFinishedWarp
	Event.iPosix = iPosix
	PRINTLN("BROADCAST_EVENT_WARP_BUYSELL_SCRIPT_VEHICLE: iVehicleArray = ", iVehicleArray, " - bFinishedWarp = ", bFinishedWarp, " - iPosix = ", iPosix)

	INT iPlayersFlag = ALL_PLAYERS_ON_SCRIPT()
	
	IF iPlayersFlag != 0
		NET_PRINT("BROADCAST_EVENT_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_EVENT_GUNRUN_VEHICLE_UPDATE_CURRENT_CHECKPOINT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
	
ENDPROC

PROC BROADCAST_START_MOVE_BETWEEN_OFFICE_GARAGE_INTERIOR(INT iInteriorToMove)
												
	SCRIPT_EVENT_DATA_MOVE_BETWEEN_OFFICE_GARAGE Event
	Event.Details.Type = SCRIPT_EVENT_MOVE_BETWEEN_OFFICE_GARAGE_AND_MOD
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_START_MOVE_BETWEEN_OFFICE_GARAGE_INTERIOR: sending from = ", GET_PLAYER_NAME(PLAYER_ID()))
	
	Event.iInteriorToMove = iInteriorToMove
	PRINTLN("BROADCAST_START_MOVE_BETWEEN_OFFICE_GARAGE_INTERIOR: move to = ", iInteriorToMove)
	
	IF iInteriorToMove = 2
//		SCRIPT_ASSERT("BROADCAST_START_MOVE_BETWEEN_OFFICE_GARAGE_INTERIOR: iInteriorToMove = 2: Cleaning up iIsPlayerGoingToModGarageBS")
		CDEBUG1LN(DEBUG_SAFEHOUSE, "BROADCAST_START_MOVE_BETWEEN_OFFICE_GARAGE_INTERIOR: iIsPlayerGoingToModGarageBS = -1")
		CLEAR_BIT(GlobalplayerBD_FM[NATIVE_TO_INT(PLAYER_ID())].iIsPlayerGoingToModGarageBS, biIsPlayerGoingToModGarageTrue)
		CLEAR_BIT(GlobalplayerBD_FM[NATIVE_TO_INT(PLAYER_ID())].iIsPlayerGoingToModGarageBS, biIsPlayerGoingToModGarageFalse)		
		CLEAR_BIT(GlobalplayerBD_FM[NATIVE_TO_INT(PLAYER_ID())].iIsPlayerGoingToModGarageBS, biIsPlayerGoingToModGarageUnset)		
	ENDIF
	IF iInteriorToMove = 1
//		SCRIPT_ASSERT("BROADCAST_START_MOVE_BETWEEN_OFFICE_GARAGE_INTERIOR: iInteriorToMove = 1: Cleaning up iIsPlayerGoingToModGarageBS")
	ENDIF
	INT iPlayersFlag = ALL_PLAYERS_ON_SCRIPT()
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_START_MOVE_BETWEEN_OFFICE_GARAGE_INTERIOR - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_START_MOVE_BETWEEN_OFFICE_GARAGE_INTERIOR - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_START_PRE_SELL_VEHICLE_MOD(PLAYER_INDEX playerVeh1, PLAYER_INDEX playerVeh2, PLAYER_INDEX playerVeh3, PLAYER_INDEX playerVeh4, 
												INT iVehicleID1, INT iVehicleID2, INT iVehicleID3, INT iVehicleID4, VEHICLE_EXPORT_DROPOFF_TYPE eDropoffLocation, BOOL bCollectionMission)
												
	SCRIPT_EVENT_DATA_START_PRE_SELL_VEHICLE_MOD Event
	Event.Details.Type = SCRIPT_EVENT_START_PRE_SELL_VEHICLE_MOD
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_START_PRE_SELL_VEHICLE_MOD: Boss = ", GET_PLAYER_NAME(PLAYER_ID()))
	
	Event.playerModdingVeh[0] = playerVeh1
	PRINTLN("BROADCAST_START_PRE_SELL_VEHICLE_MOD: Player modding vehicle 1 = ", NATIVE_TO_INT(playerVeh1))
	
	Event.playerModdingVeh[1] = playerVeh2
	PRINTLN("BROADCAST_START_PRE_SELL_VEHICLE_MOD: Player modding vehicle 2 = ", NATIVE_TO_INT(playerVeh2))
	
	Event.playerModdingVeh[2] = playerVeh3
	PRINTLN("BROADCAST_START_PRE_SELL_VEHICLE_MOD: Player modding vehicle 3 = ", NATIVE_TO_INT(playerVeh3))
	
	Event.playerModdingVeh[3] = playerVeh4
	PRINTLN("BROADCAST_START_PRE_SELL_VEHICLE_MOD: Player modding vehicle 4 = ", NATIVE_TO_INT(playerVeh4))
	
	Event.iVehiclesToMod[0] = iVehicleID1
	PRINTLN("BROADCAST_START_PRE_SELL_VEHICLE_MOD: iVehicleIndex 1 = ", iVehicleID1)
	
	Event.iVehiclesToMod[1] = iVehicleID2
	PRINTLN("BROADCAST_START_PRE_SELL_VEHICLE_MOD: iVehicleIndex 2 = ", iVehicleID2)
	
	Event.iVehiclesToMod[2] = iVehicleID3
	PRINTLN("BROADCAST_START_PRE_SELL_VEHICLE_MOD: iVehicleIndex 3 = ", iVehicleID3)
	
	Event.iVehiclesToMod[3] = iVehicleID4
	PRINTLN("BROADCAST_START_PRE_SELL_VEHICLE_MOD: iVehicleIndex 4 = ", iVehicleID4)
	
	Event.eDropOffLocation = eDropoffLocation
	PRINTLN("BROADCAST_START_PRE_SELL_VEHICLE_MOD: eDropoffLocation = ", eDropoffLocation)
	
	//Set to true when we are selling a collection of 2 or more specific vehicles
	Event.bCollectionOfVehicles = bCollectionMission
	PRINTLN("BROADCAST_START_PRE_SELL_VEHICLE_MOD: selling a vehicle collection = ", bCollectionMission)
	
	INT iPlayersFlag = ALL_GANG_MEMBERS()
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("BROADCAST_START_PRE_SELL_VEHICLE_MOD - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("BROADCAST_START_PRE_SELL_VEHICLE_MOD - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_STOCKPILING_PACKAGE_COLLECTION
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPackageCollected
ENDSTRUCT

PROC BROADCAST_STOCKPILING_PACKAGE_COLLECTION(INT iPackageCollected, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_STOCKPILING_PACKAGE_COLLECTION Event
	Event.Details.Type = SCRIPT_EVENT_STOCKPILING_PACKAGE_COLLECTION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPackageCollected = iPackageCollected
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_STOCKPILING_PACKAGE_COLLECTION - called by local player. iPackageCollected = ", iPackageCollected)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		PRINTLN("BROADCAST_STOCKPILING_PACKAGE_COLLECTION - iPlayerFlags = 0, not broadcasting")
	ENDIF
ENDPROC
STRUCT SCRIPT_EVENT_DATA_STOCKPILING_PACKAGE_DESTROYED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPackageDestroyed
ENDSTRUCT

PROC BROADCAST_STOCKPILING_PACKAGE_DESTROYED(INT iPackageDestroyed, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_STOCKPILING_PACKAGE_DESTROYED Event
	Event.Details.Type = SCRIPT_EVENT_STOCKPILING_PACKAGE_DESTROYED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPackageDestroyed = iPackageDestroyed
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_STOCKPILING_PACKAGE_DESTROYED - called by local player. iPackageDestroyed = ", iPackageDestroyed)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		PRINTLN("BROADCAST_STOCKPILING_PACKAGE_DESTROYED - iPlayerFlags = 0, not broadcasting")
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_VELOCITY_CHECKPOINT_COLLECTION
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iNumCheckpointsCollected
ENDSTRUCT

PROC BROADCAST_VELOCITY_CHECKPOINT_COLLECTION(INT iPlayerFlags, INT iNumCheckpointsCollected)
	SCRIPT_EVENT_DATA_VELOCITY_CHECKPOINT_COLLECTION Event
	Event.Details.Type = SCRIPT_EVENT_VELOCITY_CHECKPOINT_COLLECTION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iNumCheckpointsCollected = iNumCheckpointsCollected
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_VELOCITY_CHECKPOINT_COLLECTION - called by local player.")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		PRINTLN("BROADCAST_VELOCITY_CHECKPOINT_COLLECTION - iPlayerFlags = 0, not broadcasting")
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_UPDATE_PV_LOCKSTATE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iLockState
	INT iClubhouseOverrideState
ENDSTRUCT

PROC BROADCAST_SET_PERSONAL_VEHICLE_LOCK_STATE(INT iLockState, INT iClubhouseOverrideState)
	SCRIPT_EVENT_DATA_UPDATE_PV_LOCKSTATE Event
	Event.Details.Type = SCRIPT_EVENT_UPDATE_PV_LOCKSTATE
	Event.Details.FromPlayerIndex = PLAYER_ID()	
	Event.iLockState = iLockState
	Event.iClubhouseOverrideState = iClubhouseOverrideState
	
	PRINTLN("[personal_vehicle] BROADCAST_SET_PERSONAL_VEHICLE_LOCK_STATE - called with ", iLockState, ", ", iClubhouseOverrideState )
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
	
ENDPROC



//╔═════════════════════════════════════════════════════════════════════════════╗
//║				 			TELL PLAYERS TO LOCK TRUCK							║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ══════════════════════════╡  DATA STRUCTURES  ╞═══════════════════════════════
STRUCT SCRIPT_EVENT_DATA_UPDATE_TRUCK_LOCKSTATE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iLockState
ENDSTRUCT

PROC BROADCAST_SET_TRUCK_LOCK_STATE(INT iLockState)
	SCRIPT_EVENT_DATA_UPDATE_TRUCK_LOCKSTATE Event
	Event.Details.Type = SCRIPT_EVENT_UPDATE_TRUCK_LOCKSTATE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iLockState = iLockState
	
	PRINTLN("[personal_vehicle] BROADCAST_SET_TRUCK_LOCK_STATE - called with ", iLockState)
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

PROC BROADCAST_SET_AVENGER_LOCK_STATE(INT iLockState)
	SCRIPT_EVENT_DATA_UPDATE_TRUCK_LOCKSTATE Event
	Event.Details.Type = SCRIPT_EVENT_UPDATE_AVENGER_LOCKSTATE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iLockState = iLockState
	
	PRINTLN("[personal_vehicle] BROADCAST_SET_AVENGER_LOCK_STATE - called with ", iLockState)
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

PROC BROADCAST_SET_HACKER_TRUCK_LOCK_STATE(INT iLockState)
	SCRIPT_EVENT_DATA_UPDATE_TRUCK_LOCKSTATE Event
	Event.Details.Type = SCRIPT_EVENT_UPDATE_HACKER_TRUCK_LOCKSTATE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iLockState = iLockState
	
	PRINTLN("[personal_vehicle] BROADCAST_SET_HACKER_TRUCK_LOCK_STATE - called with ", iLockState)
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				 			TELL OWNER TO ASSIGN TRUCK TO MAIN SCRIPT			║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ══════════════════════════╡  DATA STRUCTURES  ╞═══════════════════════════════
//STRUCT SCRIPT_EVENT_DATA_ASSIGN_TRUCK_TO_MAIN_SCRIPT
//	STRUCT_EVENT_COMMON_DETAILS Details
//	BOOL bAssign
//ENDSTRUCT

//PROC BROADCAST_ASSIGN_TRUCK_TO_MAIN_SCRIPT(BOOL bAssign, PLAYER_INDEX sendToOwner)
//	SCRIPT_EVENT_DATA_ASSIGN_TRUCK_TO_MAIN_SCRIPT Event
//	Event.Details.Type = SCRIPT_EVENT_REQUEST_ASSIGN_TRUCK_TO_MAIN_SCRIPT
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.bAssign = bAssign
//	
//	PRINTLN("[personal_vehicle] BROADCAST_ASSIGN_TRUCK_TO_MAIN_SCRIPT - called with ", bAssign)
//	PRINTLN("[personal_vehicle] BROADCAST_ASSIGN_TRUCK_TO_MAIN_SCRIPT - sending to  ", GET_PLAYER_NAME(sendToOwner))
//	
//	IF IS_NET_PLAYER_OK(sendToOwner, FALSE, TRUE)
//		INT iPlayersFlag = 0
//		SET_BIT(iPlayersFlag , NATIVE_TO_INT(sendToOwner))
//		IF NOT (iPlayersFlag = 0)
//			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)
//		ENDIF	
//	ELSE
//		PRINTLN("[personal_vehicle] BROADCAST_ASSIGN_TRUCK_TO_MAIN_SCRIPT - sender  ", GET_PLAYER_NAME(sendToOwner) , " left session!" )
//	ENDIF
//ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				 		Transisition in and out of bunker with truck			║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ══════════════════════════╡  DATA STRUCTURES  ╞═══════════════════════════════
STRUCT SCRIPT_EVENT_DATA_TRANSITION_IN_OUT_BUNKER_WITH_TRUCK
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bDriveOutofBunker
ENDSTRUCT

PROC BROADCAST_TRANSITION_IN_OUT_BUNKER_WITH_TRUCK(BOOL bDriveOutOfBunker)
	SCRIPT_EVENT_DATA_TRANSITION_IN_OUT_BUNKER_WITH_TRUCK Event
	Event.Details.Type = SCRIPT_EVENT_TRANSITION_IN_OUT_BUNKER_WITH_TRUCK
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bDriveOutofBunker = bDriveOutOfBunker
	
	PRINTLN("[personal_vehicle] BROADCAST_TRANSITION_IN_OUT_BUNKER_WITH_TRUCK - called bDriveOutOfBunker:  ", bDriveOutOfBunker)
	
	INT iPlayersFlag = ALL_PLAYERS_IN_VEHICLE(GET_VEHICLE_PED_IS_IN(PLAYER_PED_ID()))
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("[personal_vehicle] BROADCAST_TRANSITION_IN_OUT_BUNKER_WITH_TRUCK - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("[personal_vehicle] BROADCAST_TRANSITION_IN_OUT_BUNKER_WITH_TRUCK - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				 		Transisition in and out of base with avenger			║
//╚═════════════════════════════════════════════════════════════════════════════╝

// ══════════════════════════╡  DATA STRUCTURES  ╞═══════════════════════════════
STRUCT SCRIPT_EVENT_DATA_TRANSITION_IN_OUT_BASE_WITH_AVENGER
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bDriveOutofBase
ENDSTRUCT

PROC BROADCAST_TRANSITION_IN_OUT_BASE_WITH_AVENGER(BOOL bDriveOutofBase)
	SCRIPT_EVENT_DATA_TRANSITION_IN_OUT_BASE_WITH_AVENGER Event
	Event.Details.Type = SCRIPT_EVENT_TRANSITION_IN_OUT_BASE_WITH_AVENGER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bDriveOutofBase = bDriveOutofBase
	
	PRINTLN("[personal_vehicle] BROADCAST_TRANSITION_IN_OUT_BASE_WITH_AVENGER - called bDriveOutofBase:  ", bDriveOutofBase)
	
	INT iPlayersFlag = ALL_PLAYERS_IN_VEHICLE(GET_VEHICLE_PED_IS_IN(PLAYER_PED_ID()))
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("[personal_vehicle] BROADCAST_TRANSITION_IN_OUT_BASE_WITH_AVENGER - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("[personal_vehicle] BROADCAST_TRANSITION_IN_OUT_BASE_WITH_AVENGER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║				 		GUNRUNNING FREEMODE DELIVERY EVENTS												
//╚═════════════════════════════════════════════════════════════════════════════╝
// ══════════════════════════╡  DATA STRUCTURES  ╞═══════════════════════════════
STRUCT SCRIPT_EVENT_DATA_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID
	STRUCT_EVENT_COMMON_DETAILS Details
	FREEMODE_DELIVERABLE_ID deliverableID
	FREEMODE_DELIVERABLE_TYPE eType
	FREEMODE_DELIVERY_DROPOFFS eDropoff
	FM_DELIVERY_MISSION_ID sMissionID
	INT iQuantity
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FREEMODE_DELIVERY_CLEANUP_DELIVERABLE_ID
	STRUCT_EVENT_COMMON_DETAILS Details
	FREEMODE_DELIVERABLE_ID deliverableID
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FREEMODE_DELIVERY_REQUEST_DROPOFF_ACTIVATION
	STRUCT_EVENT_COMMON_DETAILS Details
	FREEMODE_DELIVERY_DROPOFFS eDropoffID
	FM_DELIVERY_MISSION_ID sMissionID
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_FREEMODE_DELIVERY_REQUEST_DROPOFF_MISSION_ID_ASSIGNMENT
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX pOwner
	FM_DELIVERY_MISSION_ID sMissionID
	FREEMODE_DELIVERY_DROPOFFS eDropoffs[FREEMODE_DELIVERY_MAX_ACTIVE_DROPOFFS]
	INT iDropoffCount = 0
ENDSTRUCT

FUNC BOOL FREEMODE_DELIVERY_IS_MISSION_ID_VALID(FM_DELIVERY_MISSION_ID sMissionID)
	IF sMissionID.iScriptHash 		= -1
	OR sMissionID.iScriptInstance 	= FM_DELIVERY_INVALID
		RETURN FALSE
	ENDIF
	
	RETURN TRUE
ENDFUNC

FUNC BOOL FREEMODE_DELIVERY_ARE_DELIVERABLES_EQUAL(FREEMODE_DELIVERABLE_ID deliverableA, FREEMODE_DELIVERABLE_ID deliverableB)
	IF deliverableA.iIndex != -1
	AND deliverableB.iIndex != -1
		RETURN (deliverableA.pOwner = deliverableB.pOwner) AND (deliverableA.iIndex = deliverableB.iIndex)
	ENDIF
	
	RETURN FALSE
ENDFUNC

/// PURPOSE:
///    Returns the sserver array index for the given deliverable. -1 if the deliverable doesn't exist on the server
///    Always check the value returned is not -1!
FUNC INT GET_DELIVERABLE_SERVER_INDEX(FREEMODE_DELIVERABLE_ID deliverableID)
	INT i
	
	REPEAT FREEMODE_DELIVERY_GLOBAL_SERVER_BD_DELIVERABLE_POOL_SIZE i		
		IF FREEMODE_DELIVERY_ARE_DELIVERABLES_EQUAL(deliverableID, GlobalServerBD_BlockB.freemodeDelivery.deliverablePool[i].deliverableID)
			RETURN i
		ENDIF
	ENDREPEAT
	
	RETURN -1
ENDFUNC

FUNC FM_DELIVERY_MISSION_ID FREEMODE_DELIVERY_GET_DELIVERABLE_MISSION_ID(FREEMODE_DELIVERABLE_ID deliverableID)
	
	INT iServerDeliverableIndex = GET_DELIVERABLE_SERVER_INDEX(deliverableID)
	
	IF iServerDeliverableIndex < 0
	OR iServerDeliverableIndex >= FREEMODE_DELIVERY_GLOBAL_SERVER_BD_DELIVERABLE_POOL_SIZE
		SCRIPT_ASSERT("FREEMODE_DELIVERY_GET_DELIVERABLE_MISSION_ID - Invalid server ID")
		FM_DELIVERY_MISSION_ID sDummy
		RETURN sDummy
	ENDIF

	RETURN GlobalServerBD_BlockB.freemodeDelivery.deliverablePool[iServerDeliverableIndex].sMissionID
ENDFUNC

FUNC BOOL FREEMODE_DELIVERY_DO_MISSION_IDS_MATCH(FM_DELIVERY_MISSION_ID sMissionIDOne, FM_DELIVERY_MISSION_ID sMissionIDTwo)
	
	IF NOT FREEMODE_DELIVERY_IS_MISSION_ID_VALID(sMissionIDOne)
		RETURN FALSE
	ENDIF
	
	IF sMissionIDOne.iScriptHash 		= sMissionIDTwo.iScriptHash
	AND sMissionIDOne.iScriptInstance 	= sMissionIDTwo.iScriptInstance
		RETURN TRUE
	ENDIF
	
	RETURN FALSE
ENDFUNC

DEBUGONLY FUNC FM_DELIVERY_MISSION_ID _GET_DEBUG_MISSION_ID()
	FM_DELIVERY_MISSION_ID sReturn
	sReturn.iScriptHash = HASH("Debug")
	sReturn.iScriptInstance = 1
	
	RETURN sReturn
ENDFUNC

FUNC BOOL FREEMODE_DELIVERY_IS_DELIVERABLE_VALID(FREEMODE_DELIVERABLE_ID deliverableID)
	RETURN deliverableID.iIndex != -1 AND deliverableID.pOwner != INVALID_PLAYER_INDEX()
ENDFUNC

// ════════════════════════╡  BROADCAST PROCEDURES  ╞════════════════════════════

PROC BROADCAST_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID(FREEMODE_DELIVERABLE_ID deliverableID, FREEMODE_DELIVERABLE_TYPE eType, INT iQuantity, FM_DELIVERY_MISSION_ID sMissionID, FREEMODE_DELIVERY_DROPOFFS eDropoff = FREEMODE_DELIVERY_DROPOFF_INVALID)
	
	IF NOT FREEMODE_DELIVERY_IS_MISSION_ID_VALID(sMissionID)
		SCRIPT_ASSERT("BROADCAST_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID - Invalid mission ID")
		PRINTLN("BROADCAST_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID - Invalid mission ID")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID Event
	Event.Details.Type = SCRIPT_EVENT_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID: FromPlayerIndex = ", GET_PLAYER_NAME(PLAYER_ID()))
	
	Event.deliverableID = deliverableID
	//FREEMODE_DELIVERY_DEBUG_PRINT_DELIVERABLE_ID(deliverableID, "BROADCAST_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID")
	
	Event.eType = eType
	PRINTLN("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID: eType = ", ENUM_TO_INT(eType))
	
	Event.iQuantity = iQuantity
	PRINTLN("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID: iQuantity = ", iQuantity)
	
	Event.eDropoff = eDropoff
	PRINTLN("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID: eDropoff = ", eDropoff)
	
	Event.sMissionID = sMissionID
	PRINTLN("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID: Mission ID: ", sMissionID.iScriptHash, ":", sMissionID.iScriptInstance)
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_REQUEST_DELIVERABLE_ID - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_FREEMODE_DELIVERY_CLEANUP_DELIVERABLE_ID(FREEMODE_DELIVERABLE_ID deliverableID)
	SCRIPT_EVENT_DATA_FREEMODE_DELIVERY_CLEANUP_DELIVERABLE_ID Event
	Event.Details.Type = SCRIPT_EVENT_FREEMODE_DELIVERY_CLEANUP_DELIVERABLE_ID
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_CLEANUP_DELIVERABLE_ID: FromPlayerIndex = ", GET_PLAYER_NAME(PLAYER_ID()))
	
	Event.deliverableID = deliverableID
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_CLEANUP_DELIVERABLE_ID - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_CLEANUP_DELIVERABLE_ID - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_FREEMODE_DELIVERY_REQUEST_DROPOFF_ACTIVATION(FREEMODE_DELIVERY_DROPOFFS eDropoffID, FM_DELIVERY_MISSION_ID sMissionID)
	SCRIPT_EVENT_DATA_FREEMODE_DELIVERY_REQUEST_DROPOFF_ACTIVATION Event
	Event.Details.Type = SCRIPT_EVENT_FREEMODE_DELIVERY_REQUEST_DROPOFF_ACTIVATION
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.eDropoffID = eDropoffID
	Event.sMissionID = sMissionID
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_REQUEST_DROPOFF_ACTIVATION - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_REQUEST_DROPOFF_ACTIVATION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_FREEMODE_DELIVERY_REQUEST_DROPOFF_MISSION_ID_ASSIGNMENT(PLAYER_INDEX pOwner, FM_DELIVERY_MISSION_ID sMissionID, FREEMODE_DELIVERY_DROPOFFS &eDropoffs[])
	
	IF NOT FREEMODE_DELIVERY_IS_MISSION_ID_VALID(sMissionID)
		SCRIPT_ASSERT("BROADCAST_FREEMODE_DELIVERY_REQUEST_DROPOFF_MISSION_ID_ASSIGNMENT - Invalid mission ID")
		PRINTLN("BROADCAST_FREEMODE_DELIVERY_REQUEST_DROPOFF_MISSION_ID_ASSIGNMENT - Invalid mission ID")
		EXIT
	ENDIF
	
	IF COUNT_OF(eDropoffs) > FREEMODE_DELIVERY_MAX_ACTIVE_DROPOFFS
		SCRIPT_ASSERT("BROADCAST_FREEMODE_DELIVERY_REQUEST_DROPOFF_MISSION_ID_ASSIGNMENT - trying to link more dropoffs than MAX_ACTIVE_DROPOFFS")
		PRINTLN("BROADCAST_FREEMODE_DELIVERY_REQUEST_DROPOFF_MISSION_ID_ASSIGNMENT - trying to link more dropoffs than MAX_ACTIVE_DROPOFFS")
		EXIT
	ENDIF
	
	IF COUNT_OF(eDropoffs) <= 0
		SCRIPT_ASSERT("BROADCAST_FREEMODE_DELIVERY_REQUEST_DROPOFF_MISSION_ID_ASSIGNMENT - trying to link 0 dropoffs")
		PRINTLN("BROADCAST_FREEMODE_DELIVERY_REQUEST_DROPOFF_MISSION_ID_ASSIGNMENT - trying to link 0 dropoffs")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_FREEMODE_DELIVERY_REQUEST_DROPOFF_MISSION_ID_ASSIGNMENT Event
	Event.Details.Type = SCRIPT_EVENT_FREEMODE_DELIVERY_REQUEST_DROPOFF_MISSION_ID_ASSIGNMENT
	
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.pOwner 					= pOwner
	Event.sMissionID 				= sMissionID
	Event.iDropoffCount				= COUNT_OF(eDropoffs)
	
	INT i
	
	REPEAT COUNT_OF(eDropoffs) i
		Event.eDropoffs[i] = eDropoffs[i]
	ENDREPEAT
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_REQUEST_DROPOFF_MISSION_ID_ASSIGNMENT - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("[FREEMODE_DELIVERY] BROADCAST_FREEMODE_DELIVERY_REQUEST_DROPOFF_MISSION_ID_ASSIGNMENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

#IF IS_DEBUG_BUILD
FUNC STRING DEBUG_GET_FM_DELIVERY_PEA_STRING(FM_DELIVERY_EVENT_POST_EVENT_ACTION eAction)
	SWITCH eAction
		CASE FM_DELIVERY_ACTION_DEFAULT								RETURN "FM_DELIVERY_ACTION_DEFAULT"								BREAK
		CASE FM_DELIVERY_ACTION_WARP_INTO_PROPERTY_NO_SCENE	RETURN "FM_DELIVERY_ACTION_WARP_INTO_PROPERTY_NO_SCENE"	BREAK
	ENDSWITCH
	
	RETURN "***Invalid***"
ENDFUNC
#ENDIF

/// PURPOSE:
///    Informs gang members that the local player has taken a deliverable to a dropoff
/// PARAMS:
///    eDeliverable - The deliverable delivered by the local player
///    iQuantityRemaining - Count of drops this deliverable still has to make
PROC BROADCAST_FREEMODE_DELIVERABLE_DELIVERY(FREEMODE_DELIVERABLE_ID eDeliverable, INT iQuantityRemaining, FREEMODE_DELIVERY_DROPOFFS eDropoffDeliveredTo, FREEMODE_DELIVERABLE_TYPE etype, FM_DELIVERY_EVENT_POST_EVENT_ACTION ePostEventAct, BOOL bStolen = FALSE , BOOL bSendToAllPlayers = FALSE)
	SCRIPT_EVENT_DATA_FM_DELIVERABLE_DELIVERY Event
	Event.Details.Type = SCRIPT_EVENT_FM_DELIVERABLE_DELIVERY
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY: player doing delivery = ", GET_PLAYER_NAME(PLAYER_ID()), " (", NATIVE_TO_INT(PLAYER_ID()), ")")
	Event.eDeliverable = eDeliverable
	PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY: deliverable ID = ", Event.eDeliverable.iIndex)
	PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY: deliverable owner = ", GET_PLAYER_NAME(Event.eDeliverable.pOwner), " (", NATIVE_TO_INT(Event.eDeliverable.pOwner), ")")
	Event.iQuantityRemaining = iQuantityRemaining
	PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY: deliverable quantity remaining = ", iQuantityRemaining)
	Event.eDropoffDeliverdTo = eDropoffDeliveredTo
	PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY: deliverable delivered to dropoff = ", eDropoffDeliveredTo)
	Event.eType = etype
	PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY: deliverable type = ", etype)
	Event.bStolen = bStolen
	PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY: Was it stolen? ", bStolen)
	Event.ePostEventAct = ePostEventAct
	PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY: ePostEventAct: ", DEBUG_GET_FM_DELIVERY_PEA_STRING(ePostEventAct))
	IF bStolen
		Event.iRivalVariation = MPGlobalsAmbience.sRivalBusinessDelivery.iRivalBusinessVariation
		Event.iRivalFMMCType = MPGlobalsAmbience.sRivalBusinessDelivery.iRivalBusinessType
		PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY: Rival FMMC type = ", Event.iRivalFMMCType)
		#IF IS_DEBUG_BUILD
		IF MPGlobalsAmbience.sRivalBusinessDelivery.iRivalBusinessType = FMMC_TYPE_VEHICLE_LIST_EVENT
			PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY: Vehicle Model = ", GET_MODEL_NAME_FOR_DEBUG(INT_TO_ENUM(MODEL_NAMES, Event.iRivalVariation)))
		ELSE
			PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY: Rival variation = ", Event.iRivalVariation)
		ENDIF
		#ENDIF
	ENDIF
	
	INT iPlayersBS = 0
	
		IF bSendToAllPlayers
			iPlayersBS = ALL_PLAYERS()
			PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY - Sending to all players")
		ENDIF
	
	IF iPlayersBS = 0
		IF GB_ARE_PLAYERS_IN_SAME_GANG(PLAYER_ID(), Event.eDeliverable.pOwner)
			iPlayersBS = ALL_GANG_MEMBERS(FALSE)
			PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY - called by local player in gang, sending to gang members")
		ELSE
			IF bStolen
				IF GB_GET_LOCAL_PLAYER_GANG_BOSS() != INVALID_PLAYER_INDEX()
					iPlayersBS = ALL_GANG_MEMBERS(FALSE)
					PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY - called by local player rival, sending to all gang members")
				ENDIF
				
				IF IS_NET_PLAYER_OK(Event.eDeliverable.pOwner, FALSE)
					SET_BIT(iPlayersBS, NATIVE_TO_INT(Event.eDeliverable.pOwner))
					PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY - called by local player rival, sending to boss owner")
				ELSE
					PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY - called by local player rival, but boss is not okay. only sending to local player.")
				ENDIF
			ELSE
				IF IS_NET_PLAYER_OK(Event.eDeliverable.pOwner, FALSE)
					iPlayersBS = SPECIFIC_PLAYER(Event.eDeliverable.pOwner)				
					PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY - called by local player rival, sending to boss owner")
				ELSE
					PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY - called by local player rival, but boss is not okay. only sending to local player.")
				ENDIF
				
				IF GB_GET_LOCAL_PLAYER_GANG_BOSS() != INVALID_PLAYER_INDEX()
					SET_BIT(iPlayersBS, NATIVE_TO_INT(GB_GET_LOCAL_PLAYER_GANG_BOSS()))
				ENDIF
			ENDIF
			
			SET_BIT(iPlayersBS, NATIVE_TO_INT(PLAYER_ID()))
		ENDIF
	ENDIF
	
	IF NOT (iPlayersBS = 0)
		PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY - called by local player")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersBS)	
	ELSE
		PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

/// PURPOSE:
///    For new deliverable functionality allowing the player to hold multiple deliverable items
///    Informs gang members that the local player has taken up to FREEMODE_DELIVERY_MAX_HELD_DELIVERABLES deliverable to a dropoff
/// PARAMS:
///    eDeliverable - The deliverable delivered by the local player
///    iQuantityRemaining - Count of drops this deliverable still has to make
PROC BROADCAST_FREEMODE_MULTIPLE_DELIVERABLE_DELIVERY(FREEMODE_DELIVERABLE_ID &eDeliverable[FREEMODE_DELIVERY_MAX_HELD_DELIVERABLES], INT &iQuantityRemaining[FREEMODE_DELIVERY_MAX_HELD_DELIVERABLES], FREEMODE_DELIVERY_DROPOFFS eDropoffDeliveredTo, FREEMODE_DELIVERABLE_TYPE &etype[FREEMODE_DELIVERY_MAX_HELD_DELIVERABLES], FM_DELIVERY_MISSION_ID sMissionID, FM_DELIVERY_EVENT_POST_EVENT_ACTION ePostEventAct, BOOL bSendToAllPlayers = FALSE )
	SCRIPT_EVENT_DATA_FM_MUTLTIPLE_DELIVERABLE_DELIVERY Event
	Event.Details.Type = SCRIPT_EVENT_FM_MULTIPLE_DELIVERABLE_DELIVERY
	
	INT i
	
	Event.Details.FromPlayerIndex = PLAYER_ID()
	PRINTLN("BROADCAST_FREEMODE_MULTIPLE_DELIVERABLE_DELIVERY: player doing delivery = ", GET_PLAYER_NAME(PLAYER_ID()), " (", NATIVE_TO_INT(PLAYER_ID()), ")")
	Event.ePostEventAct = ePostEventAct
	PRINTLN("BROADCAST_FREEMODE_MULTIPLE_DELIVERABLE_DELIVERY ePostEventAct = ", DEBUG_GET_FM_DELIVERY_PEA_STRING(ePostEventAct))
	
	#IF IS_DEBUG_BUILD
	FM_DELIVERY_MISSION_ID sDebugMissionID = _GET_DEBUG_MISSION_ID()
	#ENDIF
		
	REPEAT FREEMODE_DELIVERY_MAX_HELD_DELIVERABLES i
		#IF IS_DEBUG_BUILD
		IF FREEMODE_DELIVERY_DO_MISSION_IDS_MATCH(sMissionID, sDebugMissionID)
			IF FREEMODE_DELIVERY_IS_DELIVERABLE_VALID(eDeliverable[i])
				Event.eDeliverable[i] = eDeliverable[i]
				Event.iQuantityRemaining[i] = iQuantityRemaining[i]
				Event.eType[i] = etype[i]
				PRINTLN("BROADCAST_FREEMODE_MULTIPLE_DELIVERABLE_DELIVERY: debug deliverable ", i, " ID = ", Event.eDeliverable[i].iIndex, " added")
				RELOOP
			ENDIF
		ENDIF
		#ENDIF
		
		IF FREEMODE_DELIVERY_IS_DELIVERABLE_VALID(eDeliverable[i])
			FM_DELIVERY_MISSION_ID sDeliverableMissionID = FREEMODE_DELIVERY_GET_DELIVERABLE_MISSION_ID(eDeliverable[i])
			
			IF FREEMODE_DELIVERY_DO_MISSION_IDS_MATCH(sDeliverableMissionID, sMissionID)			
				Event.eDeliverable[i] = eDeliverable[i]
				PRINTLN("BROADCAST_FREEMODE_MULTIPLE_DELIVERABLE_DELIVERY: deliverable ", i, " ID = ", Event.eDeliverable[i].iIndex)
				
				Event.iQuantityRemaining[i] = iQuantityRemaining[i]
				PRINTLN("BROADCAST_FREEMODE_MULTIPLE_DELIVERABLE_DELIVERY: deliverable ", i, " quantity remaining = ", iQuantityRemaining[i])
				
				Event.eType[i] = etype[i]
				PRINTLN("BROADCAST_FREEMODE_DELIVERABLE_DELIVERY: deliverable ", i, " type = ", etype[i])
			ELSE
				PRINTLN("BROADCAST_FREEMODE_MULTIPLE_DELIVERABLE_DELIVERY: exclude deliverable ", i, " ID = ", Event.eDeliverable[i].iIndex, " Dropoff mission ID: ", sMissionID.iScriptHash, ":", sMissionID.iScriptInstance, " deliverable mission ID: ", sDeliverableMissionID.iScriptHash, ":", sDeliverableMissionID.iScriptInstance)
			ENDIF
		ELSE
			PRINTLN("BROADCAST_FREEMODE_MULTIPLE_DELIVERABLE_DELIVERY: exclude invalid deliverable at player array index ", i)
		ENDIF
	ENDREPEAT
	
	PRINTLN("BROADCAST_FREEMODE_MULTIPLE_DELIVERABLE_DELIVERY: deliverable owner = ", GET_PLAYER_NAME(Event.eDeliverable[0].pOwner), " (", NATIVE_TO_INT(Event.eDeliverable[0].pOwner), ")")
	Event.eDropoffDeliverdTo = eDropoffDeliveredTo
	PRINTLN("BROADCAST_FREEMODE_MULTIPLE_DELIVERABLE_DELIVERY: deliverable delivered to dropoff = ", eDropoffDeliveredTo)
	
	INT iPlayersBS = ALL_GANG_MEMBERS()
	
	//If we're not in a gang then this is likley coming from a debug widget so send it to the local player
	IF NOT GB_IS_LOCAL_PLAYER_MEMBER_OF_A_GANG()
		iPlayersBS = 0
		SET_BIT(iPlayersBS, NATIVE_TO_INT(PLAYER_ID()))
	ENDIF
	
		IF bSendToAllPlayers
			iPlayersBS = ALL_PLAYERS()
			PRINTLN("BROADCAST_FREEMODE_MULTIPLE_DELIVERABLE_DELIVERY - Sending to all players")
		ENDIF
	
	IF NOT (iPlayersBS = 0)
		PRINTLN("BROADCAST_FREEMODE_MULTIPLE_DELIVERABLE_DELIVERY - called by local player, sending to everyone")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersBS)	
	ELSE
		PRINTLN("BROADCAST_FREEMODE_MULTIPLE_DELIVERABLE_DELIVERY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

#IF IS_DEBUG_BUILD
STRUCT SCRIPT_EVENT_DATA_DEBUG_REQUEST_MISSION_LAUNCH_WITH_DROPOFF
	STRUCT_EVENT_COMMON_DETAILS Details
	FREEMODE_DELIVERY_DROPOFFS eDbgSelectedDropoffs[3]
	FREEMODE_DELIVERY_ROUTES eDbgSelectedRoute
ENDSTRUCT

PROC DEBUG_BROADCAST_REQUEST_MISSION_LAUNCH_WITH_DROPOFF(FREEMODE_DELIVERY_DROPOFFS &eSelectedDropoffs[3], FREEMODE_DELIVERY_ROUTES eSelectedRoute)
	INT i
	PLAYER_INDEX pFreemodeHost = NETWORK_GET_HOST_OF_SCRIPT(FREEMODE_SCRIPT())
	SCRIPT_EVENT_DATA_DEBUG_REQUEST_MISSION_LAUNCH_WITH_DROPOFF Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_REQUEST_MISSION_LAUNCH_WITH_DROPOFF
	
	Event.Details.FromPlayerIndex = PLAYER_ID()	
	
	REPEAT 3 i
		Event.eDbgSelectedDropoffs[i] = eSelectedDropoffs[i]
		PRINTLN("[FREEMODE_DELIVERY] DEBUG_BROADCAST_REQUEST_MISSION_LAUNCH_WITH_DROPOFF: Request: ", (i+1), " dropoff = ", eSelectedDropoffs[i])
	ENDREPEAT
	
	Event.eDbgSelectedRoute = eSelectedRoute
	PRINTLN("[FREEMODE_DELIVERY] DEBUG_BROADCAST_REQUEST_MISSION_LAUNCH_WITH_DROPOFF: Requested route: ", eSelectedRoute)
	
	IF NOT GB_IS_PLAYER_BOSS_OF_A_GANG(PLAYER_ID())
		g_FreemodeDeliveryData.iDbgShowSelectDropoffFailOnScreen = FREEMODE_DELIVERY_DEBUG_HELP_NOT_BOSS
		PRINTLN("[FREEMODE_DELIVERY] DEBUG_BROADCAST_REQUEST_MISSION_LAUNCH_WITH_DROPOFF: not able to launch for the local player as they are not a boss")
		EXIT
	ELIF GlobalplayerBD_FM[NATIVE_TO_INT(PLAYER_ID())].propertyDetails.bdFactoryData[BUNKER_SAVE_SLOT].eFactoryID = FACTORY_ID_INVALID
	AND eSelectedDropoffs[0] < SMUGGLER_DROPOFF_LSIA_HANGAR_1
	AND eSelectedRoute < FREEMODE_DELIVERY_FLYING_FORTRESS_1
		PRINTLN("[FREEMODE_DELIVERY] DEBUG_BROADCAST_REQUEST_MISSION_LAUNCH_WITH_DROPOFF: not able to launch for the local player as they do not own a bunker")
		g_FreemodeDeliveryData.iDbgShowSelectDropoffFailOnScreen = FREEMODE_DELIVERY_DEBUG_HELP_NO_BUNKER
		EXIT
	ELIF GlobalplayerBD_FM[NATIVE_TO_INT(PLAYER_ID())].propertyDetails.bdHangarData.eHangar = HANGAR_ID_INVALID
	AND (eSelectedDropoffs[0] >= SMUGGLER_DROPOFF_LSIA_HANGAR_1 OR eSelectedDropoffs[0] = FREEMODE_DELIVERY_DROPOFF_INVALID)
	AND (eSelectedRoute >= FREEMODE_DELIVERY_FLYING_FORTRESS_1 OR eSelectedRoute = FREEMODE_DELIVERY_ROUTE_NO_ROUTE)
		PRINTLN("[FREEMODE_DELIVERY] DEBUG_BROADCAST_REQUEST_MISSION_LAUNCH_WITH_DROPOFF: not able to launch for the local player as they do not own a hangar")
		g_FreemodeDeliveryData.iDbgShowSelectDropoffFailOnScreen = FREEMODE_DELIVERY_DEBUG_HELP_NO_HANGAR
		EXIT
	ELIF GB_IS_PLAYER_ON_ANY_GANG_BOSS_MISSION(PLAYER_ID(), TRUE)
		PRINTLN("[FREEMODE_DELIVERY] DEBUG_BROADCAST_REQUEST_MISSION_LAUNCH_WITH_DROPOFF: not able to launch for the local player as they are on a mission already")
		g_FreemodeDeliveryData.iDbgShowSelectDropoffFailOnScreen = FREEMODE_DELIVERY_DEBUG_HELP_ON_MISSION
		EXIT
	ENDIF
	
	INT iPlayersFlag = ALL_PLAYERS()
	
	IF NOT (iPlayersFlag = 0)
		PRINTLN("[FREEMODE_DELIVERY] DEBUG_BROADCAST_REQUEST_MISSION_LAUNCH_WITH_DROPOFF - called by local player. Current freemode host = ", GET_PLAYER_NAME(pFreemodeHost))	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)
	ELSE
		PRINTLN("[FREEMODE_DELIVERY] DEBUG_BROADCAST_REQUEST_MISSION_LAUNCH_WITH_DROPOFF - playerflags = 0 so not broadcasting")	
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_REPLY_TO_MISSION_LAUNCH_WITH_DROPOFF_REQUEST
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bSuccess
	GUNRUN_VARIATION eMissionVar
	SMUGGLER_VARIATION eSmugglerMissionVar
ENDSTRUCT

PROC DEBUG_BROADCAST_REPLY_TO_MISSION_LAUNCH_WITH_DROPOFF(PLAYER_INDEX piRespondToPlayer, BOOL bSuccessful, GUNRUN_VARIATION eMissionVar = GRV_INVALID, SMUGGLER_VARIATION eSmugglerMissionVar = SMV_INVALID)
	SCRIPT_EVENT_DATA_DEBUG_REPLY_TO_MISSION_LAUNCH_WITH_DROPOFF_REQUEST Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_REPLY_TO_MISSION_LAUNCH_WITH_DROPOFF_REQUEST
	
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bSuccess 					= bSuccessful	
	Event.eMissionVar 				= eMissionVar
	Event.eSmugglerMissionVar 		= eSmugglerMissionVar
	
	INT iPlayersFlag = 0
	
	SET_BIT(iPlayersFlag, NATIVE_TO_INT(piRespondToPlayer))
	PRINTLN("[FREEMODE_DELIVERY] DEBUG_BROADCAST_REPLY_TO_MISSION_LAUNCH_WITH_DROPOFF: Requested by ", GET_PLAYER_NAME(piRespondToPlayer), " Successful? ", bSuccessful, " mission variation: ", eMissionVar)
	
	IF NOT (iPlayersFlag = 0)
		NET_PRINT("[FREEMODE_DELIVERY] DEBUG_BROADCAST_REPLY_TO_MISSION_LAUNCH_WITH_DROPOFF - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		NET_PRINT("[FREEMODE_DELIVERY] DEBUG_BROADCAST_REPLY_TO_MISSION_LAUNCH_WITH_DROPOFF - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC
#ENDIF

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							BROADCAST DRIVER ENTER SIMP INT WITH VEH													
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_ENTER_SIMPL_INT_WITH_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bEntered
	BOOL bAvenvger
ENDSTRUCT

PROC BROADCAST_OWNER_ENTER_SIMPL_INT_WITH_VEHICLE(BOOL bEntered, BOOL bAvenger = FALSE)
	IF IS_PED_IN_ANY_VEHICLE(PLAYER_PED_ID())
		
		SCRIPT_EVENT_DATA_ENTER_SIMPL_INT_WITH_VEHICLE Event
		
		Event.Details.Type = SCRIPT_EVENT_DRIVER_ENTERED_SIMPL_INT
		Event.Details.FromPlayerIndex = PLAYER_ID()
		Event.bEntered = bEntered
		Event.bAvenvger = bAvenger
		PRINTLN("BROADCAST_OWNER_ENTER_SIMPL_INT_WITH_VEHICLE: bEntered = ", bEntered, " is this avenger: ", bAvenger)

		INT iPlayersFlag = ALL_PLAYERS_IN_VEHICLE(GET_VEHICLE_PED_IS_IN(PLAYER_PED_ID()), FALSE, FALSE, TRUE)
		
		IF NOT (iPlayersFlag = 0)
			NET_PRINT("BROADCAST_OWNER_ENTER_SIMPL_INT_WITH_VEHICLE - called by local player" ) NET_NL()	
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
		ELSE
			NET_PRINT("BROADCAST_OWNER_ENTER_SIMPL_INT_WITH_VEHICLE - playerflags = 0 so not broadcasting") NET_NL()		
		ENDIF
	ELSE
		NET_PRINT("BROADCAST_OWNER_ENTER_SIMPL_INT_WITH_VEHICLE - IS_PED_IN_ANY_VEHICLE FALSE") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_BOSS_SHOULD_LAUNCH_THIS_WVM
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iWVMToLaunch
ENDSTRUCT

PROC BROADCAST_BOSS_SHOULD_LAUNCH_THIS_WVM(INT iWVMToLaunch)
	IF GB_IS_LOCAL_PLAYER_MEMBER_OF_A_GANG(FALSE)
		
		SCRIPT_EVENT_DATA_BOSS_SHOULD_LAUNCH_THIS_WVM Event
		
		Event.Details.Type = SCRIPT_EVENT_BOSS_SHOULD_LAUNCH_WVM
		Event.Details.FromPlayerIndex = PLAYER_ID()
		Event.iWVMToLaunch = iWVMToLaunch
		
		INT iPlayersFlag = 0
		
		SET_BIT(iPlayersFlag, NATIVE_TO_INT(GB_GET_LOCAL_PLAYER_GANG_BOSS()))
		
		IF NOT (iPlayersFlag = 0)
			PRINTLN("BROADCAST_BOSS_SHOULD_LAUNCH_THIS_WVM - called by local player; iWVMToLaunch = ", iWVMToLaunch)
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)
		ELSE
			PRINTLN("BROADCAST_BOSS_SHOULD_LAUNCH_THIS_WVM - playerflags = 0 so not broadcasting")
		ENDIF
	ELSE
		PRINTLN("BROADCAST_BOSS_SHOULD_LAUNCH_THIS_WVM - GB_IS_LOCAL_PLAYER_MEMBER_OF_A_GANG(FALSE) - FALSE")
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							BROADCAST PROPERTY DETAILS EVENT													
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_PROPERTY_DETAILS_ON_JOINING
	STRUCT_EVENT_COMMON_DETAILS Details
	GAMER_HANDLE aGamerHandle
	INT iPackedInt
ENDSTRUCT

PROC BROADCAST_PROPERTY_DETAILS_ON_JOINING(INT iPlayerFlags,GAMER_HANDLE &aGamerHandle, INT iPackedInt)
	SCRIPT_EVENT_DATA_PROPERTY_DETAILS_ON_JOINING Event
	Event.Details.Type = SCRIPT_EVENT_PROPERTY_DETAILS_ON_JOINING
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.aGamerHandle = aGamerHandle
	Event.iPackedInt = iPackedInt
	PRINTLN("BROADCAST_PROPERTY_DETAILS_ON_JOINING: iPackedInt = ", iPackedInt)
	PRINTLN("BROADCAST_PROPERTY_DETAILS_ON_JOINING: GamerHandle = ")
	#IF IS_DEBUG_BUILD
	NET_TRANSITION_SESSION_DEBUG_PRINT_HANDLE(aGamerHandle)
	#ENDIF
	IF NOT (iPlayerFlags = 0)
		NET_PRINT("BROADCAST_PROPERTY_DETAILS_ON_JOINING - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PROPERTY_DETAILS_ON_JOINING - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

/// PURPOSE: Triggers a transition event with info about current property
PROC SEND_TRANSITION_CURRENT_PROPERTY_DETAILS(GAMER_HANDLE &aGamerHandle,  INT iPackedInt)
	PRINTLN("SEND_TRANSITION_CURRENT_PROPERTY_DETAILS: iPackedInt = ", iPackedInt)
	PRINTLN("SEND_TRANSITION_CURRENT_PROPERTY_DETAILS: GamerHandle = ")
	#IF IS_DEBUG_BUILD
	NET_TRANSITION_SESSION_DEBUG_PRINT_HANDLE(aGamerHandle)
	#ENDIF
	IF NETWORK_IS_ACTIVITY_SESSION()
		BROADCAST_PROPERTY_DETAILS_ON_JOINING(SPECIFIC_PLAYER(NETWORK_GET_PLAYER_FROM_GAMER_HANDLE(aGamerHandle)),aGamerHandle,iPackedInt)
	ELSE
		NETWORK_SEND_TRANSITION_GAMER_INSTRUCTION(aGamerHandle, "", TRANSITION_SESSION_INSTRUCTION_PROPERTY_DETAILS,
														iPackedInt, TRUE)
	ENDIF
ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║							lauch a group warp														
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_GROUP_WARP
	STRUCT_EVENT_COMMON_DETAILS Details
	
	GROUP_WARP_LOCATION eGroupWarpLocation
	INT iPlayerNamesHash[NUM_NETWORK_PLAYERS]
	INT iBitset

ENDSTRUCT

PROC BROADCAST_GROUP_WARP_EVENT(GROUP_WARP_LOCATION eGroupWarpLocation, INT &iPlayerNamesHash[], INT iBitset)
	
	SCRIPT_EVENT_DATA_GROUP_WARP Event
	Event.Details.Type = SCRIPT_EVENT_GROUP_WARP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iBitset = iBitset

	Event.eGroupWarpLocation =  eGroupWarpLocation
	
	INT i, iCount
	iCount = COUNT_OF(iPlayerNamesHash)
	IF iCount > NUM_NETWORK_PLAYERS
		iCount = NUM_NETWORK_PLAYERS
	ENDIF
	
	REPEAT iCount i
		Event.iPlayerNamesHash[i] = iPlayerNamesHash[i]
	ENDREPEAT
	
	NET_PRINT("BROADCAST_GROUP_WARP_EVENT - called by local player" ) NET_NL()	
	PRINTLN("BROADCAST_GROUP_WARP_EVENT - iGroupWarpLocation = ", ENUM_TO_INT(eGroupWarpLocation), " iBitset = ", iBitset)
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
	
ENDPROC




//╔═════════════════════════════════════════════════════════════════════════════╗
//║							launch synced interaction														
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_LAUNCH_SYNCED_INTERACTION
	STRUCT_EVENT_COMMON_DETAILS Details
	
	INT iSceneID
	//INT iUniqueID
	INT iPlayerNamesHash[4]
	INT iForceLocation
	INT iForceActor

ENDSTRUCT

PROC BROADCAST_LAUNCH_SYNCED_INTERACTION_EVENT(INT iSceneID, INT &iPlayerNamesHash[], INT iForceLocation=-1, INT iForceActor=-1)
	SCRIPT_EVENT_DATA_LAUNCH_SYNCED_INTERACTION Event
	Event.Details.Type = SCRIPT_EVENT_LAUNCH_SYNCED_INTERACTION
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.iSceneID =  iSceneID
	//Event.iUniqueID = iUniqueID
	Event.iForceLocation = iForceLocation
	Event.iForceActor = iForceActor
	
	INT i, iCount
	iCount = COUNT_OF(iPlayerNamesHash)
	IF iCount > NUM_NETWORK_PLAYERS
		iCount = NUM_NETWORK_PLAYERS
	ENDIF
	
	REPEAT iCount i
		Event.iPlayerNamesHash[i] = iPlayerNamesHash[i]
	ENDREPEAT
	
	NET_PRINT("BROADCAST_LAUNCH_SYNCED_INTERACTION_EVENT - called by local player" ) NET_NL()	
	PRINTLN("BROADCAST_LAUNCH_SYNCED_INTERACTION_EVENT - iForceLocation = ", iForceLocation)
	PRINTLN("BROADCAST_LAUNCH_SYNCED_INTERACTION_EVENT - iForceActor = ", iForceActor)
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
	
ENDPROC



//╔═════════════════════════════════════════════════════════════════════════════╗
//║							STORE LAST HOT TARGET ROUTE														
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_HOT_TARGET_ROUTE
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vRouteStart
ENDSTRUCT

PROC BROADCAST_HOT_TARGET_ROUTE(VECTOR vRouteStart, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_HOT_TARGET_ROUTE Event
	Event.Details.Type = SCRIPT_EVENT_HOT_TARGET_ROUTE
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.vRouteStart = vRouteStart
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_HOT_TARGET_ROUTE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_HOT_TARGET_ROUTE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							PLANE DROP EXPLODE VEHICLE														
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
//STRUCT SCRIPT_EVENT_DATA_PLANE_DROP_EXPLODE_VEHICLE
//	STRUCT_EVENT_COMMON_DETAILS Details
//	NETWORK_INDEX veh
//ENDSTRUCT
//
//PROC BROADCAST_PLANE_DROP_EXPLODE_VEHICLE(NETWORK_INDEX veh, INT iPlayerFlags)
//	SCRIPT_EVENT_DATA_PLANE_DROP_EXPLODE_VEHICLE Event
//	Event.Details.Type = SCRIPT_EVENT_PLANE_DROP_EXPLODE_VEHICLE
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//
//	Event.veh = veh
//	
//	IF NOT (iPlayerFlags = 0)
//		PRINTLN("     ----->    SCRIPT_EVENT_PLANE_DROP_EXPLODE_VEHICLE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_PLANE_DROP_EXPLODE_VEHICLE - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF
//ENDPROC

#IF IS_DEBUG_BUILD
//╔═════════════════════════════════════════════════════════════════════════════╗
//║							launch synced interaction														
//╚═════════════════════════════════════════════════════════════════════════════╝
// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_HOT_TARGET
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iVehType
	INT iVehModel
	INT iRouteType
	INT iRoute
	INT iReverseRoute
ENDSTRUCT

PROC BROADCAST_DEBUG_LAUNCH_HOT_TARGET(INT iVehType, INT iVehModel, INT iRouteType, INT iRoute, INT iReverseRoute, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_HOT_TARGET Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_HOT_TARGET
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.iVehType = iVehType
	Event.iVehModel = iVehModel
	Event.iRouteType = iRouteType
	Event.iRoute = iRoute
	Event.iReverseRoute = iReverseRoute
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_DEBUG_LAUNCH_HOT_TARGET - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_LAUNCH_HOT_TARGET - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
//STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_PLANE_DROP
//	STRUCT_EVENT_COMMON_DETAILS Details
//	INT iRoute
//ENDSTRUCT
//
//PROC BROADCAST_DEBUG_LAUNCH_PLANE_DROP(INT iRoute, INT iPlayerFlags)
//	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_PLANE_DROP Event
//	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_PLANE_DROP
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//
//	Event.iRoute = iRoute
//	
//	IF NOT (iPlayerFlags = 0)
//		PRINTLN("     ----->    SCRIPT_EVENT_DEBUG_LAUNCH_PLANE_DROP - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_DEBUG_LAUNCH_PLANE_DROP - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF
//ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_URBAN_WARFARE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iStartVeh
	INT iLocation
	BOOL bIsCompet
ENDSTRUCT

PROC BROADCAST_DEBUG_LAUNCH_URBAN_WARFARE(INT iveh, INT iLoc, BOOL bIsCompetitive, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_URBAN_WARFARE Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_URBAN_WARFARE
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.iStartVeh = iveh
	Event.iLocation = iLoc
	Event.bIsCompet = bIsCompetitive
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_DEBUG_LAUNCH_URBAN_WARFARE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_LAUNCH_URBAN_WARFARE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_PENNED_IN
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iLocation
ENDSTRUCT

PROC BROADCAST_DEBUG_LAUNCH_PENNED_IN(INT iLoc, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_PENNED_IN Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_PENNED_IN
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iLocation = iLoc
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_DEBUG_LAUNCH_PENNED_IN - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT(), " Location = ", iLoc)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_LAUNCH_PENNED_IN - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_MTA
	STRUCT_EVENT_COMMON_DETAILS Details
//	INT iLocation
ENDSTRUCT

PROC BROADCAST_DEBUG_LAUNCH_MTA( INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_MTA Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_MTA
	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.iLocation = iLoc
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_DEBUG_LAUNCH_MTA - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_LAUNCH_MTA - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_CHALLENGES
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iChallenge
ENDSTRUCT

PROC BROADCAST_DEBUG_LAUNCH_CHALLENGES(INT iChallenge, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_CHALLENGES Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_CHALLENGES
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.iChallenge = iChallenge
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_DEBUG_LAUNCH_CHALLENGES - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_LAUNCH_CHALLENGES - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_CHECKPOINTS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iArea
	INT iCPCollectionType
	INT iVariation
ENDSTRUCT

PROC BROADCAST_DEBUG_LAUNCH_CHECKPOINTS(INT iArea,INT iCPCollectionType,INT iVariation,INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_CHECKPOINTS Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_CHECKPOINTS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iArea = iArea
	Event.iCPCollectionType = iCPCollectionType
	Event.iVariation = iVariation
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_DEBUG_LAUNCH_CHECKPOINTS - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_LAUNCH_CHECKPOINTS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_PASS_THE_PARCEL
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iVehModel
	INT iRoute
ENDSTRUCT

PROC BROADCAST_DEBUG_LAUNCH_PASS_THE_PARCEL(INT iVehModel,INT iRoute, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_PASS_THE_PARCEL Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_PASS_THE_PARCEL
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.iVehModel = iVehModel
	Event.iRoute = iRoute
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_DEBUG_LAUNCH_PASS_THE_PARCEL - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_LAUNCH_PASS_THE_PARCEL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_HOT_PROPERTY
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iLocation
ENDSTRUCT

PROC BROADCAST_DEBUG_LAUNCH_HOT_PROPERTY(INT iLocation, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_HOT_PROPERTY Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_HOT_PROPERTY
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.iLocation = iLocation
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_DEBUG_LAUNCH_HOT_PROPERTY - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_LAUNCH_HOT_PROPERTY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_DEAD_DROP
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iLocation
ENDSTRUCT

PROC BROADCAST_DEBUG_LAUNCH_DEAD_DROP(INT iLocation, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_DEAD_DROP Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_DEAD_DROP
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.iLocation = iLocation
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_DEBUG_LAUNCH_DEAD_DROP - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_LAUNCH_DEAD_DROP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_KING_OF_THE_CASTLE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iLocation
ENDSTRUCT

PROC BROADCAST_DEBUG_LAUNCH_KING_OF_THE_CASTLE(INT iLocation, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_KING_OF_THE_CASTLE Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_KING_OF_THE_CASTLE
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.iLocation = iLocation
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_DEBUG_LAUNCH_KING_OF_THE_CASTLE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_LAUNCH_KING_OF_THE_CASTLE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_CRIMINAL_DAMAGE
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_DEBUG_LAUNCH_CRIMINAL_DAMAGE(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_CRIMINAL_DAMAGE Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_CRIMINAL_DAMAGE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_DEBUG_LAUNCH_CRIMINAL_DAMAGE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_LAUNCH_CRIMINAL_DAMAGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_HUNT_THE_BEAST
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iVariation
ENDSTRUCT

PROC BROADCAST_DEBUG_LAUNCH_HUNT_THE_BEAST(INT iVariation,INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_HUNT_THE_BEAST Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_HUNT_THE_BEAST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iVariation = iVariation
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_DEBUG_LAUNCH_HUNT_THE_BEAST - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_LAUNCH_HUNT_THE_BEAST - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

//STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_INFECTION
//	STRUCT_EVENT_COMMON_DETAILS Details
//ENDSTRUCT

//PROC BROADCAST_DEBUG_LAUNCH_INFECTION(INT iPlayerFlags)
//	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_INFECTION Event
//	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_INFECTION
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	
//	IF NOT (iPlayerFlags = 0)
//		PRINTLN("     ----->    SCRIPT_EVENT_DEBUG_LAUNCH_INFECTION - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_DEBUG_LAUNCH_INFECTION - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF
//ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_LAUNCH_MYSTERIOUS_TEXT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iLocation
ENDSTRUCT

PROC BROADCAST_DEBUG_LAUNCH_MYSTERIOUS_TEXT(INT iLocation, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_LAUNCH_MYSTERIOUS_TEXT Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_LAUNCH_MYSTERIOUS_TEXT
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.iLocation = iLocation
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_DEBUG_LAUNCH_MYSTERIOUS_TEXT - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_LAUNCH_MYSTERIOUS_TEXT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_SKIP_WARNING_DELAY
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_DEBUG_SKIP_WARNING_DELAY(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_SKIP_WARNING_DELAY Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_SKIP_WARNING_DELAY
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_DEBUG_SKIP_WARNING_DELAY - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_SKIP_WARNING_DELAY- playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_GANGOPS_FLOW_COMPLETE_MISSION
	STRUCT_EVENT_COMMON_DETAILS Details
	GANG_OPS_MISSION_ENUM eMission
	BOOL bComplete
ENDSTRUCT

PROC BROADCAST_DEBUG_GANGOPS_FLOW_COMPLETE_MISSION(GANG_OPS_MISSION_ENUM eMission, BOOL bComplete, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_GANGOPS_FLOW_COMPLETE_MISSION Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_GANGOPS_FLOW_COMPLETE_MISSION
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.eMission = eMission
	Event.bComplete = bComplete
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_DEBUG_GANGOPS_FLOW_COMPLETE_MISSION - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_GANGOPS_FLOW_COMPLETE_MISSION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_GANGOPS_FLOW_SKIP_TO_FINALE
	STRUCT_EVENT_COMMON_DETAILS Details
	GANG_OPS_MISSION_STRAND_ENUM eStrand
ENDSTRUCT

PROC BROADCAST_DEBUG_GANGOPS_FLOW_SKIP_TO_FINALE(GANG_OPS_MISSION_STRAND_ENUM eStrand, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_GANGOPS_FLOW_SKIP_TO_FINALE Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_GANGOPS_FLOW_SKIP_TO_FINALE
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.eStrand = eStrand
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_DEBUG_GANGOPS_FLOW_SKIP_TO_FINALE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_GANGOPS_FLOW_SKIP_TO_FINALE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DEBUG_GANGOPS_FLOW_RESET_STRAND
	STRUCT_EVENT_COMMON_DETAILS Details
	GANG_OPS_MISSION_STRAND_ENUM eStrand
ENDSTRUCT

PROC BROADCAST_DEBUG_GANGOPS_FLOW_RESET_STRAND(GANG_OPS_MISSION_STRAND_ENUM eStrand, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DEBUG_GANGOPS_FLOW_RESET_STRAND Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_GANGOPS_FLOW_RESET_STRAND
	Event.Details.FromPlayerIndex = PLAYER_ID()

	Event.eStrand = eStrand
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_DEBUG_GANGOPS_FLOW_RESET_STRAND - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBUG_GANGOPS_FLOW_RESET_STRAND - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

#ENDIF

STRUCT SCRIPT_EVENT_DATA_KILL_ACTIVE_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_KILL_ACTIVE_EVENT(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_KILL_ACTIVE_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_KILL_ACTIVE_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_KILL_ACTIVE_EVENT - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_KILL_ACTIVE_EVENT- playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_LAUNCH_FREEMODE_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	AML_SCRIPT_TYPE eEvent
	INT iVariation = -1
	INT iSubvariation = -1
	INT iCargoType = -1
ENDSTRUCT

#IF IS_DEBUG_BUILD
FUNC STRING GET_FORCED_VARIATION_NAME_TO_LAUNCH(AML_SCRIPT_TYPE eEvent, INT iVariation)
	SWITCH eEvent
		CASE AML_SCRIPT_BUSINESS_BATTLES		RETURN GET_FMBB_VARIATION_NAME_FOR_DEBUG(INT_TO_ENUM(FMBB_VARIATION, iVariation))
	ENDSWITCH
	RETURN "INVALID"
ENDFUNC
#ENDIF

PROC BROADCAST_LAUNCH_FREEMODE_EVENT(AML_SCRIPT_TYPE eEvent,INT iPlayerFlags, INT iVariation = -1, INT iSubvariation = -1, INT iCargoType = -1)
	SCRIPT_EVENT_DATA_LAUNCH_FREEMODE_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_LAUNCH_FREEMODE_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.eEvent = eEvent
	
	Event.iVariation = iVariation
	Event.iCargoType = iCargoType
	
	IF iVariation != (-1)
	AND iSubvariation != (-1)
		Event.iSubvariation = iSubvariation
	ENDIF
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    SCRIPT_EVENT_LAUNCH_FREEMODE_EVENT - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		
		#IF IS_DEBUG_BUILD
		IF iVariation != -1
			PRINTLN("     ----->    SCRIPT_EVENT_LAUNCH_FREEMODE_EVENT - FORCED VARIATION ", GET_FORCED_VARIATION_NAME_TO_LAUNCH(eEvent, iVariation))
			IF iSubvariation != -1
				PRINTLN("     ----->    SCRIPT_EVENT_LAUNCH_FREEMODE_EVENT - FORCED SUBVARIATION ", iSubvariation)
			ENDIF
		ENDIF
		#ENDIF
		
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_LAUNCH_FREEMODE_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC
#IF IS_DEBUG_BUILD
STRUCT SCRIPT_EVENT_DATA_TOGGLE_VEHICLE_DAMAGE
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_CALL_TOGGLE_VEHICLE_DAMAGE()
	SCRIPT_EVENT_DATA_TOGGLE_VEHICLE_DAMAGE Event
	Event.Details.Type = SCRIPT_EVENT_CALL_TOGGLE_VEHICLE_DAMAGE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	INT iPlayerFlags = ALL_PLAYERS()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_CALL_TOGGLE_VEHICLE_DAMAGE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CALL_TOGGLE_VEHICLE_DAMAGE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC
PROC PROCESS_CALL_TOGGLE_VEHICLE_DAMAGE(TICKER_EVENTS eTicker)
	SCRIPT_EVENT_DATA_TICKER_MESSAGE tickerData
	tickerData.Details.Type = SCRIPT_EVENT_TICKER_MESSAGE
	tickerData.playerID = PLAYER_ID()
	tickerData.TickerEvent = eTicker
	BROADCAST_TICKER_EVENT(tickerData, ALL_PLAYERS())
ENDPROC

STRUCT SCRIPT_EVENT_DATA_MODIFY_VEHICLE_WEAPON_DAMAGE_SCALE
	STRUCT_EVENT_COMMON_DETAILS Details
	FLOAT fDamage
ENDSTRUCT

PROC BROADCAST_MODIFY_VEHICLE_WEAPON_DAMAGE_SCALE(FLOAT fDamage)
	SCRIPT_EVENT_DATA_MODIFY_VEHICLE_WEAPON_DAMAGE_SCALE Event
	Event.Details.Type = SCRIPT_EVENT_MODIFY_VEHICLE_WEAPON_DAMAGE_SCALE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.fDamage = fDamage
	INT iPlayerFlags = ALL_PLAYERS()
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_MODIFY_VEHICLE_WEAPON_DAMAGE_SCALE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT(), " to change vehicle scale to ", fDamage)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_MODIFY_VEHICLE_WEAPON_DAMAGE_SCALE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC
#ENDIF


STRUCT SCRIPT_EVENT_DATA_KILL_ACTIVE_BOSS_MISSION
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_KILL_ACTIVE_BOSS_MISSION(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_KILL_ACTIVE_BOSS_MISSION Event
	Event.Details.Type = SCRIPT_EVENT_KILL_ACTIVE_BOSS_MISSION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_KILL_ACTIVE_BOSS_MISSION - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_KILL_ACTIVE_BOSS_MISSION- playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_KILL_ACTIVE_BOSS_MISSION_LOCAL
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_KILL_ACTIVE_BOSS_MISSION_LOCAL(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_KILL_ACTIVE_BOSS_MISSION_LOCAL Event
	Event.Details.Type = SCRIPT_EVENT_KILL_ACTIVE_BOSS_MISSION_LOCAL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_KILL_ACTIVE_BOSS_MISSION_LOCAL - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_KILL_ACTIVE_BOSS_MISSION_LOCAL- playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_REQUEST_BOSS_LIMO
	STRUCT_EVENT_COMMON_DETAILS Details
	MODEL_NAMES vehicleModel
	BOOL bIgnoreDistanceChecks
ENDSTRUCT

PROC BROADCAST_REQUEST_BOSS_LIMO(INT iPlayerFlags, MODEL_NAMES vehicleModel, BOOL bIgnoreDistanceChecks = FALSE)
	SCRIPT_EVENT_DATA_REQUEST_BOSS_LIMO Event
	Event.Details.Type = SCRIPT_EVENT_REQUEST_BOSS_LIMO
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.vehicleModel = vehicleModel
	Event.bIgnoreDistanceChecks = bIgnoreDistanceChecks
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_REQUEST_BOSS_LIMO - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_REQUEST_BOSS_LIMO- playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_REQUEST_BOSS_LIMO_FADE_IN
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX piGangBoss
ENDSTRUCT

PROC BROADCAST_REQUEST_BOSS_LIMO_FADE_IN(PLAYER_INDEX piGangBoss)
	SCRIPT_EVENT_DATA_REQUEST_BOSS_LIMO_FADE_IN Event
	Event.Details.Type 				= SCRIPT_EVENT_REQUEST_BOSS_LIMO_FADE_IN
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.piGangBoss 				= piGangBoss
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE, FALSE)
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_REQUEST_BOSS_LIMO_FADE_IN - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT(), " their boss is: ", GET_PLAYER_NAME(piGangBoss))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_REQUEST_BOSS_LIMO- playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_REQUEST_PLAYER_WARP_PV_NEAR_COORDS
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vCoords
	BOOL bFadeInAfter
	BOOL bIsHackerTruck
ENDSTRUCT

PROC BROADCAST_REQUEST_PLAYER_WARP_PV_NEAR_COORDS(VECTOR vCoords, PLAYER_INDEX pOwner, BOOL bFadeInAfter = FALSE, BOOL bIsHackerTruck = FALSE)
	SCRIPT_EVENT_DATA_REQUEST_PLAYER_WARP_PV_NEAR_COORDS Event
	Event.Details.Type 				= SCRIPT_EVENT_REQUEST_PLAYER_WARP_PV_NEAR_COORDS
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.vCoords 					= vCoords
	Event.bFadeInAfter				= bFadeInAfter
	Event.bIsHackerTruck		 	= bIsHackerTruck
	
	IF pOwner = INVALID_PLAYER_INDEX()
		NET_PRINT("BROADCAST_REQUEST_PLAYER_WARP_PV_NEAR_COORDS- pOwner = -1 so not broadcasting") NET_NL()
		EXIT
	ENDIF
	
	IF IS_VECTOR_ZERO(Event.vCoords)
		NET_PRINT("BROADCAST_REQUEST_PLAYER_WARP_PV_NEAR_COORDS- vCoords = 0 so not broadcasting") NET_NL()
		EXIT
	ENDIF
	
	#IF IS_DEBUG_BUILD
		IF bIsHackerTruck
			NET_PRINT("BROADCAST_REQUEST_PLAYER_WARP_PV_NEAR_COORDS- Requesting warp for hacker truck") NET_NL()
		ENDIF
	#ENDIF
	
	INT iPlayerFlags = SPECIFIC_PLAYER(pOwner)
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_REQUEST_PLAYER_WARP_PV_NEAR_COORDS - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT(), " the owner is: ", GET_PLAYER_NAME(pOwner))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_REQUEST_PLAYER_WARP_PV_NEAR_COORDS- playerflags = 0 so not broadcasting") NET_NL()
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_DELETE_OLD_BV
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_DELETE_OLD_BV(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_DELETE_OLD_BV Event
	Event.Details.Type = SCRIPT_EVENT_DELETE_OLD_BV
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_DELETE_OLD_BV - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DELETE_OLD_BV- playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_BOSS_WORK_REQUEST_SERVER
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iMission
	INT iRequestedVariation
	INT iRequestedVariation2
	INT iRequestedVariation3
	INT iWarehouse
ENDSTRUCT

PROC BROADCAST_GB_BOSS_WORK_REQUEST_SERVER(INT iMission, INT iPlayerFlags, INT iRequestedVariation = -1, INT iRequestedVariation2 = -1, INT iRequestedVariation3 = -1, INT iWarehouse = -1)
	SCRIPT_EVENT_DATA_GB_BOSS_WORK_REQUEST_SERVER Event
	Event.Details.Type = SCRIPT_EVENT_GB_BOSS_WORK_REQUEST_SERVER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iMission = iMission
	Event.iRequestedVariation = iRequestedVariation
	Event.iRequestedVariation2 = iRequestedVariation2
	Event.iRequestedVariation3 = iRequestedVariation3
	Event.iWarehouse = iWarehouse
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_BOSS_WORK_REQUEST_SERVER - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_BOSS_WORK_REQUEST_SERVER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT GB_BOSS_WORK_SERVER_VARIATION_DATA
	INT iVariation1
	INT iVariation2
	INT iVariation3
	FREEMODE_DELIVERY_ACTIVE_DROPOFF_PROPERTIES sDropOffProperties
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_GB_BOSS_WORK_SERVER_CONFIRM
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bAccept
	INT iMission
	GB_BOSS_WORK_SERVER_VARIATION_DATA vData
ENDSTRUCT

PROC BROADCAST_GB_BOSS_WORK_SERVER_CONFIRM(BOOL bAccept,INT iMission, INT iPlayerFlags, GB_BOSS_WORK_SERVER_VARIATION_DATA vData)
	SCRIPT_EVENT_DATA_GB_BOSS_WORK_SERVER_CONFIRM Event
	Event.Details.Type = SCRIPT_EVENT_GB_BOSS_WORK_SERVER_CONFIRM
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bAccept = bAccept
	Event.iMission = iMission
	Event.vData = vData
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_BOSS_WORK_SERVER_CONFIRM - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_BOSS_WORK_SERVER_CONFIRM - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FM_RANDOM_EVENT_REQUEST
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iMission
	INT iVariation
	INT iSubvariation
	eEVENT_SAFETY_CHECK_BYPASS eSafetyChecks
ENDSTRUCT

PROC BROADCAST_FM_RANDOM_EVENT_REQUEST(INT iPlayerFlags, INT iMission, INT iVariation = -1, INT iSubvariation = -1, eEVENT_SAFETY_CHECK_BYPASS eSafetyChecks = eEVENTSAFETYCHECKBYPASS_LOCAL)
	SCRIPT_EVENT_DATA_FM_RANDOM_EVENT_REQUEST Event
	Event.Details.Type = SCRIPT_EVENT_FM_RANDOM_EVENT_REQUEST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iMission = iMission
	Event.iVariation = iVariation
	Event.iSubvariation = iSubvariation
	Event.eSafetyChecks = eSafetyChecks
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_FM_RANDOM_EVENT_REQUEST - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FM_RANDOM_EVENT_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FM_RANDOM_EVENT_UPDATE_TRIGGER
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iInstance
	VECTOR vTrigger
	FLOAT fRange
ENDSTRUCT

PROC BROADCAST_FM_RANDOM_EVENT_UPDATE_TRIGGER(INT iPlayerFlags, INT iInstance, VECTOR vTrigger, FLOAT fRange = -1.0)
	SCRIPT_EVENT_DATA_FM_RANDOM_EVENT_UPDATE_TRIGGER Event
	Event.Details.Type = SCRIPT_EVENT_FM_RANDOM_EVENT_UPDATE_TRIGGER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iInstance = iInstance
	Event.vTrigger = vTrigger
	Event.fRange = fRange
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_FM_RANDOM_EVENT_UPDATE_TRIGGER - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FM_RANDOM_EVENT_UPDATE_TRIGGER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_TRIGGER_DEFEND_MISSION
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iWarehouse
ENDSTRUCT

PROC BROADCAST_GB_TRIGGER_DEFEND_MISSION(INT iPlayerFlags, INT iWarehouse)
	SCRIPT_EVENT_DATA_GB_TRIGGER_DEFEND_MISSION Event
	Event.Details.Type = SCRIPT_EVENT_GB_TRIGGER_DEFEND_MISSION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iWarehouse = iWarehouse
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_TRIGGER_DEFEND_MISSION - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_TRIGGER_DEFEND_MISSION - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_CONTRABAND_DESTROYED
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX contrabandOwner
	PLAYER_INDEX destroyer
	INT iUniqueSessionHash0
	INT iUniqueSessionHash1
ENDSTRUCT

PROC BROADCAST_CONTRABAND_DESTROYED(INT iPlayerFlags, PLAYER_INDEX contrabandOwner, PLAYER_INDEX destroyer)
	SCRIPT_EVENT_DATA_CONTRABAND_DESTROYED Event
	Event.Details.Type = SCRIPT_EVENT_CONTRABAND_DESTROYED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.contrabandOwner = contrabandOwner
	Event.destroyer = destroyer
	GET_THIS_SESSION_UNIQUE_EVENT_IDS(Event.iUniqueSessionHash0, Event.iUniqueSessionHash1)
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_CONTRABAND_DESTROYED - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CONTRABAND_DESTROYED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC


STRUCT SCRIPT_EVENT_DATA_VEHICLE_EXPORT_GIVE_WANTED_LEVEL
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iWantedLevel
	INT iSentAtPosix
	INT iDelay = 0
	BOOL bDamagedCop
ENDSTRUCT

PROC GB_BROADCAST_VEHICLE_EXPORT_GIVE_WANTED_LEVEL(INT iPlayerFlags, INT iWantedLevel, BOOL bDamagedCop, INT iDelay = 0)
	SCRIPT_EVENT_DATA_VEHICLE_EXPORT_GIVE_WANTED_LEVEL Event
	Event.Details.Type = SCRIPT_EVENT_VEHICLE_EXPORT_GIVE_WANTED_LEVEL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iWantedLevel = iWantedLevel
	Event.iSentAtPosix = GET_CLOUD_TIME_AS_INT()
	Event.bDamagedCop = bDamagedCop
	Event.iDelay = iDelay
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    GB_BROADCAST_VEHICLE_EXPORT_GIVE_WANTED_LEVEL - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		PRINTLN("     ----->    GB_BROADCAST_VEHICLE_EXPORT_GIVE_WANTED_LEVEL - WANTED LEVEL SENT = ", iWantedLevel, " - DAMAGED COP = ", bDamagedCop, " - DELAY = ", iDelay)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("GB_BROADCAST_VEHICLE_EXPORT_GIVE_WANTED_LEVEL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GUNRUN_ENTITY_DESTROYED
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX exportEntityOwner
	PLAYER_INDEX destroyer
ENDSTRUCT

PROC BROADCAST_GUNRUN_ENTITY_DESTROYED(INT iPlayerFlags, PLAYER_INDEX entityOwner, PLAYER_INDEX destroyer)
	SCRIPT_EVENT_DATA_GUNRUN_ENTITY_DESTROYED Event
	Event.Details.Type = SCRIPT_EVENT_GUNRUN_ENTITY_DESTROYED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.exportEntityOwner = entityOwner
	Event.destroyer = destroyer
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GUNRUN_ENTITY_DESTROYED - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GUNRUN_ENTITY_DESTROYED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GUNRUN_GIVE_WANTED_LEVEL
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iWantedLevel
	INT iSentAtPosix
	INT iDelay = 0
	BOOL bDamagedCop
ENDSTRUCT

PROC GB_BROADCAST_GUNRUN_GIVE_WANTED_LEVEL(INT iPlayerFlags, INT iWantedLevel, BOOL bDamagedCop, INT iDelay = 0)
	SCRIPT_EVENT_DATA_VEHICLE_EXPORT_GIVE_WANTED_LEVEL Event
	Event.Details.Type = SCRIPT_EVENT_GUNRUN_GIVE_WANTED_LEVEL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iWantedLevel = iWantedLevel
	Event.iSentAtPosix = GET_CLOUD_TIME_AS_INT()
	Event.bDamagedCop = bDamagedCop
	Event.iDelay = iDelay
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    GB_BROADCAST_GUNRUN_GIVE_WANTED_LEVEL - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		PRINTLN("     ----->    GB_BROADCAST_GUNRUN_GIVE_WANTED_LEVEL - WANTED LEVEL SENT = ", iWantedLevel, " - DAMAGED COP = ", bDamagedCop, " - DELAY = ", iDelay)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("GB_BROADCAST_GUNRUN_GIVE_WANTED_LEVEL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_BUSINESS_GIVE_WANTED_LEVEL
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iWantedLevel
	INT iSentAtPosix
	INT iDelay = 0
	BOOL bDamagedCop
ENDSTRUCT

PROC GB_BROADCAST_BUSINESS_GIVE_WANTED_LEVEL(INT iPlayerFlags, INT iWantedLevel, BOOL bDamagedCop, INT iDelay = 0)
	SCRIPT_EVENT_DATA_BUSINESS_GIVE_WANTED_LEVEL Event
	Event.Details.Type = SCRIPT_EVENT_BUSINESS_GIVE_WANTED_LEVEL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iWantedLevel = iWantedLevel
	Event.iSentAtPosix = GET_CLOUD_TIME_AS_INT()
	Event.bDamagedCop = bDamagedCop
	Event.iDelay = iDelay
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    GB_BROADCAST_BUSINESS_GIVE_WANTED_LEVEL - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		PRINTLN("     ----->    GB_BROADCAST_BUSINESS_GIVE_WANTED_LEVEL - WANTED LEVEL SENT = ", iWantedLevel, " - DAMAGED COP = ", bDamagedCop, " - DELAY = ", iDelay)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("GB_BROADCAST_BUSINESS_GIVE_WANTED_LEVEL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

PROC GB_BROADCAST_FM_EVENT_GIVE_WANTED_LEVEL(INT iPlayerFlags, INT iWantedLevel, BOOL bDamagedCop, INT iDelay = 0)
	SCRIPT_EVENT_DATA_BUSINESS_GIVE_WANTED_LEVEL Event
	Event.Details.Type = SCRIPT_EVENT_FM_EVENT_GIVE_WANTED_LEVEL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iWantedLevel = iWantedLevel
	Event.iSentAtPosix = GET_CLOUD_TIME_AS_INT()
	Event.bDamagedCop = bDamagedCop
	Event.iDelay = iDelay
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    GB_BROADCAST_FM_EVENT_GIVE_WANTED_LEVEL - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		PRINTLN("     ----->    GB_BROADCAST_FM_EVENT_GIVE_WANTED_LEVEL - WANTED LEVEL SENT = ", iWantedLevel, " - DAMAGED COP = ", bDamagedCop, " - DELAY = ", iDelay)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("GB_BROADCAST_FM_EVENT_GIVE_WANTED_LEVEL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_FREEMODE_CONTENT_GIVE_WANTED_LEVEL_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iFMMC
	INT iWantedLevel
	INT iSentAtPosix
	INT iDelay = 0
	BOOL bDamagedCop
ENDSTRUCT

PROC BROADCAST_FREEMODE_CONTENT_GIVE_WANTED_LEVEL(INT iFMMC, INT iPlayerFlags, INT iWantedLevel, BOOL bDamagedCop, INT iDelay = 0)
	SCRIPT_EVENT_FREEMODE_CONTENT_GIVE_WANTED_LEVEL_DATA Event
	Event.Details.Type = SCRIPT_EVENT_FREEMODE_CONTENT_GIVE_WANTED_LEVEL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	Event.iFMMC = iFMMC
	Event.iWantedLevel = iWantedLevel
	Event.iSentAtPosix = GET_CLOUD_TIME_AS_INT()
	Event.bDamagedCop = bDamagedCop
	Event.iDelay = iDelay
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_FREEMODE_CONTENT_GIVE_WANTED_LEVEL - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT(), " for FMMC ", iFMMC)
		PRINTLN("     ----->    BROADCAST_FREEMODE_CONTENT_GIVE_WANTED_LEVEL - WANTED LEVEL SENT = ", iWantedLevel, " - DAMAGED COP = ", bDamagedCop, " - DELAY = ", iDelay)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_FREEMODE_CONTENT_GIVE_WANTED_LEVEL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_VEHICLE_EXPORT_SWITCH_SCENARIOS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iSentAtPosix
ENDSTRUCT

PROC GB_BROADCAST_VEHICLE_EXPORT_SWITCH_SCENARIOS(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_VEHICLE_EXPORT_SWITCH_SCENARIOS Event
	Event.Details.Type = SCRIPT_EVENT_VEHICLE_EXPORT_SWITCH_SCENARIOS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iSentAtPosix = GET_CLOUD_TIME_AS_INT()
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    GB_BROADCAST_VEHICLE_EXPORT_SWITCH_SCENARIOS - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",Event.iSentAtPosix)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("GB_BROADCAST_VEHICLE_EXPORT_SWITCH_SCENARIOS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_JAILBREAK_RESET_PED_LOOKAT_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPrisonerPed
ENDSTRUCT

PROC BROADCAST_UPDATE_JAILBREAK_PED_LOOKAT_DATA(INT iPlayerFlags, INT iPrisonerPed)
	SCRIPT_EVENT_DATA_JAILBREAK_RESET_PED_LOOKAT_DATA Event
	Event.Details.Type = SCRIPT_EVENT_GB_JAILBREAK_UPDATE_PED_LOOKAT_DATA
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPrisonerPed = iPrisonerPed
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_UPDATE_JAILBREAK_PED_LOOKAT_DATA - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_UPDATE_JAILBREAK_PED_LOOKAT_DATA - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_SET_PLAYER_GANG_ROLE
	STRUCT_EVENT_COMMON_DETAILS Details
	GB_GANG_ROLE gangRole
	PLAYER_INDEX changedPlayer
ENDSTRUCT

PROC BROADCAST_GB_SET_PLAYER_GANG_ROLE(INT iPlayerFlags, PLAYER_INDEX changedPlayer, GB_GANG_ROLE gangRole)
	SCRIPT_EVENT_DATA_GB_SET_PLAYER_GANG_ROLE Event
	Event.Details.Type = SCRIPT_EVENT_GB_SET_PLAYER_GANG_ROLE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.gangRole = gangRole
	Event.changedPlayer = changedPlayer
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_SET_PLAYER_GANG_ROLE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_SET_PLAYER_GANG_ROLE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_NON_BOSS_CHALLENGE_REQUEST
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iMissionType
	INT iVariation
ENDSTRUCT

PROC BROADCAST_GB_NON_BOSS_CHALLENGE_REQUEST(INT iPlayerFlags, INT iType, INT iVariation)
	SCRIPT_EVENT_DATA_GB_NON_BOSS_CHALLENGE_REQUEST Event
	Event.Details.Type = SCRIPT_EVENT_GB_NON_BOSS_CHALLENGE_REQUEST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iMissionType = iType
	Event.iVariation = iVariation

	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_NON_BOSS_CHALLENGE_REQUEST - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_NON_BOSS_CHALLENGE_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_MEMBER_ABANDONED_CLUB
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_GB_MEMBER_ABANDONED_CLUB(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_GB_MEMBER_ABANDONED_CLUB Event
	Event.Details.Type = SCRIPT_EVENT_GB_MEMBER_ABANDONED_CLUB
	Event.Details.FromPlayerIndex = PLAYER_ID()

	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_MEMBER_ABANDONED_CLUB - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_MEMBER_ABANDONED_CLUB - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_START_TARGET_RIVAL
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX piRivalTarget 
	BOOL Activate
ENDSTRUCT

PROC BROADCAST_GB_START_TARGET_RIVAL(INT iPlayerFlags, PLAYER_INDEX rivalTarget, BOOL activate)
	SCRIPT_EVENT_DATA_GB_START_TARGET_RIVAL Event
	Event.Details.Type = SCRIPT_EVENT_GB_START_TARGET_RIVAL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.piRivalTarget = rivalTarget
	Event.Activate = activate

	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->  [TARGET_RIVAL]  BROADCAST_GB_START_TARGET_RIVAL - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT(), " rival ", GET_PLAYER_NAME(rivalTarget), " activate = ", activate, " ")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("[TARGET_RIVAL] BROADCAST_GB_START_TARGET_RIVAL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_NON_BOSS_DROP_REQUEST
	STRUCT_EVENT_COMMON_DETAILS Details
	eGB_BOSS_DROPS sDropType
ENDSTRUCT

PROC BROADCAST_GB_NON_BOSS_DROP_REQUEST(INT iPlayerFlags, eGB_BOSS_DROPS sDropType)
	SCRIPT_EVENT_DATA_GB_NON_BOSS_DROP_REQUEST Event
	Event.Details.Type = SCRIPT_EVENT_GB_NON_BOSS_DROP_REQUEST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.sDropType = sDropType

	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    [MAGNATE_GANG_BOSS] [BOSS_DROPS] BROADCAST_GB_NON_BOSS_DROP_REQUEST - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("[MAGNATE_GANG_BOSS] [BOSS_DROPS] BROADCAST_GB_NON_BOSS_DROP_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT STRUCT_SCRIPT_EVENT_BEEN_PAID_GOON_CASH
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCashPaid
	GB_CONTRABAND_TYPE contrabandType
	BOOL bBonus
	INT iUniquePlayersHash
	INT iUniqueSessionHash0
	INT iUniqueSessionHash1
ENDSTRUCT

PROC BROADCAST_GB_SCRIPT_EVENT_BEEN_PAID_GOON_CASH(PLAYER_INDEX playerToSendTo, INT iCashAmount, BOOL bBonus, GB_CONTRABAND_TYPE contrabandType = GBCT_CEO)
	
	STRUCT_SCRIPT_EVENT_BEEN_PAID_GOON_CASH sEvent
	
	sEvent.Details.Type = SCRIPT_EVENT_BEEN_PAID_GOON_CASH
	sEvent.Details.FromPlayerIndex = PLAYER_ID()
	sEvent.iCashPaid = iCashAmount
	sEvent.bBonus = bBonus
	sEvent.contrabandType = contrabandType
	sEvent.iUniquePlayersHash = GET_THIS_PLAYER_UNIQUE_EVENT_ID(playerToSendTo)
	GET_THIS_SESSION_UNIQUE_EVENT_IDS(sEvent.iUniqueSessionHash0, sEvent.iUniqueSessionHash1)
	
	IF playerToSendTo != INVALID_PLAYER_INDEX()
		IF NETWORK_IS_PLAYER_ACTIVE(playerToSendTo)
			PRINTLN("     ----->    [MAGNATE_GANG_BOSS] BROADCAST_GB_SCRIPT_EVENT_BEEN_PAID_GOON_CASH - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at GET_CLOUD_TIME_AS_INT = ", GET_CLOUD_TIME_AS_INT())
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, sEvent, SIZE_OF(sEvent), SPECIFIC_PLAYER(playerToSendTo))	
		ELSE
			PRINTLN("[MAGNATE_GANG_BOSS] BROADCAST_GB_SCRIPT_EVENT_BEEN_PAID_GOON_CASH - NETWORK_IS_PLAYER_ACTIVE = FALSE so not broadcasting")	
		ENDIF
	ELSE
		PRINTLN("[MAGNATE_GANG_BOSS] BROADCAST_GB_SCRIPT_EVENT_BEEN_PAID_GOON_CASH - playerToSendTo = INVALID_PLAYER_INDEX() so not broadcasting")	
	ENDIF
	
ENDPROC

STRUCT STRUCT_SCRIPT_EVENT_GB_BOSS_STARTED_USING_SCTV
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_GB_SCRIPT_EVENT_BOSS_STARTED_USING_SCTV()
	
	INT i
	STRUCT_SCRIPT_EVENT_GB_BOSS_STARTED_USING_SCTV sEvent
	
	sEvent.Details.Type 							= SCRIPT_EVENT_GB_BOSS_STARTED_USING_SCTV
	sEvent.Details.FromPlayerIndex 					= PLAYER_ID()
	
	REPEAT GB_MAX_GANG_GOONS i
		IF GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].sMagnateGangBossData.GangMembers[i] != INVALID_PLAYER_INDEX()
			IF NETWORK_IS_PLAYER_ACTIVE(GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].sMagnateGangBossData.GangMembers[i])
				SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, sEvent, SIZE_OF(sEvent), SPECIFIC_PLAYER(GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].sMagnateGangBossData.GangMembers[i]))	
				PRINTLN("[MAGNATE_GANG_BOSS] BROADCAST_GB_SCRIPT_EVENT_BOSS_STARTED_USING_SCTV - broadcast to goon ", i)
				#IF IS_DEBUG_BUILD
				TEXT_LABEL_63 tl63Temp = GET_PLAYER_NAME(GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].sMagnateGangBossData.GangMembers[i])
				PRINTLN("[MAGNATE_GANG_BOSS] BROADCAST_GB_SCRIPT_EVENT_BOSS_STARTED_USING_SCTV - goon ", i, " player name = ", tl63Temp)
				#ENDIF
			ELSE
				PRINTLN("[MAGNATE_GANG_BOSS] BROADCAST_GB_SCRIPT_EVENT_BOSS_STARTED_USING_SCTV - not broadcasting to goon ", i, " NETWORK_IS_PLAYER_ACTIVE = FALSE")
			ENDIF
		ELSE
			PRINTLN("[MAGNATE_GANG_BOSS] BROADCAST_GB_SCRIPT_EVENT_BOSS_STARTED_USING_SCTV - not broadcasting to goon ", i, " player index = INVALID_PLAYER_INDEX")
		ENDIF
	ENDREPEAT
	
ENDPROC

PROC PROCESS_GB_SCRIPT_EVENT_BOSS_STARTED_USING_SCTV(INT iEventID)
	
	STRUCT_SCRIPT_EVENT_GB_BOSS_STARTED_USING_SCTV Event
	
	IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iEventID, Event, SIZE_OF(Event))
		
		PRINTLN("[GBCARJCK] PROCESS_GB_SCRIPT_EVENT_BOSS_STARTED_USING_SCTV - called...")
		
		GB_SET_GLOBAL_NON_BD_BIT0(eGB_GLOBAL_NON_BD_BITSET_0_GB_BOSS_USING_SCTV)
		
	ELSE	
		SCRIPT_ASSERT("[GBCARJCK] PROCESS_GB_SCRIPT_EVENT_BOSS_STARTED_USING_SCTV - could not retrieve data.")
	ENDIF
	
ENDPROC

STRUCT STRUCT_SCRIPT_EVENT_GB_BOSS_CHANGED_NAME
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT
PROC GB_SEND_NAME_CHANGE_EVENT()
	INT i
	STRUCT_SCRIPT_EVENT_GB_BOSS_STARTED_USING_SCTV sEvent
	sEvent.Details.Type 							= SCRIPT_EVENT_GB_BOSS_CHANGED_NAME
	sEvent.Details.FromPlayerIndex 					= PLAYER_ID()
	REPEAT GB_MAX_GANG_GOONS i
		IF GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].sMagnateGangBossData.GangMembers[i] != INVALID_PLAYER_INDEX()
			IF NETWORK_IS_PLAYER_ACTIVE(GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].sMagnateGangBossData.GangMembers[i])
				SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, sEvent, SIZE_OF(sEvent), SPECIFIC_PLAYER(GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].sMagnateGangBossData.GangMembers[i]))	
				PRINTLN("[MAGNATE_GANG_BOSS] GB_SEND_NAME_CHANGE_EVENT - broadcast to goon ", i)
				#IF IS_DEBUG_BUILD
				TEXT_LABEL_63 tl63Temp = GET_PLAYER_NAME(GlobalplayerBD_FM_3[NATIVE_TO_INT(PLAYER_ID())].sMagnateGangBossData.GangMembers[i])
				PRINTLN("[MAGNATE_GANG_BOSS] GB_SEND_NAME_CHANGE_EVENT - goon ", i, " player name = ", tl63Temp)
				#ENDIF
			ELSE
				PRINTLN("[MAGNATE_GANG_BOSS] GB_SEND_NAME_CHANGE_EVENT - not broadcasting to goon ", i, " NETWORK_IS_PLAYER_ACTIVE = FALSE")
			ENDIF
		ELSE
			PRINTLN("[MAGNATE_GANG_BOSS] GB_SEND_NAME_CHANGE_EVENT - not broadcasting to goon ", i, " player index = INVALID_PLAYER_INDEX")
		ENDIF
	ENDREPEAT	
ENDPROC

PROC GB_PROCESS_NAME_CHANGE_EVENT(INT iEventID)
	STRUCT_SCRIPT_EVENT_GB_BOSS_STARTED_USING_SCTV Event
	IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iEventID, Event, SIZE_OF(Event))
		PRINTLN("[MAGNATE_GANG_BOSS] GB_PROCESS_NAME_CHANGE_EVENT - called...")
		GB_SET_GLOBAL_NON_BD_BIT0(eGB_GLOBAL_NON_BD_BITSET_0_REFRESH_GANG_NAME)
	ELSE	
		SCRIPT_ASSERT("[MAGNATE_GANG_BOSS] GB_PROCESS_NAME_CHANGE_EVENT - could not retrieve data.")
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_CLEAR_REMOTE_PLAYER_GANG_MEMBERSHIP
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bDoMessage
	eGB_END_BEING_GOON_REASON eEndReason
ENDSTRUCT

PROC BROADCAST_GB_CLEAR_REMOTE_PLAYER_GANG_MEMBERSHIP(INT iPlayerFlags,BOOL bDoMessage = FALSE, eGB_END_BEING_GOON_REASON eEndReason = eGBENDBEINGGOONREASON_IGNORE)
	SCRIPT_EVENT_DATA_GB_CLEAR_REMOTE_PLAYER_GANG_MEMBERSHIP Event
	Event.Details.Type = SCRIPT_EVENT_GB_CLEAR_REMOTE_PLAYER_GANG_MEMBERSHIP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bDoMessage = bDoMessage
	Event.eEndReason = eEndReason
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_CLEAR_REMOTE_PLAYER_GANG_MEMBERSHIP - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_CLEAR_REMOTE_PLAYER_GANG_MEMBERSHIP - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_REQUEST_JOIN_GANG
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_GB_REQUEST_JOIN_GANG(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_GB_REQUEST_JOIN_GANG Event
	Event.Details.Type = SCRIPT_EVENT_GB_REQUEST_JOIN_GANG
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_REQUEST_JOIN_GANG - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_REQUEST_JOIN_GANG - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_CONFIRM_JOIN_GANG
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bAccept
ENDSTRUCT

PROC BROADCAST_GB_CONFIRM_JOIN_GANG(BOOL bAccept, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_GB_CONFIRM_JOIN_GANG Event
	Event.Details.Type = SCRIPT_EVENT_GB_CONFIRM_JOIN_GANG
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.bAccept = bAccept
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_CONFIRM_JOIN_GANG - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_CONFIRM_JOIN_GANG - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_INVITE_TO_GANG
	STRUCT_EVENT_COMMON_DETAILS Details
	GOON_INVITE_TYPE invType
	STRUCT_GANG_INVITE_DATA sInviteData
	INT iUniqueSessionHash0
	INT iUniqueSessionHash1
ENDSTRUCT

PROC BROADCAST_GB_INVITE_TO_GANG(INT iPlayerFlags, GOON_INVITE_TYPE invType, STRUCT_GANG_INVITE_DATA sInviteData)
	SCRIPT_EVENT_DATA_GB_INVITE_TO_GANG Event
	Event.Details.Type = SCRIPT_EVENT_GB_INVITE_TO_GANG
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.invType = invType
	Event.sInviteData = sInviteData
	GET_THIS_SESSION_UNIQUE_EVENT_IDS(Event.iUniqueSessionHash0, Event.iUniqueSessionHash1)
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_INVITE_TO_GANG - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_INVITE_TO_GANG - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_CLEAR_GANG_INVITE
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_GB_CLEAR_GANG_INVITE(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_GB_CLEAR_GANG_INVITE Event
	Event.Details.Type = SCRIPT_EVENT_GB_CLEAR_GANG_INVITE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_CLEAR_GANG_INVITE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_CLEAR_GANG_INVITE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_REFRESH_LIMO_LOCKS
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_GB_REFRESH_LIMO_LOCKS(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_GB_REFRESH_LIMO_LOCKS Event
	Event.Details.Type = SCRIPT_EVENT_GB_REFRESH_LIMO_LOCKS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_GB_REFRESH_LIMO_LOCKS - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_GB_REFRESH_LIMO_LOCKS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GB_PLAYER_COLLECTED_MONEY_PACKAGE
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_PLAYER_COLLECTED_MONEY_PACKAGE(INT iPlayerFlags)
	SCRIPT_EVENT_DATA_GB_PLAYER_COLLECTED_MONEY_PACKAGE Event
	Event.Details.Type = SCRIPT_EVENT_GB_PLAYER_COLLECTED_CASH
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("     ----->    BROADCAST_PLAYER_COLLECTED_MONEY_PACKAGE - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PLAYER_COLLECTED_MONEY_PACKAGE - playerflags = 0 so not broadcasting") NET_NL()	
	ENDIF
ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║						Give Boss Cut From Freemode Earnings																		
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_GIVE_GANG_BOSS_CUT_FROM_EARNINGS
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iCashToGive
	BOOL bDoTicker
	BOOL bBossCut
ENDSTRUCT

PROC BROADCAST_GIVE_GANG_BOSS_CUT_FROM_EARNINGS(PLAYER_INDEX PlayerID, INT iCash, BOOL bDoTicker = TRUE)

	IF IS_NET_PLAYER_OK(PlayerID, FALSE, TRUE)
		SCRIPT_EVENT_DATA_GIVE_PLAYER_CASH_FROM_LAST_JOB Event
		
		Event.iType  = ENUM_TO_INT(SCRIPT_EVENT_GB_GIVE_GANG_BOSS_CUT_FROM_EARNINGS)
		Event.FromPlayerIndex = PLAYER_ID()
		Event.iCashToGive = iCash
		Event.banimate = bDoTicker
		Event.iUniquePlayersHash = GET_THIS_PLAYER_UNIQUE_EVENT_ID(PlayerID)		
		GET_THIS_SESSION_UNIQUE_EVENT_IDS(Event.iUniqueSessionHash0, Event.iUniqueSessionHash1)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerID))
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_GIVE_GANG_BOSS_CUT_FROM_EARNINGS - SENT TO - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_GIVE_GANG_BOSS_CUT_FROM_EARNINGS - PLAYER NOT OKAY - ") NET_PRINT(GET_PLAYER_NAME(PlayerID)) NET_NL()
	ENDIF

ENDPROC

////╔═════════════════════════════════════════════════════════════════════════════╗
////║						Set Gang Outfit	Broadcast Struct																
////╚═════════════════════════════════════════════════════════════════════════════╝
//STRUCT SCRIPT_EVENT_DATA_GB_SET_GANG_OUTFIT
//	STRUCT_EVENT_COMMON_DETAILS Details 
//	INT outfit
//	INT style
//ENDSTRUCT

STRUCT STRUCT_SCRIPT_EVENT_CASHING_OUT_UPDATE_BLOCKED_ATMS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iBlockedATM
ENDSTRUCT

PROC BROADCAST_CASHING_OUT_UPDATE_BLOCKED_ATMS(PLAYER_INDEX playerToSendTo, INT iBlockedATMIndex)
	
	IF IS_NET_PLAYER_OK(playerToSendTo, FALSE, TRUE)
		STRUCT_SCRIPT_EVENT_CASHING_OUT_UPDATE_BLOCKED_ATMS Event
		
		Event.Details.Type 				= SCRIPT_EVENT_CASHING_OUT_UPDATE_BLOCKED_ATMS
		Event.Details.FromPlayerIndex 	= PLAYER_ID()
		Event.iBlockedATM 				= iBlockedATMIndex
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(playerToSendTo))
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_CASHING_OUT_UPDATE_BLOCKED_ATMS - SENT TO - ") NET_PRINT(GET_PLAYER_NAME(playerToSendTo)) NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_CASHING_OUT_UPDATE_BLOCKED_ATMS - PLAYER NOT OKAY - ") NET_PRINT(GET_PLAYER_NAME(playerToSendTo)) NET_NL()
	ENDIF
	
ENDPROC 

STRUCT STRUCT_SCRIPT_EVENT_CASHING_OUT_UPDATE_ATM_BLIPS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iATM
ENDSTRUCT

PROC BROADCAST_CASHING_OUT_UPDATE_ATM_BLIPS(INT iPlayerFlags, INT iATMToUpdate)
	
	IF NOT (iPlayerFlags = 0)
		STRUCT_SCRIPT_EVENT_CASHING_OUT_UPDATE_ATM_BLIPS Event
		
		Event.Details.Type 				= SCRIPT_EVENT_CASHING_OUT_UPDATE_ATM_BLIP
		Event.Details.FromPlayerIndex 	= PLAYER_ID()
		Event.iATM 						= iATMToUpdate
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_CASHING_OUT_UPDATE_ATM_BLIPS - SENT - ") NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_CASHING_OUT_UPDATE_ATM_BLIPS - INVALID PLAYER FLAGS PASSED - ") NET_NL()
	ENDIF
	
ENDPROC

STRUCT STRUCT_SCRIPT_EVENT_AIRFREIGHT_RESTART_DISCONNECT_TIMER
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bReset
ENDSTRUCT

PROC BROADCAST_GB_AIRFREIGHT_RESTART_DISCONNECT_TIMER(PLAYER_INDEX player, BOOL bReset = FALSE)
	IF player != INVALID_PLAYER_INDEX()
		IF IS_NET_PLAYER_OK(player, FALSE, TRUE)
			STRUCT_SCRIPT_EVENT_AIRFREIGHT_RESTART_DISCONNECT_TIMER Event
			Event.Details.Type = SCRIPT_EVENT_AIRFREIGHT_RESTART_DISCONNECT_TIMER
			Event.Details.FromPlayerIndex = PLAYER_ID()
			Event.bReset = bReset
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(player))
			NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_GB_AIRFREIGHT_RESTART_DISCONNECT_TIMER - SENT TO - ") NET_PRINT(GET_PLAYER_NAME(player)) NET_NL()
		ELSE
			NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_GB_AIRFREIGHT_RESTART_DISCONNECT_TIMER - PLAYER NOT OKAY - ") NET_PRINT(GET_PLAYER_NAME(player)) NET_NL()
		ENDIF
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_GB_AIRFREIGHT_RESTART_DISCONNECT_TIMER - INVALID PLAYER INDEX") NET_NL()
	ENDIF
ENDPROC

PROC BROADCAST_START_RADAR_JAM(INT iPlayerFlags)
	IF NOT (iPlayerFlags = 0)
		STRUCT_EVENT_COMMON_DETAILS Details
		Details.Type = SCRIPT_EVENT_CONTRABAND_SELL_START_RADAR_JAM
		Details.FromPlayerIndex = PLAYER_ID()
			
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Details, SIZE_OF(Details), iPlayerFlags)
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_START_RADAR_JAM - SENT - ") NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_START_RADAR_JAM - INVALID PLAYER INDEX") NET_NL()
	ENDIF
ENDPROC

PROC BROADCAST_STOP_RADAR_JAM(INT iPlayerFlags)
	IF NOT (iPlayerFlags = 0)
		
		STRUCT_EVENT_COMMON_DETAILS Details
		Details.Type = SCRIPT_EVENT_CONTRABAND_SELL_STOP_RADAR_JAM
		Details.FromPlayerIndex = PLAYER_ID()
			
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Details, SIZE_OF(Details), iPlayerFlags)
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_STOP_RADAR_JAM - SENT - ") NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_STOP_RADAR_JAM - INVALID PLAYER INDEX") NET_NL()
	ENDIF
ENDPROC

STRUCT STRUCT_SCRIPT_EVENT_SET_VEHICLE_AS_TARGETABLE_BY_HOMING_MISSILE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bTargetable
ENDSTRUCT

PROC BROADCAST_SET_VEHICLE_AS_TARGETABLE_BY_HOMING_MISSILE(INT iPlayerFlags, BOOL bTargetable)
	IF NOT (iPlayerFlags = 0)
		
		STRUCT_SCRIPT_EVENT_SET_VEHICLE_AS_TARGETABLE_BY_HOMING_MISSILE eStruct
		eStruct.Details.Type = SCRIPT_EVENT_GB_SET_VEHICLE_AS_TARGETABLE_BY_HOMING_MISSILE
		eStruct.Details.FromPlayerIndex = PLAYER_ID()
		eStruct.bTargetable = bTargetable
			
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, eStruct, SIZE_OF(eStruct), iPlayerFlags)
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_SET_VEHICLE_AS_TARGETABLE_BY_HOMING_MISSILE - SENT - ") NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_SET_VEHICLE_AS_TARGETABLE_BY_HOMING_MISSILE - INVALID PLAYER INDEX") NET_NL()
	ENDIF
ENDPROC
	

STRUCT STRUCT_SCRIPT_EVENT_OPEN_BOMB_BAY_DOORS
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bOpen
ENDSTRUCT

PROC BROADCAST_OPEN_BOMB_BAY_DOORS(INT iPlayerFlags, BOOL bOpen)
	IF NOT (iPlayerFlags = 0)
		STRUCT_SCRIPT_EVENT_OPEN_BOMB_BAY_DOORS eStruct
		eStruct.Details.Type = SCRIPT_EVENT_OPEN_BOMB_BAY_DOORS
		eStruct.Details.FromPlayerIndex = PLAYER_ID()
		eStruct.bOpen = bOpen

		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, eStruct, SIZE_OF(eStruct), iPlayerFlags)
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_OPEN_BOMB_BAY_DOORS - SENT - ") NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_OPEN_BOMB_BAY_DOORS - INVALID PLAYER INDEX") NET_NL()
	ENDIF
ENDPROC

STRUCT STRUCT_SCRIPT_EVENT_SET_CHAFF_LOCK_ON
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bSet
ENDSTRUCT

PROC BROADCAST_SET_CHAFF_LOCK_ON(INT iPlayerFlags, BOOL bSet)
	IF NOT (iPlayerFlags = 0)
		STRUCT_SCRIPT_EVENT_SET_CHAFF_LOCK_ON eStruct
		eStruct.Details.Type = SCRIPT_EVENT_SET_CHAFF_LOCK_ON
		eStruct.Details.FromPlayerIndex = PLAYER_ID()
		eStruct.bSet = bSet
		
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, eStruct, SIZE_OF(eStruct), iPlayerFlags)
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_SET_CHAFF_LOCK_ON - SENT - ") NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_SET_CHAFF_LOCK_ON - INVALID PLAYER INDEX") NET_NL()
	ENDIF
ENDPROC

STRUCT STRUCT_SCRIPT_EVENT_DECREMENT_AIRCRAFT_AMMO
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bBomb
	BOOL bCountermeasure
ENDSTRUCT

PROC BROADCAST_DECREMENT_AIRCRAFT_AMMO(INT iPlayerFlags, BOOL bBomb, BOOL bCountermeasure)
	IF NOT (iPlayerFlags = 0)
		STRUCT_SCRIPT_EVENT_DECREMENT_AIRCRAFT_AMMO eStruct
		eStruct.Details.Type = SCRIPT_EVENT_DECREMENT_AIRCRAFT_AMMO
		eStruct.Details.FromPlayerIndex = PLAYER_ID()
		eStruct.bBomb = bBomb
		eStruct.bCountermeasure = bCountermeasure
		
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, eStruct, SIZE_OF(eStruct), iPlayerFlags)
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_DECREMENT_AIRCRAFT_AMMO - SENT - ") NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_DECREMENT_AIRCRAFT_AMMO - INVALID PLAYER INDEX") NET_NL()
	ENDIF
ENDPROC

STRUCT STRUCT_SCRIPT_EVENT_ADD_FMBB_VARIATION_TO_HISTORY
	STRUCT_EVENT_COMMON_DETAILS Details
	FMBB_VARIATION eVariation1
ENDSTRUCT

PROC BROADCAST_ADD_FMBB_VARIATION_TO_HISTORY(INT iPlayerFlags, FMBB_VARIATION eVariation1)
	IF NOT (iPlayerFlags = 0)
		STRUCT_SCRIPT_EVENT_ADD_FMBB_VARIATION_TO_HISTORY eStruct
		eStruct.Details.Type = SCRIPT_EVENT_ADD_FMBB_VARIATION_TO_HISTORY
		eStruct.Details.FromPlayerIndex = PLAYER_ID()
		eStruct.eVariation1 = eVariation1
		
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, eStruct, SIZE_OF(eStruct), iPlayerFlags)
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_ADD_FMBB_VARIATION_TO_HISTORY - SENT - ") NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_ADD_FMBB_VARIATION_TO_HISTORY - INVALID PLAYER INDEX") NET_NL()
	ENDIF
ENDPROC

STRUCT STRUCT_SCRIPT_EVENT_TRIGGER_PROPERTY_SCRIPT_PED_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX pOwner
	PROPERTY_SCRIPT_PED_EVENT ePedEvent
ENDSTRUCT

PROC BROADCAST_TRIGGER_PROPERTY_SCRIPT_PED_EVENT(PLAYER_INDEX pOwner, PROPERTY_SCRIPT_PED_EVENT ePedEvent)
	STRUCT_SCRIPT_EVENT_TRIGGER_PROPERTY_SCRIPT_PED_EVENT Event
	
	Event.Details.Type 				= SCRIPT_EVENT_TRIGGER_PROPERTY_SCRIPT_PED_EVENT
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.pOwner 					= pOwner
	Event.ePedEvent					= ePedEvent
	
	INT iPlayerFlags = ALL_PLAYERS()
	
	IF NOT (iPlayerFlags = 0)		
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_TRIGGER_PROPERTY_SCRIPT_PED_EVENT - SENT - ") NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_TRIGGER_PROPERTY_SCRIPT_PED_EVENT - INVALID PLAYER INDEX") NET_NL()
	ENDIF
ENDPROC

STRUCT STRUCT_SCRIPT_EVENT_INCREMENT_PLAYER_APPEARANCES_IN_CLUB
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX pOwner
ENDSTRUCT

PROC BROADCAST_INCREMENT_PLAYER_APPEARANCES_IN_CLUB(PLAYER_INDEX pOwner)
	STRUCT_SCRIPT_EVENT_INCREMENT_PLAYER_APPEARANCES_IN_CLUB Event
	
	Event.Details.Type 				= SCRIPT_EVENT_INCREMENT_PLAYER_APPEARANCES_IN_CLUB
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.pOwner 					= pOwner
	
	INT iPlayerFlags = ALL_PLAYERS()
	
	IF NOT (iPlayerFlags = 0)		
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_INCREMENT_PLAYER_APPEARANCES_IN_CLUB - SENT - ") NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_INCREMENT_PLAYER_APPEARANCES_IN_CLUB - INVALID PLAYER INDEX") NET_NL()
	ENDIF
ENDPROC

STRUCT STRUCT_SCRIPT_EVENT_TRIGGER_SMPL_INT_GHOST_CHAIR
	STRUCT_EVENT_COMMON_DETAILS Details
	SIMPLE_INTERIORS eInteriorID
	PLAYER_INDEX pOwner
ENDSTRUCT

PROC BROADCAST_TRIGGER_SMPL_INT_GHOST_CHAIR(PLAYER_INDEX pOwner, SIMPLE_INTERIORS eInteriorID)
	STRUCT_SCRIPT_EVENT_TRIGGER_SMPL_INT_GHOST_CHAIR Event
	
	Event.Details.Type 				= SCRIPT_EVENT_TRIGGER_SMPL_INT_GHOST_CHAIR
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.pOwner 					= pOwner
	Event.eInteriorID				= eInteriorID
	
	INT iPlayerFlags = ALL_PLAYERS()
	
	IF NOT (iPlayerFlags = 0)		
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_TRIGGER_SMPL_INT_GHOST_CHAIR - SENT - ") NET_NL()
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_TRIGGER_SMPL_INT_GHOST_CHAIR - INVALID PLAYER INDEX") NET_NL()
	ENDIF
ENDPROC

STRUCT STRUCT_SCRIPT_EVENT_ENTERING_CLUB_IN_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iFloorIndex
	//NETWORK_INDEX vehEntryVehicle
	SIMPLE_INTERIORS eInteriorID
ENDSTRUCT

PROC BROADCAST_ENTERING_MULTI_FLOOR_SMPL_INTERIOR_IN_VEHICLE(VEHICLE_INDEX vehEntryVehicle, INT iFloorIndex, SIMPLE_INTERIORS eInteriorID)
	
	IF NOT DOES_ENTITY_EXIST(PLAYER_PED_ID())
	OR IS_ENTITY_DEAD(PLAYER_PED_ID())
	OR NOT DOES_ENTITY_EXIST(vehEntryVehicle)
	OR IS_ENTITY_DEAD(vehEntryVehicle)
	OR NOT IS_PED_IN_VEHICLE(PLAYER_PED_ID(), vehEntryVehicle)
	OR GET_PED_IN_VEHICLE_SEAT(vehEntryVehicle) != PLAYER_PED_ID()
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_ENTERING_MULTI_FLOOR_SMPL_INTERIOR_IN_VEHICLE - PED IS NOT IN A VALID STATE IN THE DRIVERS SEAT - ") NET_NL()
		EXIT
	ENDIF
	
	STRUCT_SCRIPT_EVENT_ENTERING_CLUB_IN_VEHICLE Event
	
	Event.Details.Type 				= SCRIPT_EVENT_ENTERING_CLUB_OR_HUB_IN_VEHICLE
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	//Event.vehEntryVehicle 			= VEH_TO_NET(vehEntryVehicle)
	Event.iFloorIndex				= iFloorIndex
	Event.eInteriorID				= eInteriorID
	
	INT iPlayerFlags = ALL_PLAYERS_IN_VEHICLE(vehEntryVehicle, FALSE, FALSE, FALSE)
	
	IF NOT (iPlayerFlags = 0)		
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
		PRINTLN("     ---------->     BROADCAST_ENTERING_MULTI_FLOOR_SMPL_INTERIOR_IN_VEHICLE - SENT")
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_ENTERING_MULTI_FLOOR_SMPL_INTERIOR_IN_VEHICLE - No other players in the vehicle") NET_NL()
	ENDIF
ENDPROC

STRUCT STRUCT_SCRIPT_EVENT_UPDATED_FROSTED_GLASS
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bFrosted
	INT iGlassIndex
	INT iFrameCount
ENDSTRUCT

PROC BROADCAST_UPDATED_FROSTED_GLASS(BOOL bFrosted, INT iGlassIndex, INT iScriptHost)
	
	STRUCT_SCRIPT_EVENT_UPDATED_FROSTED_GLASS Event
	
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_FROSTED_GLASS
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bFrosted					= bFrosted
	Event.iGlassIndex				= iGlassIndex
	Event.iFrameCount				= GET_FRAME_COUNT()
	
	INT iPlayerFlags = 0
	IF iScriptHost != -1
		SET_BIT(iPlayerFlags, iScriptHost)
	ENDIF
	
	IF NOT (iPlayerFlags = 0)		
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
		PRINTLN("     ---------->     BROADCAST_UPDATED_FROSTED_GLASS - SENT")
	ELSE
		NET_PRINT_TIME() NET_PRINT("     ---------->     BROADCAST_UPDATED_FROSTED_GLASS - INVALID PLAYER INDEX") NET_NL()
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							INSURANCE EVENT																
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_INSURANCE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iAmount
ENDSTRUCT

PROC BROADCAST_CAR_INSURANCE_EVENT(INT iPlayerFlags,INT iValue)
	SCRIPT_EVENT_DATA_INSURANCE Event
	Event.Details.Type = SCRIPT_EVENT_CAR_INSURANCE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iAmount =  iValue
	IF NOT (iPlayerFlags = 0)
		NET_PRINT("BROADCAST_CAR_INSURANCE_EVENT - called by local player" ) NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CAR_INSURANCE_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							CONTACT REQUEST EVENT																
//╚═════════════════════════════════════════════════════════════════════════════╝
#IF IS_DEBUG_BUILD
FUNC STRING EVENTS_GET_CONTACT_REQUEST_STRING_FROM_TYPE(CONTACT_REQUEST_TYPE RequestType)
	SWITCH RequestType
		CASE REQUEST_BRUCIE_BOX					RETURN	"REQUEST_BRUCIE_BOX"						BREAK
		CASE REQUEST_BOUNTY						RETURN	"REQUEST_BOUNTY"							BREAK
		CASE REQUEST_THIEF1						RETURN	"REQUEST_THIEF1"							BREAK
		CASE REQUEST_THIEF2						RETURN	"REQUEST_THIEF2"							BREAK
		CASE REQUEST_THIEF3						RETURN	"REQUEST_THIEF3"							BREAK
		CASE REQUEST_GIVE_WANTED				RETURN	"REQUEST_GIVE_WANTED"						BREAK
		CASE REQUEST_OFF_THE_RADAR				RETURN	"REQUEST_OFF_THE_RADAR"						BREAK
		CASE REQUEST_PERSONAL_VEHICLE			RETURN	"REQUEST_PERSONAL_VEHICLE"					BREAK
		CASE REQUEST_AMMO_DROP					RETURN	"REQUEST_AMMO_DROP"							BREAK
		CASE REQUEST_BOAT_PICKUP				RETURN	"REQUEST_BOAT_PICKUP"						BREAK
		CASE REQUEST_BACKUP_HELI				RETURN	"REQUEST_BACKUP_HELI"						BREAK
		CASE REQUEST_AIRSTRIKE					RETURN	"REQUEST_AIRSTRIKE"							BREAK
		CASE REQUEST_MERCENARIES				RETURN	"REQUEST_MERCENARIES"						BREAK
		CASE REQUEST_HELI_PICKUP				RETURN	"REQUEST_HELI_PICKUP"						BREAK
		CASE REQUEST_REVEAL_PLAYERS				RETURN	"REQUEST_REVEAL_PLAYERS"					BREAK
		CASE REQUEST_LESTER_JOB					RETURN 	"REQUEST_LESTER_JOB"						BREAK
		CASE REQUEST_VEHICLE_SPAWN				RETURN 	"REQUEST_VEHICLE_SPAWN"						BREAK
		CASE REQUEST_GERALD_JOB					RETURN 	"REQUEST_GERALD_JOB"						BREAK
		CASE REQUEST_SIMEON_JOB					RETURN 	"REQUEST_SIMEON_JOB"						BREAK
		CASE REQUEST_MARTIN_JOB					RETURN  "REQUEST_MARTIN_JOB"						BREAK
		CASE REQUEST_RON_JOB					RETURN 	"REQUEST_RON_JOB"							BREAK
		CASE REQUEST_REMOVE_WANTED				RETURN	"REQUEST_REMOVE_WANTED"						BREAK
		CASE REQUEST_PEGASUS					RETURN	"REQUEST_PEGASUS"							BREAK
		CASE REQUEST_LESTER_LOCATE_BOAT			RETURN	"REQUEST_LESTER_LOCATE_BOAT"				BREAK
		CASE REQUEST_LESTER_LOCATE_HELI			RETURN	"REQUEST_LESTER_LOCATE_HELI"				BREAK
		CASE REQUEST_LESTER_LOCATE_CAR			RETURN	"REQUEST_LESTER_LOCATE_CAR"					BREAK
		CASE REQUEST_LESTER_LOCATE_PLANE		RETURN	"REQUEST_LESTER_LOCATE_PLANE"				BREAK
		CASE REQUEST_STRIPPER_JULIET			RETURN	"REQUEST_STRIPPER_JULIET"					BREAK
		CASE REQUEST_STRIPPER_NIKKI				RETURN	"REQUEST_STRIPPER_NIKKI"					BREAK
		CASE REQUEST_STRIPPER_CHASTITY			RETURN	"REQUEST_STRIPPER_CHASTITY"					BREAK
		CASE REQUEST_STRIPPER_CHEETAH			RETURN	"REQUEST_STRIPPER_CHEETAH"					BREAK
		CASE REQUEST_STRIPPER_INFERNUS			RETURN	"REQUEST_STRIPPER_INFERNUS"					BREAK
		CASE REQUEST_STRIPPER_FUFU				RETURN	"REQUEST_STRIPPER_FUFU"						BREAK
		CASE REQUEST_STRIPPER_SAPPHIRE			RETURN	"REQUEST_STRIPPER_SAPPHIRE"					BREAK
		CASE REQUEST_STRIPPER_PEACH				RETURN	"REQUEST_STRIPPER_PEACH"					BREAK
		
		CASE REQUEST_PERSONAL_ASSISTANT_IMPOUND_RECOVERY 		RETURN	"REQUEST_PERSONAL_ASSISTANT_IMPOUND_RECOVERY"				BREAK
		CASE REQUEST_PERSONAL_ASSISTANT_HELI_PICKUP				RETURN	"REQUEST_PERSONAL_ASSISTANT_HELI_PICKUP"					BREAK
		
		CASE REQUEST_GUNRUNNING_TRUCK			RETURN	"REQUEST_GUNRUNNING_TRUCK"					BREAK
		CASE REQUEST_PERSONAL_AIRCRAFT			RETURN	"REQUEST_PERSONAL_AIRCRAFT"					BREAK
		CASE REQUEST_ARMORY_AIRCRAFT			RETURN	"REQUEST_ARMORY_AIRCRAFT"					BREAK
		CASE REQUEST_HACKER_TRUCK				RETURN	"REQUEST_HACKER_TRUCK"						BREAK
		CASE REQUEST_LESTER_LOCATE_BLIMP		RETURN	"REQUEST_LESTER_LOCATE_BLIMP"				BREAK
		CASE REQUEST_RC_BANDITO					RETURN "REQUEST_RC_BANDITO"							BREAK
		CASE REQUEST_CASINO_MANAGER_LIMO		RETURN	"REQUEST_CASINO_MANAGER_LIMO"				BREAK
		CASE REQUEST_CASINO_MANAGER_LUXURY_CAR	RETURN	"REQUEST_CASINO_MANAGER_LUXURY_CAR"			BREAK
		CASE REQUEST_RC_TANK					RETURN "REQUEST_RC_TANK"							BREAK
		CASE REQUEST_RETURN_PV					RETURN "REQUEST_RETURN_PV"							BREAK
		#IF FEATURE_HEIST_ISLAND	
		CASE REQUEST_SUBMARINE					RETURN "REQUEST_SUBMARINE"							BREAK
		CASE REQUEST_SUBMARINE_DINGHY			RETURN "REQUEST_SUBMARINE_DINGHY"					BREAK
		CASE REQUEST_MOON_POOL					RETURN "REQUEST_MOON_POOL"							BREAK
		#ENDIF
		#IF FEATURE_FIXER
		CASE REQUEST_RC_PERSONAL_VEHICLE		RETURN "REQUEST_RC_PERSONAL_VEHICLE"				BREAK
		CASE REQUEST_SUPPLY_STASH				RETURN "REQUEST_SUPPLY_STASH"						BREAK
		CASE REQUEST_SOURCE_MOTORCYCLE			RETURN "REQUEST_SOURCE_MOTORCYCLE"					BREAK
		CASE REQUEST_OUT_OF_SIGHT				RETURN "REQUEST_OUT_OF_SIGHT"						BREAK
		CASE REQUEST_FRANKLIN_PAYPHONE_HIT		RETURN "REQUEST_FRANKLIN_PAYPHONE_HIT"				BREAK
		CASE REQUEST_COMPANY_SUV_SERVICE		RETURN "REQUEST_COMPANY_SUV_SERVICE"				BREAK
		#ENDIF
		#IF FEATURE_DLC_2_2022
		CASE REQUEST_ACID_LAB					RETURN "REQUEST_ACID_LAB"							BREAK
		CASE REQUEST_SUPPORT_BIKE				RETURN "REQUEST_SUPPORT_BIKE"						BREAK
		#ENDIF
	ENDSWITCH
	RETURN ""
ENDFUNC
#ENDIF

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CONTACT_REQUEST
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerID
	CONTACT_REQUEST_TYPE RequestType
	INT iResponseBS
	CONTACT_REQUEST_VARIATION requestVariation
	#IF IS_DEBUG_BUILD
	INT iDebugIdentifier
	#ENDIF
ENDSTRUCT

PROC BROADCAST_ASK_SERVER_FOR_CONTACT_REQUEST(INT iPlayerFlags,CONTACT_REQUEST_TYPE RequestType, PLAYER_INDEX thePlayer,CONTACT_REQUEST_VARIATION requestVariation = REQUEST_VARIATION_INVALID)
	SCRIPT_EVENT_DATA_CONTACT_REQUEST Event
	Event.Details.Type = SCRIPT_EVENT_ASK_SERVER_FOR_CONTACT_REQUEST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.RequestType = RequestType
	Event.requestVariation = requestVariation
	Event.playerID = thePlayer
	#IF IS_DEBUG_BUILD
	Event.iDebugIdentifier = GET_RANDOM_INT_IN_RANGE(0,99999999)
	#ENDIF
	
	PRINTLN("BROADCAST_ASK_SERVER_FOR_CONTACT_REQUEST of type ", EVENTS_GET_CONTACT_REQUEST_STRING_FROM_TYPE(RequestType),
					" - debugIdentifier = ",Event.iDebugIdentifier ) 	
	
	IF NOT (iPlayerFlags = 0)
		IF requestVariation = REQUEST_VARIATION_INVALID
			g_TransitionSessionNonResetVars.contactRequests.iResultBS[ENUM_TO_INT(event.RequestType)] = 0
			REINIT_NET_TIMER(g_TransitionSessionNonResetVars.contactRequests.stOutstandingTimer[ENUM_TO_INT(RequestType)],TRUE)
			g_TransitionSessionNonResetVars.contactRequests.piHostWhenRequested = NETWORK_GET_HOST_OF_SCRIPT(FREEMODE_SCRIPT())
			PRINTLN("BROADCAST_ASK_SERVER_FOR_CONTACT_REQUESTL: Host when request was sent = ", NATIVE_TO_INT(NETWORK_GET_HOST_OF_SCRIPT(FREEMODE_SCRIPT())))
		ELSE
			MPGlobalsAmbience.npcBountyRequests.iResultBS = 0
			REINIT_NET_TIMER(MPGlobalsAmbience.npcBountyRequests.stOutstandingTimer)
		ENDIF
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_ASK_SERVER_FOR_CONTACT_REQUEST- playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_ASK_SERVER_FOR_CLEAR_PENDING_CONTACT_REQUEST(INT iPlayerFlags,CONTACT_REQUEST_TYPE RequestType, PLAYER_INDEX thePlayer,CONTACT_REQUEST_VARIATION requestVariation = REQUEST_VARIATION_INVALID)
	SCRIPT_EVENT_DATA_CONTACT_REQUEST Event
	Event.Details.Type = SCRIPT_EVENT_ASK_SERVER_FOR_CLEAR_PENDING_CONTACT_REQUEST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.RequestType = RequestType
	Event.playerID = thePlayer
	#IF IS_DEBUG_BUILD
	Event.iDebugIdentifier = GET_RANDOM_INT_IN_RANGE(0,99999999)
	
	#ENDIF
	PRINTLN("BROADCAST_ASK_SERVER_FOR_CLEAR_PENDING_CONTACT_REQUEST of type ", EVENTS_GET_CONTACT_REQUEST_STRING_FROM_TYPE(RequestType),
					" - debugIdentifier = ",Event.iDebugIdentifier ) 	
	g_TransitionSessionNonResetVars.contactRequests.clear[ENUM_TO_INT(RequestType)].WaitingForClear = TRUE
	REINIT_NET_TIMER(g_TransitionSessionNonResetVars.contactRequests.clear[ENUM_TO_INT(RequestType)].Timer,TRUE)
	IF NOT (iPlayerFlags = 0)
		IF requestVariation = REQUEST_VARIATION_INVALID
			RESET_NET_TIMER(g_TransitionSessionNonResetVars.contactRequests.stOutstandingTimer[ENUM_TO_INT(RequestType)])
		ELSE
			RESET_NET_TIMER(MPGlobalsAmbience.npcBountyRequests.stOutstandingTimer)
		ENDIF
		#IF IS_DEBUG_BUILD
		IF bTestRequestPendingClearFailure
			PRINTLN("BROADCAST_ASK_SERVER_FOR_CLEAR_PENDING_CONTACT_REQUEST: bTestRequestPendingClearFailure = TRUE") 
		ELSE
		#ENDIF
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
		#IF IS_DEBUG_BUILD
		ENDIF
		#ENDIF
	ELSE
		NET_PRINT("BROADCAST_ASK_SERVER_FOR_CLEAR_PENDING_CONTACT_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_TELL_SERVER_CONTACT_REQUEST_COMPLETE(INT iPlayerFlags,CONTACT_REQUEST_TYPE RequestType, PLAYER_INDEX thePlayer)
	SCRIPT_EVENT_DATA_CONTACT_REQUEST Event
	Event.Details.Type = SCRIPT_EVENT_TELL_SERVER_CONTACT_REQUEST_COMPLETE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.RequestType = RequestType
	Event.playerID = thePlayer
	#IF IS_DEBUG_BUILD
	Event.iDebugIdentifier = GET_RANDOM_INT_IN_RANGE(0,99999999)
	#ENDIF
	PRINTLN("BROADCAST_TELL_SERVER_CONTACT_REQUEST_COMPLETE of type ", EVENTS_GET_CONTACT_REQUEST_STRING_FROM_TYPE(RequestType),
					" - debugIdentifier = ",Event.iDebugIdentifier ) 		
	IF NOT (iPlayerFlags = 0)
		#IF IS_DEBUG_BUILD
		IF bTestRequestCompleteFailure
			PRINTLN("BROADCAST_TELL_SERVER_CONTACT_REQUEST_COMPLETE: bTestRequestCompleteFailure = TRUE") 
		ELSE
		#ENDIF
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
		#IF IS_DEBUG_BUILD
		ENDIF
		#ENDIF
	ELSE
		NET_PRINT("BROADCAST_TELL_SERVER_CONTACT_REQUEST_COMPLETE- playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_SERVER_SEND_RESPONSE_FOR_CONTACT_REQUEST(INT iPlayerFlags,CONTACT_REQUEST_TYPE RequestType,PLAYER_INDEX thePlayer, INT iResponseBS, CONTACT_REQUEST_VARIATION contactVariation)
	SCRIPT_EVENT_DATA_CONTACT_REQUEST Event
	Event.Details.Type = SCRIPT_EVENT_SERVER_SEND_RESPONSE_FOR_CONTACT_REQUEST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.RequestType = RequestType
	Event.requestVariation = contactVariation
	Event.iResponseBS = iResponseBS
	Event.playerID = thePlayer
	#IF IS_DEBUG_BUILD
	Event.iDebugIdentifier = GET_RANDOM_INT_IN_RANGE(0,99999999)
	#ENDIF
	PRINTLN("BROADCAST_SERVER_SEND_RESPONSE_FOR_CONTACT_REQUEST of type ",EVENTS_GET_CONTACT_REQUEST_STRING_FROM_TYPE(RequestType),
					" - debugIdentifier = ",Event.iDebugIdentifier ) 	
	PRINTLN("Event.requestVariation = ",ENUM_TO_INT(Event.requestVariation)) 					
		
	IF NOT (iPlayerFlags = 0)
		
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SERVER_SEND_RESPONSE_FOR_CONTACT_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

PROC BROADCAST_SERVER_SEND_RESPONSE_FOR_CLEAR_CONTACT_REQUEST(INT iPlayerFlags,CONTACT_REQUEST_TYPE RequestType,PLAYER_INDEX thePlayer, INT iResponseBS)
	SCRIPT_EVENT_DATA_CONTACT_REQUEST Event
	Event.Details.Type = SCRIPT_EVENT_SERVER_SEND_RESPONSE_FOR_CLEAR_CONTACT_REQUEST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.RequestType = RequestType
	Event.iResponseBS = iResponseBS
	Event.playerID = thePlayer
	#IF IS_DEBUG_BUILD
	Event.iDebugIdentifier = GET_RANDOM_INT_IN_RANGE(0,99999999)
	#ENDIF
	PRINTLN("BROADCAST_SERVER_SEND_RESPONSE_FOR_CLEAR_CONTACT_REQUEST of type ",EVENTS_GET_CONTACT_REQUEST_STRING_FROM_TYPE(RequestType),
					" - debugIdentifier = ",Event.iDebugIdentifier ) 	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_SERVER_SEND_RESPONSE_FOR_CLEAR_CONTACT_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC


PROC BROADCAST_PLAYER_BEGIN_CR_TARGET_COOLDOWN(INT iPlayerFlags,CONTACT_REQUEST_TYPE RequestType)
	SCRIPT_EVENT_DATA_CONTACT_REQUEST Event
	Event.Details.Type = SCRIPT_EVENT_PLAYER_BEGIN_CR_TARGET_COOLDOWN
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.RequestType = RequestType
	PRINTLN("BROADCAST_PLAYER_BEGIN_CR_TARGET_COOLDOWN of type ",EVENTS_GET_CONTACT_REQUEST_STRING_FROM_TYPE(RequestType) ) 	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_PLAYER_BEGIN_CR_TARGET_COOLDOWN - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║							VEHICLE SPAWN EVENT																	
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_VEHICLE_SPAWN_FAIL
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerID
	INT iRequestID
ENDSTRUCT

PROC BROADCAST_SERVER_VEHICLE_SPAWN_FAIL(INT iPlayerFlags, INT iRequestID, PLAYER_INDEX thePlayer)
	SCRIPT_EVENT_DATA_VEHICLE_SPAWN_FAIL Event
	Event.Details.Type = SCRIPT_EVENT_SERVER_VEHICLE_SPAWN_FAIL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRequestID = iRequestID
	Event.playerID = thePlayer
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
ENDPROC

STRUCT SCRIPT_EVENT_DATA_VEHICLE_SPAWN_REQUEST
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPlayerID
	INT iRequestID
	INT iVSID
ENDSTRUCT

PROC BROADCAST_SERVER_VEHICLE_SPAWN_REQUEST(INT iPlayerFlags, INT iPlayerID, INT iRequestID, INT iVSID)
	SCRIPT_EVENT_DATA_VEHICLE_SPAWN_REQUEST Event
	Event.Details.Type = SCRIPT_EVENT_SERVER_VEHICLE_SPAWN_REQUEST
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPlayerID = iPlayerID
	Event.iRequestID = iRequestID
	Event.iVSID = iVSID
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
ENDPROC

STRUCT SCRIPT_EVENT_DATA_VEHICLE_SPAWN_COMPLETE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPlayerID
	INT iRequestID
	INT iVSID
ENDSTRUCT

PROC BROADCAST_SERVER_VEHICLE_SPAWN_COMPLETE(INT iPlayerFlags, INT iPlayerID, INT iRequestID, INT iVSID)
	SCRIPT_EVENT_DATA_VEHICLE_SPAWN_COMPLETE Event
	Event.Details.Type = SCRIPT_EVENT_SERVER_VEHICLE_SPAWN_COMPLETE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iPlayerID = iPlayerID
	Event.iRequestID = iRequestID
	Event.iVSID = iVSID
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║							BROADCAST GARAGE OPEN/CLOSE REQUESTS																	
//╚═════════════════════════════════════════════════════════════════════════════╝
//
//// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
//STRUCT SCRIPT_EVENT_DATA_GARAGE_DOOR
//	STRUCT_EVENT_COMMON_DETAILS Details 
//	BOOL bForceOpen
//	INT iGarageType
//	INT iGarageTeam
//ENDSTRUCT
//
////PURPOSE: Broadcast for all player to let them know when someone requested a garage open 
//// NOTE: only server will care but since you don't know who is host send to everyone
//PROC BROADCAST_GARAGE_OPEN_REQUEST(INT iGarageType, INT iGarageTeam, INT iPlayerFlags, BOOL bForceOpen = FALSE)
//	SCRIPT_EVENT_DATA_GARAGE_DOOR Event
//	Event.Details.Type = SCRIPT_EVENT_GARAGE_OPEN_REQUEST
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.iGarageType = iGarageType
//	Event.iGarageTeam = iGarageTeam
//	Event.bForceOpen = bForceOpen
//	NET_PRINT_TIME() NET_NL()
//	NET_PRINT("BROADCAST_GARAGE_OPEN_REQUEST") NET_NL()
//	NET_PRINT_STRINGS(GET_THIS_SCRIPT_NAME()," BROADCAST_GARAGE_OPEN_REQUEST has been called") NET_NL()
//	NET_NL()
//		NET_PRINT_STRING_INT("GARAGE TYPE: ",iGarageType) NET_NL()
//		NET_PRINT_STRING_INT("TEAM: ",iGarageTeam) NET_NL()
//	NET_NL()
//	IF NOT (iPlayerFlags = 0)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_GARAGE_OPEN_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF	
//ENDPROC
//
//
////PURPOSE: Broadcast for all player to let them know when someone cleared their request for a garage being open
//// NOTE: only server will care but since you don't know who is host send to everyone
//PROC BROADCAST_CLEAR_GARAGE_OPEN_REQUEST(INT iGarageType, INT iGarageTeam, INT iPlayerFlags, BOOL bForcedOpen = FALSE)
//	SCRIPT_EVENT_DATA_GARAGE_DOOR Event
//	Event.Details.Type = SCRIPT_EVENT_CLEAR_GARAGE_OPEN_REQUEST
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.iGarageType = iGarageType
//	Event.iGarageTeam = iGarageTeam
//	Event.bForceOpen = bForcedOpen
//	NET_PRINT_TIME() NET_NL()
//	NET_PRINT("BROADCAST_CLEAR_GARAGE_OPEN_REQUEST") NET_NL()
//	NET_PRINT_STRINGS(GET_THIS_SCRIPT_NAME()," BROADCAST_CLEAR_GARAGE_OPEN_REQUEST has been called") NET_NL()
//	NET_NL()
//		NET_PRINT_STRING_INT("GARAGE TYPE: ",iGarageType) NET_NL()
//		NET_PRINT_STRING_INT("TEAM: ",iGarageTeam) NET_NL()
//	NET_NL()
//	IF NOT (iPlayerFlags = 0)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_CLEAR_GARAGE_OPEN_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF	
//ENDPROC
//
////╔═════════════════════════════════════════════════════════════════════════════╗
////║							BROADCAST PAY AND SPRAY OPEN/CLOSE REQUESTS																	
////╚═════════════════════════════════════════════════════════════════════════════╝
//
//// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
//STRUCT SCRIPT_EVENT_DATA_PAY_AND_SPRAY_DOOR
//	STRUCT_EVENT_COMMON_DETAILS Details 
//	INT iPayAndSprayID
//ENDSTRUCT
//
////PURPOSE: Broadcast for all player to let them know when someone requested a pay and spray open 
//// NOTE: only server will care but since you don't know who is host send to everyone
//PROC BROADCAST_PAY_AND_SPRAY_LOCK_REQUEST(INT iPayAndSprayID, INT iPlayerFlags)
//	SCRIPT_EVENT_DATA_PAY_AND_SPRAY_DOOR Event
//	Event.Details.Type = SCRIPT_EVENT_PAY_AND_SPRAY_LOCK_REQUEST
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.iPayAndSprayID = iPayAndSprayID
//	NET_PRINT_STRINGS(GET_THIS_SCRIPT_NAME()," BROADCAST_PAY_AND_SPRAY_LOCK_REQUEST has been called") NET_NL()
//	NET_NL()
//		NET_PRINT_STRING_INT("iPayAndSprayID: ",iPayAndSprayID) NET_NL()
//	NET_NL()
//	IF NOT (iPlayerFlags = 0)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_PAY_AND_SPRAY_LOCK_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF	
//ENDPROC
//
//
////PURPOSE: Broadcast for all player to let them know when someone cleared their request for a pay and spray being open
//// NOTE: only server will care but since you don't know who is host send to everyone
//PROC BROADCAST_CLEAR_PAY_AND_SPRAY_LOCK_REQUEST(INT iPayAndSprayID, INT iPlayerFlags)
//	SCRIPT_EVENT_DATA_PAY_AND_SPRAY_DOOR Event
//	Event.Details.Type = SCRIPT_EVENT_CLEAR_PAY_AND_SPRAY_LOCK_REQUEST
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.iPayAndSprayID = iPayAndSprayID
//	NET_PRINT_STRINGS(GET_THIS_SCRIPT_NAME()," BROADCAST_CLEAR_PAY_AND_SPRAY_LOCK_REQUEST has been called") NET_NL()
//	NET_NL()
//		NET_PRINT_STRING_INT("iPayAndSprayID: ",iPayAndSprayID) NET_NL()
//	NET_NL()
//	IF NOT (iPlayerFlags = 0)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_CLEAR_PAY_AND_SPRAY_LOCK_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF	
//ENDPROC

//STRUCT SCRIPT_EVENT_DATA_NON_GARAGE_DOOR
//	STRUCT_EVENT_COMMON_DETAILS Details 
//	INT iNonGarageDoorID
//ENDSTRUCT
//
////PURPOSE: Broadcast for all player to let them know when someone requested a non-garage door open 
//// NOTE: only server will care but since you don't know who is host send to everyone
//PROC BROADCAST_NON_GARAGE_DOOR_LOCK_REQUEST(INT iNonGarageDoorID, INT iPlayerFlags)
//	SCRIPT_EVENT_DATA_NON_GARAGE_DOOR Event
//	Event.Details.Type = SCRIPT_EVENT_NON_GARAGE_DOOR_LOCK_REQUEST
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.iNonGarageDoorID = iNonGarageDoorID
//	NET_PRINT_STRINGS(GET_THIS_SCRIPT_NAME()," BROADCAST_NON_GARAGE_DOOR_LOCK_REQUEST has been called") NET_NL()
//	NET_NL()
//		NET_PRINT_STRING_INT("iNonGarageDoorID: ",iNonGarageDoorID) NET_NL()
//	NET_NL()
//	IF NOT (iPlayerFlags = 0)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_NON_GARAGE_DOOR_LOCK_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF	
//ENDPROC
//
//
////PURPOSE: Broadcast for all player to let them know when someone cleared their request for a non-garage door being open
//// NOTE: only server will care but since you don't know who is host send to everyone
//PROC BROADCAST_CLEAR_NON_GARAGE_DOOR_LOCK_REQUEST(INT iNonGarageDoorID, INT iPlayerFlags)
//	SCRIPT_EVENT_DATA_NON_GARAGE_DOOR Event
//	Event.Details.Type = SCRIPT_EVENT_CLEAR_NON_GARAGE_DOOR_LOCK_REQUEST
//	Event.Details.FromPlayerIndex = PLAYER_ID()
//	Event.iNonGarageDoorID = iNonGarageDoorID
//	NET_PRINT_STRINGS(GET_THIS_SCRIPT_NAME()," BROADCAST_CLEAR_NON_GARAGE_DOOR_LOCK_REQUEST has been called") NET_NL()
//	NET_NL()
//		NET_PRINT_STRING_INT("iNonGarageDoorID: ",iNonGarageDoorID) NET_NL()
//	NET_NL()
//	IF NOT (iPlayerFlags = 0)
//		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
//	ELSE
//		NET_PRINT("BROADCAST_CLEAR_NON_GARAGE_DOOR_LOCK_REQUEST - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF	
//ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							BROADCAST STAT QUERY AND SEND STAT DATA																
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_CHARACTER_STAT_DATA_INT
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iRequestID
	INT iMPIntStat
	INT iValue
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_CHARACTER_STAT_DATA_FLOAT
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iRequestID
	INT iMPIntStat
	FLOAT fValue
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_CHARACTER_STAT_DATA_BOOL
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iRequestID
	INT iMPIntStat
	BOOL bValue
ENDSTRUCT


//PURPOSE: Broadcast for all player to let them know when someone requested a stat
PROC BROADCAST_CHARACTER_STAT_DATA_QUERY_INT(INT iRequestID,INT iMPIntStat, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_CHARACTER_STAT_DATA_INT Event
	Event.Details.Type = SCRIPT_EVENT_CHARACTER_STAT_DATA_QUERY_INT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRequestID = iRequestID
	Event.iMPIntStat = iMPIntStat
	IF NOT (iPlayerFlags = 0)
		NET_PRINT("BROADCAST_CHARACTER_STAT_DATA_QUERY_INT") NET_NL()
		NET_PRINT_STRINGS(GET_THIS_SCRIPT_NAME()," BROADCAST_CHARACTER_STAT_DATA_QUERY_INT has been called") NET_NL()
		NET_NL()
			NET_PRINT_STRING_INT("BROADCAST_CHARACTER_STAT_DATA_QUERY_INT iRequestID: ",iRequestID) NET_NL()
			NET_PRINT_STRING_INT("BROADCAST_CHARACTER_STAT_DATA_QUERY_INT iMPIntStat: ",iMPIntStat) NET_NL()
		NET_NL()
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CHARACTER_STAT_DATA_QUERY_INT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//PURPOSE: Broadcast for all player to let them know when someone requested a stat
PROC BROADCAST_CHARACTER_STAT_DATA_QUERY_FLOAT(INT iRequestID,INT iMPIntStat, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_CHARACTER_STAT_DATA_FLOAT Event
	Event.Details.Type = SCRIPT_EVENT_CHARACTER_STAT_DATA_QUERY_FLOAT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRequestID = iRequestID
	Event.iMPIntStat = iMPIntStat
	
	IF NOT (iPlayerFlags = 0)
		NET_PRINT("BROADCAST_CHARACTER_STAT_DATA_QUERY_FLOAT") NET_NL()
		NET_PRINT_STRINGS(GET_THIS_SCRIPT_NAME()," BROADCAST_CHARACTER_STAT_DATA_QUERY_FLOAT has been called") NET_NL()
		NET_NL()
			NET_PRINT_STRING_INT("BROADCAST_CHARACTER_STAT_DATA_QUERY_FLOAT iRequestID: ",iRequestID) NET_NL()
			NET_PRINT_STRING_INT("BROADCAST_CHARACTER_STAT_DATA_QUERY_FLOAT iMPIntStat: ",iMPIntStat) NET_NL()
		NET_NL()
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CHARACTER_STAT_DATA_QUERY_FLOAT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//PURPOSE: Broadcast for all player to let them know when someone requested a stat
PROC BROADCAST_CHARACTER_STAT_DATA_QUERY_BOOL(INT iRequestID,INT iMPIntStat, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_CHARACTER_STAT_DATA_BOOL Event
	Event.Details.Type = SCRIPT_EVENT_CHARACTER_STAT_DATA_QUERY_BOOL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRequestID = iRequestID
	Event.iMPIntStat = iMPIntStat
	
	IF NOT (iPlayerFlags = 0)
		NET_PRINT("BROADCAST_CHARACTER_STAT_DATA_QUERY_BOOL") NET_NL()
		NET_PRINT_STRINGS(GET_THIS_SCRIPT_NAME()," BROADCAST_CHARACTER_STAT_DATA_QUERY_BOOL has been called") NET_NL()
		NET_NL()
			NET_PRINT_STRING_INT("BROADCAST_CHARACTER_STAT_DATA_QUERY_BOOL iRequestID: ",iRequestID) NET_NL()
			NET_PRINT_STRING_INT("BROADCAST_CHARACTER_STAT_DATA_QUERY_BOOL iMPIntStat: ",iMPIntStat) NET_NL()
		NET_NL()
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CHARACTER_STAT_DATA_QUERY_BOOL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC


//PURPOSE: Broadcast to specific player to give them information they requested about a stat
PROC BROADCAST_CHARACTER_STAT_DATA_SEND_INT(INT iRequestID,INT iMPIntStat,INT iValue, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_CHARACTER_STAT_DATA_INT Event
	Event.Details.Type = SCRIPT_EVENT_CHARACTER_STAT_DATA_SEND_INT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRequestID = iRequestID
	Event.iMPIntStat = iMPIntStat
	Event.iValue = iValue
	
	IF NOT (iPlayerFlags = 0)
		NET_PRINT("BROADCAST_CHARACTER_STAT_DATA_SEND_INT") NET_NL()
		NET_PRINT_STRINGS(GET_THIS_SCRIPT_NAME()," BROADCAST_CHARACTER_STAT_DATA_SEND_INT has been called") NET_NL()
		NET_NL()
			NET_PRINT_STRING_INT("BROADCAST_CHARACTER_STAT_DATA_SEND_INT iRequestID: ",iRequestID) NET_NL()
			NET_PRINT_STRING_INT("BROADCAST_CHARACTER_STAT_DATA_SEND_INT iMPIntStat: ",iMPIntStat) NET_NL()
			NET_PRINT_STRING_INT("BROADCAST_CHARACTER_STAT_DATA_SEND_INT iValue: ",iValue) NET_NL()
		NET_NL()
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CHARACTER_STAT_DATA_SEND_INT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//PURPOSE: Broadcast to specific player to give them information they requested about a stat
PROC BROADCAST_CHARACTER_STAT_DATA_SEND_FLOAT(INT iRequestID,INT iMPIntStat,FLOAT fValue, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_CHARACTER_STAT_DATA_FLOAT Event
	Event.Details.Type = SCRIPT_EVENT_CHARACTER_STAT_DATA_SEND_FLOAT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRequestID = iRequestID
	Event.iMPIntStat = iMPIntStat
	Event.fValue = fValue
	
	IF NOT (iPlayerFlags = 0)
		NET_PRINT("BROADCAST_STAT_CHARACTER_DATA_SEND_FLOAT") NET_NL()
		NET_PRINT_STRINGS(GET_THIS_SCRIPT_NAME()," BROADCAST_CHARACTER_STAT_DATA_SEND_FLOAT has been called") NET_NL()
		NET_NL()
			NET_PRINT_STRING_INT("BROADCAST_CHARACTER_STAT_DATA_SEND_FLOAT iRequestID: ",iRequestID) NET_NL()
			NET_PRINT_STRING_INT("BROADCAST_CHARACTER_STAT_DATA_SEND_FLOAT iMPIntStat: ",iMPIntStat) NET_NL()
			NET_PRINT_STRING_FLOAT("BROADCAST_CHARACTER_STAT_DATA_SEND_FLOAT fValue: ",fValue) NET_NL()
		NET_NL()	
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CHARACTER_STAT_DATA_SEND_FLOAT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//PURPOSE: Broadcast to specific player to give them information they requested about a stat
PROC BROADCAST_CHARACTER_STAT_DATA_SEND_BOOL(INT iRequestID,INT iMPIntStat,BOOL bValue, INT iPlayerFlags)
	SCRIPT_EVENT_DATA_CHARACTER_STAT_DATA_BOOL Event
	Event.Details.Type = SCRIPT_EVENT_CHARACTER_STAT_DATA_SEND_BOOL
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRequestID = iRequestID
	Event.iMPIntStat = iMPIntStat
	Event.bValue = bValue
	
	IF NOT (iPlayerFlags = 0)
		NET_PRINT("BROADCAST_CHARACTER_STAT_DATA_SEND_BOOL") NET_NL()
		NET_PRINT_STRINGS(GET_THIS_SCRIPT_NAME()," BROADCAST_CHARACTER_STAT_DATA_SEND_BOOL has been called") NET_NL()
		NET_NL()
			NET_PRINT_STRING_INT("BROADCAST_CHARACTER_STAT_DATA_SEND_BOOL iRequestID: ",iRequestID) NET_NL()
			NET_PRINT_STRING_INT("BROADCAST_CHARACTER_STAT_DATA_SEND_BOOL iMPIntStat: ",iMPIntStat) NET_NL()
			NET_PRINT("BROADCAST_CHARACTER_STAT_DATA_SEND_BOOL bValue: ")
			NET_PRINT_BOOL(bValue) NET_NL()
		NET_NL()
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CHARACTER_STAT_DATA_SEND_BOOL - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

// ===========================================================================================================
//      Next Mission Broadcasts
//		Can be used to inform the game of the next expected mission that will be chosen by the timed launcher
// ===========================================================================================================

// -----------------------------------------------------------------------------------------------------------
//      Event: Next Expected Cop Mission
// -----------------------------------------------------------------------------------------------------------

STRUCT m_structEventNextExpectedCopMission
	STRUCT_EVENT_COMMON_DETAILS	Details					// Common Event details
	MP_MISSION					mission					// The next expected cop mission
ENDSTRUCT


// -----------------------------------------------------------------------------------------------------------

// PURPOSE: Broadcast the next expected cop mission
//
// INPUT PARAMS:			paramMission				// The mission
//
// NOTES:	This request is always intended for the CnC Host to store as CnC server broadcast data (it is sent from the Cop Amb Launcher Host)
PROC Broadcast_Next_Expected_Cop_Mission(MP_MISSION paramMission)

	// Store the Broadcast data
	m_structEventNextExpectedCopMission Event
	
	Event.Details.Type				= SCRIPT_EVENT_NEXT_EXPECTED_COP_MISSION
	Event.Details.FromPlayerIndex	= PLAYER_ID()
	
	Event.mission					= paramMission
	
	// Broadcast the event to a MISSION CONTROL HOST
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
	
	#IF IS_DEBUG_BUILD
		NET_PRINT("...........Broadcasting SCRIPT_EVENT_NEXT_EXPECTED_COP_MISSION: ")
		NET_PRINT(GET_MP_MISSION_NAME(paramMission))
		NET_NL()
	#ENDIF
	
ENDPROC

#IF IS_DEBUG_BUILD
STRUCT SCRIPT_EVENT_DATA_SOLD_DRUGS
	STRUCT_EVENT_COMMON_DETAILS Details 
	INT iDrugType
	FLOAT fQuantitySold
	INT iCashGained
	INT iXPGained
ENDSTRUCT

PROC BROADCAST_PLAYER_SOLD_DRUGS(INT iDrugSold, FLOAT fQuantity, INT iCash, INT iXP, PLAYER_INDEX PlayerID)
	SCRIPT_EVENT_DATA_SOLD_DRUGS Event
	Event.Details.Type = SCRIPT_EVENT_SOLD_DRUGS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iDrugType = iDrugSold
	Event.fQuantitySold = fQuantity
	Event.iCashGained = iCash
	Event.iXPGained = iXP
//	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(PlayerID))	
//	ELSE
//		NET_PRINT("BROADCAST_START_NPC_CHASE - playerflags = 0 so not broadcasting") NET_NL()		
//	ENDIF	
ENDPROC
#ENDIF

STRUCT SCRIPT_EVENT_FM_PLAYER_REQUEST_NPC_INVITE 
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

STRUCT SCRIPT_EVENT_FM_TRIGGER_TUT 
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPlayersToGoOnTut
	BOOL bOnlyPlayerOnRace
	INT iTutInstance
ENDSTRUCT

STRUCT SCRIPT_EVENT_FM_TRIGGER_DM_TUT 
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPlayersToGoOnDm
	BOOL bOnePlayerBail
	INT iTutInstance
ENDSTRUCT

STRUCT SCRIPT_EVENT_FM_PLAYER_START_TRIGGER_TUT 
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

STRUCT SCRIPT_EVENT_FM_PLAYER_START_TRIGGER_DM_TUT 
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

STRUCT SCRIPT_EVENT_FM_PLAYER_READY_HOLDUP_TUT 
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iFrameCount
ENDSTRUCT

STRUCT SCRIPT_EVENT_FM_LAUNCH_HOLD_UP_TUT 
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Control stealing personal vehicle																	
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_PLAYER_STOLEN_PERSONAL_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX otherPlayer
ENDSTRUCT

PROC BROADCAST_PLAYER_STOLEN_PERSONAL_VEHICLE(PLAYER_INDEX otherPlayer)
	SCRIPT_EVENT_PLAYER_STOLEN_PERSONAL_VEHICLE Event
	event.Details.Type 				= SCRIPT_EVENT_PERSONAL_VEHICLE_STOLEN
	Event.details.FromPlayerIndex 	= PLAYER_ID()
	Event.otherPlayer 				= otherPlayer
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║						  Arm wrestling minigame messages
//╚═════════════════════════════════════════════════════════════════════════════╝

// Controls ambient scoreboard for players not involved in the current match
STRUCT SCRIPT_EVENT_DATA_ARM_WRESTLE_UPDATE
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX otherPlayer
	INT iWins // bits 0-14 away; 15-29 home
	INT iFlags // bit 0 active; bits 1-31 team
ENDSTRUCT

// Wrestlers negotiate to choose the most convenient side of the table
STRUCT SCRIPT_EVENT_DATA_ARM_WRESTLE_TABLE_POSITIONS
	STRUCT_EVENT_COMMON_DETAILS Details
	FLOAT fMyDesireLevel
ENDSTRUCT

// Score buckets are being collected and emptied
STRUCT SCRIPT_EVENT_DATA_ARM_WRESTLE_BUCKET_COLLECTION
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iBitField
ENDSTRUCT

// Let other players know we are activating the arm wrestling table
PROC BROADCAST_ARM_WRESTLE_TABLE_ACTIVATE(PLAYER_INDEX myIndex, BOOL bActivated, BOOL bApartments = FALSE)
	SCRIPT_EVENT_DATA_ARM_WRESTLE_UPDATE Event
	Event.Details.Type = SCRIPT_EVENT_ARM_WRESTLE_TABLE_ACTIVATE
	Event.Details.FromPlayerIndex = myIndex
	IF bActivated
		SET_BIT(Event.iFlags, 3)
	ELSE
		CLEAR_BIT(Event.iFlags, 3)
	ENDIF
	
	IF NOT bApartments
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
	ELSE
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS_ON_SCRIPT())
	ENDIF
ENDPROC

// Update number of wins (for scoreboard)
PROC BROADCAST_ARM_WRESTLE_UPDATE(PLAYER_INDEX myIndex, PLAYER_INDEX otherPlayer, INT iAwayWins, INT iHomeWins, INT iGang, BOOL bActive, BOOL bApartments = FALSE)
	SCRIPT_EVENT_DATA_ARM_WRESTLE_UPDATE Event
	Event.Details.Type = SCRIPT_EVENT_ARM_WRESTLE_UPDATE
	Event.Details.FromPlayerIndex = myIndex
	Event.otherPlayer = otherPlayer
	Event.iWins = (iAwayWins & 32767) + SHIFT_LEFT(iHomeWins & 32767, 15)
	Event.iFlags = SHIFT_LEFT(iGang, 1)
	IF bActive
		SET_BIT(Event.iFlags, 0)
	ENDIF
	
	IF NOT bApartments
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
	ELSE
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS_ON_SCRIPT())
	ENDIF
ENDPROC

// Clear/reset data to turn off scoreboard
PROC BROADCAST_ARM_WRESTLE_CLEAR(PLAYER_INDEX myIndex, INT iGang, BOOL bApartments = FALSE)
	SCRIPT_EVENT_DATA_ARM_WRESTLE_UPDATE Event
	Event.Details.Type = SCRIPT_EVENT_ARM_WRESTLE_UPDATE
	Event.Details.FromPlayerIndex = myIndex
	Event.iFlags = SHIFT_LEFT(iGang, 1)
	
	IF NOT bApartments
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
	ELSE
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS_ON_SCRIPT())
	ENDIF
ENDPROC

// Let the other player know how much we prefer the home side of the table
PROC BROADCAST_ARM_WRESTLE_POSITIONS(FLOAT fPosPreferenceLevel, PLAYER_INDEX myIndex, PLAYER_INDEX otherPlayer)
	SCRIPT_EVENT_DATA_ARM_WRESTLE_TABLE_POSITIONS Event
	Event.Details.Type = SCRIPT_EVENT_ARM_WRESTLE_TABLE_POSITIONS
	Event.fMyDesireLevel = fPosPreferenceLevel
	Event.Details.FromPlayerIndex = myIndex
	#IF IS_DEBUG_BUILD
		PRINTLN("net_events.sch: Broadcasting am_armwrestling.sc fPosPreferenceLevel: ", fPosPreferenceLevel)
	#ENDIF
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(otherPlayer))
ENDPROC

// Let the other player know we have processed and cleared a number of score buckets
PROC BROADCAST_ARM_WRESTLE_BUCKET_COLLECTION(INT iBucketBits, PLAYER_INDEX otherPlayer)
	SCRIPT_EVENT_DATA_ARM_WRESTLE_BUCKET_COLLECTION Event
	Event.Details.Type = SCRIPT_EVENT_ARM_WRESTLE_BUCKET_COLLECTION
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iBitField = iBucketBits
	PRINTLN("net_events.sch: Broadcasting am_armwrestling.sc BROADCAST_ARM_WRESTLE_BUCKET_COLLECTION: ", iBucketBits)
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(otherPlayer))
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║						  Darts minigame messages
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_DARTS_UPDATE
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX otherPlayer
	INT iScore // bits 0-14 away; 15-29 home
	INT iFlags // bit 0 active; bit 1 is danger zone activate, bit 2 is danger zone deactivate, 
			   // bit 3 is for when the dart is thrown, bit 4 is when the dart hits the other player, 
			   // bit 5 is for enemy presence, bits 6-31 team
	INT iDangerPedCount 
ENDSTRUCT

ENUM DARTS_DANGER_ZONE_MONITOR
	DARTS_DANGERZONE_ACTIVATE,
	DARTS_DANGERZONE_DEACTIVATE,
	DARTS_DANGERZONE_DART_THROW,
	DARTS_DANGERZONE_CLEAR_DART_THROW
ENDENUM

PROC BROADCAST_DARTS_ENEMY_PRESENT(PLAYER_INDEX myIndex, BOOL bActive, BOOL bApartments = FALSE)
	SCRIPT_EVENT_DATA_DARTS_UPDATE Event
	Event.Details.Type = SCRIPT_EVENT_DARTS_ENEMY_PRESENT
	Event.Details.FromPlayerIndex = myIndex
	
	IF bActive
		SET_BIT(Event.iFlags, 5)
		#IF IS_DEBUG_BUILD
			PRINTLN("Broadcasting Enemy presence to all players")
		#ENDIF
	ELSE
		CLEAR_BIT(Event.iFlags, 5)
		#IF IS_DEBUG_BUILD
			PRINTLN("Broadcasting lack of Enemy presence to all players")
		#ENDIF
	ENDIF
	
	IF NOT bApartments
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
	ELSE
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS_ON_SCRIPT())
	ENDIF
ENDPROC

PROC BROADCAST_DANGER_ZONE_UPDATE(PLAYER_INDEX myIndex, DARTS_DANGER_ZONE_MONITOR DangerZoneMonitor, BOOL bApartments = FALSE)
	SCRIPT_EVENT_DATA_DARTS_UPDATE Event
	Event.Details.Type = SCRIPT_EVENT_DARTS_DANGER_ZONE_UPDATE
	Event.Details.FromPlayerIndex = myIndex
	
	SWITCH DangerZoneMonitor
		CASE DARTS_DANGERZONE_ACTIVATE
			SET_BIT(Event.iFlags, 1)
			Event.iDangerPedCount = 1
			PRINTLN("Activating Danger zone for Darts")
		BREAK
		
		CASE DARTS_DANGERZONE_DEACTIVATE
			SET_BIT(Event.iFlags, 2)
			Event.iDangerPedCount = -1
			PRINTLN("Deactivating Danger zone for Darts")
		BREAK
		
		CASE DARTS_DANGERZONE_DART_THROW
			SET_BIT(Event.iFlags, 3)
			PRINTLN("Activating Danger Dart Throw")
		BREAK
		
		CASE DARTS_DANGERZONE_CLEAR_DART_THROW
			SET_BIT(Event.iFlags, 4)
			PRINTLN("Clearing Danger Dart Throw")
		BREAK
	ENDSWITCH
	
	IF NOT bApartments
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
	ELSE
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS_ON_SCRIPT())
	ENDIF
ENDPROC

PROC BROADCAST_DARTS_BOARD_ACTIVATE(PLAYER_INDEX myIndex, BOOL bActivated, BOOL bApartments = FALSE)
	SCRIPT_EVENT_DATA_DARTS_UPDATE Event
	Event.Details.Type = SCRIPT_EVENT_DARTS_BOARD_ACTIVATE
	Event.Details.FromPlayerIndex = myIndex
	IF bActivated
		SET_BIT(Event.iFlags, 3)
	ELSE
		CLEAR_BIT(Event.iFlags, 3)
	ENDIF
	PRINTLN("Setting board to active with floating help...")
	IF NOT bApartments
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
	ELSE
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS_ON_SCRIPT())
	ENDIF
ENDPROC

// TODO:  Implement this into actual Darts script so that the scores will be broadcasted
PROC BROADCAST_DARTS_UPDATE(PLAYER_INDEX myIndex, PLAYER_INDEX otherPlayer, INT iAwayScore, INT iHomeScore, INT iGang, BOOL bActive, BOOL bApartments = FALSE)
	SCRIPT_EVENT_DATA_DARTS_UPDATE Event
	Event.Details.Type = SCRIPT_EVENT_DARTS_UPDATE
	Event.Details.FromPlayerIndex = myIndex
	Event.otherPlayer = otherPlayer
	Event.iScore = (iAwayScore & 32767) + SHIFT_LEFT(iHomeScore & 32767, 15)
	Event.iFlags = SHIFT_LEFT(iGang, 1)
	IF bActive
		SET_BIT(Event.iFlags, 0)
	ENDIF
	PRINTLN("Attempting to send a darts update to all players...")
	IF NOT bApartments
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
	ELSE
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS_ON_SCRIPT())
	ENDIF
ENDPROC

PROC BROADCAST_DARTS_CLEAR(PLAYER_INDEX myIndex, INT iGang, BOOL bApartments = FALSE)
	SCRIPT_EVENT_DATA_DARTS_UPDATE Event
	Event.Details.Type = SCRIPT_EVENT_DARTS_UPDATE
	Event.Details.FromPlayerIndex = myIndex
	Event.iFlags = SHIFT_LEFT(iGang, 1)
	PRINTLN("Attempting to send a darts clear to all players...")
	IF NOT bApartments
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())
	ELSE
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS_ON_SCRIPT())
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							BROADCAST DRONE EMP									
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_DRONE_EMP
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vDroneCoord
	BOOL bPlayerDamagedByEmp
ENDSTRUCT

//Purpose: Syncs the current distance of the rollercoaster with the server
PROC BROADCAST_DRONE_EMP(VECTOR vDroneCoord, BOOL bCallBack = FALSE)
	SCRIPT_EVENT_DATA_DRONE_EMP Event
	Event.Details.Type 				= SCRIPT_EVENT_DRONE_EMP
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.vDroneCoord 				= vDroneCoord
	Event.bPlayerDamagedByEmp 		= bCallBack
	
	IF !bCallBack
		IF NOT (ALL_PLAYERS() = 0)
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
			PRINTLN("[AM_MP_DRONE] - BROADCAST_DRONE_EMP - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		ELSE
			NET_PRINT("[AM_MP_DRONE] - BROADCAST_DRONE_EMP - playerflags = 0 so not broadcasting") NET_NL()		
		ENDIF
	ELSE
		IF g_sDroneGlobals.playerUsedDroneEMP != INVALID_PLAYER_INDEX()
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(g_sDroneGlobals.playerUsedDroneEMP))
			PRINTLN("[AM_MP_DRONE] - BROADCAST_DRONE_EMP - SENT BY ", GET_PLAYER_NAME(g_sDroneGlobals.playerUsedDroneEMP)," at ",GET_CLOUD_TIME_AS_INT())
		ELSE
			NET_PRINT("[AM_MP_DRONE] - BROADCAST_DRONE_EMP - g_sDroneGlobals.playerUsedDroneEMP = -1 so not broadcasting") NET_NL()
		ENDIF
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_MBS_TRIGGER_PTFX
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iMissionEntity
	INT iUniqueMissionID
ENDSTRUCT

PROC BROADCAST_MBS_TRIGGER_PTFX_FROM_MISSION_ENTITY(INT iMissionEntity, INT iUniqueMissionID)
	SCRIPT_EVENT_DATA_MBS_TRIGGER_PTFX Event
	Event.Details.Type = SCRIPT_EVENT_MBS_TRIGGER_PTFX
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iMissionEntity = iMissionEntity
	Event.iUniqueMissionID = iUniqueMissionID
	
	IF NOT (ALL_PLAYERS_ON_SCRIPT() = 0)
		PRINTLN("[MB_MISSION] - BROADCAST_MBS_TRIGGER_PTFX_FROM_MISSION_ENTITY - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		PRINTLN("[MB_MISSION] - BROADCAST_MBS_TRIGGER_PTFX_FROM_MISSION_ENTITY - Event.iMissionEntity = ", Event.iMissionEntity)
		PRINTLN("[MB_MISSION] - BROADCAST_MBS_TRIGGER_PTFX_FROM_MISSION_ENTITY - Event.iUniqueMissionID = ", Event.iUniqueMissionID)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS_ON_SCRIPT())	
	ELSE
		NET_PRINT("[MB_MISSION] - BROADCAST_MBS_TRIGGER_PTFX_FROM_MISSION_ENTITY - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_MBS_PRINT_DELIVERY_TICKER
	STRUCT_EVENT_COMMON_DETAILS Details
	MEGA_BUSINESS_MISSION_VARIATION eVariation1
	INT iMissionID
	PLAYER_INDEX piDeliverer
ENDSTRUCT

PROC BROADCAST_MBS_PRINT_DELIVERY_TICKER(PLAYER_INDEX piDeliverer, MEGA_BUSINESS_MISSION_VARIATION eVariation1, INT iMissionID)
	SCRIPT_EVENT_DATA_MBS_PRINT_DELIVERY_TICKER Event
	Event.Details.Type = SCRIPT_EVENT_MBS_PRINT_DELIVERY_TICKER
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.eVariation1 = eVariation1
	Event.iMissionID = iMissionID
	Event.piDeliverer = piDeliverer
	
	IF NOT (ALL_PLAYERS() = 0)
		PRINTLN("[MB_MISSION] - BROADCAST_MBS_PRINT_DELIVERY_TICKER - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
	ELSE
		NET_PRINT("[MB_MISSION] - BROADCAST_MBS_PRINT_DELIVERY_TICKER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

#IF FEATURE_CASINO

STRUCT SCRIPT_EVENT_DATA_CASINO_FM_MISSION_CHIPS_RECOVERED
	STRUCT_EVENT_COMMON_DETAILS Details
	GBC_VARIATION eVariation1
	INT iMissionID
	PLAYER_INDEX piPlayerRecovered
	INT iThief = -1
ENDSTRUCT

PROC BROADCAST_CASINO_FM_MISSION_CHIPS_RECOVERED(PLAYER_INDEX piPlayerRecovered, INT iThief, GBC_VARIATION eVariation1, INT iMissionID)
	SCRIPT_EVENT_DATA_CASINO_FM_MISSION_CHIPS_RECOVERED Event
	Event.Details.Type = SCRIPT_EVENT_CASINO_FM_MISSION_CHIPS_RECOVERED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.eVariation1 = eVariation1
	Event.iMissionID = iMissionID
	Event.piPlayerRecovered = piPlayerRecovered
	Event.iThief = iThief
	
	IF NOT (ALL_PLAYERS() = 0)
		PRINTLN("[GB_CASINO] - BROADCAST_CASINO_FM_MISSION_CHIPS_RECOVERED - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
	ELSE
		NET_PRINT("[GB_CASINO] - BROADCAST_CASINO_FM_MISSION_CHIPS_RECOVERED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC
#ENDIF

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Nightclub Ped Speech events								
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_NIGHTCLUB_PEDS_SPEECH_UPDATE
	STRUCT_EVENT_COMMON_DETAILS Details
	NC_PED_SPEECH_ENUM eNC_PedSpeech
	BOOL bCashierPed = FALSE
ENDSTRUCT

//PURPOSE: 
PROC BROADCAST_NIGHTCLUB_PEDS_SPEECH_DATA(PLAYER_INDEX piNightclubOwner, NC_PED_SPEECH_ENUM eNC_PedSpeech, BOOL bCashierPed = FALSE)
	
	//Common data
	SCRIPT_EVENT_DATA_NIGHTCLUB_PEDS_SPEECH_UPDATE Event
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_NIGHTCLUB_PEDS_SPEECH
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bCashierPed				= bCashierPed
	
	//Nightclub ped speech data
	Event.eNC_PedSpeech = eNC_PedSpeech
	
	INT i, iPlayerFlags = 0
	
	REPEAT NUM_NETWORK_PLAYERS i
		PLAYER_INDEX piPlayer = INT_TO_NATIVE(PLAYER_INDEX, i)
		
		IF IS_NET_PLAYER_OK(piPlayer)
		AND GlobalPlayerBD[i].SimpleInteriorBD.propertyOwner = piNightclubOwner
		AND GET_INTERIOR_FLOOR_INDEX_FOR_PLAYER(piPlayer) = ciBUSINESS_HUB_FLOOR_NIGHTCLUB  
			SET_BIT(iPlayerFlags, i)
		ENDIF
	ENDREPEAT
	
	IF NOT (iPlayerFlags = 0)
		CPRINTLN(DEBUG_NET_PED_DANCING, "BROADCAST_NIGHTCLUB_PEDS_SPEECH_DATA - NC_PED_SPEECH_", ENUM_TO_INT(eNC_PedSpeech), " sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT(), " bCashierPed = ", bCashierPed)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_NIGHTCLUB_PEDS_SPEECH_DATA - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Casino Ped Speech events								
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_CASINO_PEDS_SPEECH_UPDATE
	STRUCT_EVENT_COMMON_DETAILS Details
	CASINO_PED_SPEECH_ENUM eCasinoPedSpeech
	TEXT_LABEL_63 tl63CasinoPedContext
	INT iPedID = 0
	INT iAssignedArea
ENDSTRUCT

//PURPOSE: 
PROC BROADCAST_CASINO_PEDS_SPEECH_DATA(CASINO_PED_SPEECH_ENUM eSpeech, STRING sContext, INT iPedID, INT iAssignedArea)
	
	//Common data
	SCRIPT_EVENT_DATA_CASINO_PEDS_SPEECH_UPDATE Event
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_CASINO_PEDS_SPEECH
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iPedID					= iPedID
	Event.iAssignedArea				= iAssignedArea
	
	//Casino ped speech data
	Event.eCasinoPedSpeech			= eSpeech
	Event.tl63CasinoPedContext		= sContext
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host
	
	IF NOT (iPlayerFlags = 0)
		CPRINTLN(DEBUG_NET_PED_DANCING, "BROADCAST_CASINO_PEDS_SPEECH_DATA - CASINO_SPEECH_", ENUM_TO_INT(eSpeech), ", sContext: ",sContext," iAssignedArea:", ENUM_TO_INT(iAssignedArea), " sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT(), " iPedID = ", iPedID)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_CASINO_PEDS_SPEECH_DATA - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Casino Nightclub Ped events								
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_CASINO_NIGHTCLUB_PEDS_EVENT_UPDATE
	STRUCT_EVENT_COMMON_DETAILS Details
	CASINO_CLUB_PED_SPEECH_ENUM eNC_PedSpeech
	CASINO_CLUB_PED_FOR_EVENT ePed
	CASINO_CLUB_SCRIPT_PED_EVENT eEventType
ENDSTRUCT

//PURPOSE: 
PROC BROADCAST_CASINO_NIGHTCLUB_PED_EVENT(CASINO_CLUB_PED_FOR_EVENT ePed, CASINO_CLUB_PED_SPEECH_ENUM eNC_PedSpeech = CCP_SPEECH_END, CASINO_CLUB_SCRIPT_PED_EVENT eEventType = CC_PED_EVENT_SPEECH)
	
	//Common data
	SCRIPT_EVENT_DATA_CASINO_NIGHTCLUB_PEDS_EVENT_UPDATE Event
	Event.Details.Type 				= SCRIPT_EVENT_PROCESS_CASINO_NIGHTCLUB_PEDS_EVENT
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	
	//Casino Nightclub ped event data
	Event.eNC_PedSpeech = eNC_PedSpeech
	Event.eEventType	= eEventType
	Event.ePed			= ePed
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE, FALSE)
	
	IF NOT (iPlayerFlags = 0)
		CPRINTLN(DEBUG_NET_PED_DANCING, "BROADCAST_CASINO_NIGHTCLUB_PED_EVENT - NC_PED_SPEECH_", ENUM_TO_INT(eNC_PedSpeech), " sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT(), " ePed = ", ePed)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_CASINO_NIGHTCLUB_PED_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Arcade Ped Speech events								
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_ARCADE_PEDS_SPEECH_UPDATE
	STRUCT_EVENT_COMMON_DETAILS Details
	PED_SPEECH_TYPE eSpeech
	INT iPed = 0
ENDSTRUCT

//PURPOSE: 
PROC BROADCAST_ARCADE_PEDS_SPEECH_DATA(PED_SPEECH_TYPE eSpeech, INT iPed)
	
	//Common data
	SCRIPT_EVENT_DATA_ARCADE_PEDS_SPEECH_UPDATE Event
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_ARCADE_PEDS_SPEECH
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.eSpeech					= eSpeech
	Event.iPed						= iPed
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT() // any player could be the host
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_ARCADE_PEDS_SPEECH_DATA - Ped ID: ", iPed, " Speech: ", ENUM_TO_INT(eSpeech), " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_ARCADE_PEDS_SPEECH_DATA - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║						Arcade Fortune Teller Anim Events							
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_ARCADE_FORTUNE_TELLER_ANIM_UPDATE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bFemalePlayer
	INT iPreSpeech
	INT iFortune
	INT iDisplaySlot
ENDSTRUCT

//PURPOSE: 
PROC BROADCAST_ARCADE_FORTUNE_TELLER_DATA(INT iFortune, INT iPreSpeech, INT iDisplaySlot, BOOL bFemalePlayer)
	
	//Common data
	SCRIPT_EVENT_DATA_ARCADE_FORTUNE_TELLER_ANIM_UPDATE Event
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_ARCADE_FORTUNE_TELLER_ANIMS
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bFemalePlayer				= bFemalePlayer
	Event.iPreSpeech				= iPreSpeech
	Event.iFortune					= iFortune
	Event.iDisplaySlot				= iDisplaySlot
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_ARCADE_FORTUNE_TELLER_DATA - Fortune: ", iFortune, " Pre Speech: ", iPreSpeech, " Display Slot: ", iDisplaySlot, " Female Ped: ", bFemalePlayer, " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_ARCADE_PEDS_SPEECH_DATA - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Arcade Lester Fortune Teller Door Anim Events							
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_ARCADE_LESTER_FORTUNE_TELLER_DOOR_ANIM_UPDATE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iFortuneDoorSpeech
	INT iFortuneDoorAnim
	BOOL bFemalePed
	BOOL bFromBasement
ENDSTRUCT

//PURPOSE: 
PROC BROADCAST_ARCADE_LESTER_FORTUNE_TELLER_DOOR_DATA(BOOL bFemalePed, INT iFortuneDoorAnim, INT iFortuneDoorSpeech, BOOL bFromBasement)
	
	//Common data
	SCRIPT_EVENT_DATA_ARCADE_LESTER_FORTUNE_TELLER_DOOR_ANIM_UPDATE Event
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_ARCADE_LESTER_FORTUNE_TELLER_DOOR_ANIMS
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iFortuneDoorAnim 			= iFortuneDoorAnim
	Event.iFortuneDoorSpeech 		= iFortuneDoorSpeech
	Event.bFemalePed 				= bFemalePed
	Event.bFromBasement 			= bFromBasement
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_ARCADE_LESTER_FORTUNE_TELLER_DOOR_DATA - Door Anim: ", iFortuneDoorAnim, " Fortune Door Speech: ", iFortuneDoorSpeech, " Female: ", bFemalePed, " From Basement: ", bFromBasement, " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		NET_PRINT("BROADCAST_ARCADE_LESTER_FORTUNE_TELLER_DOOR_DATA - playerflags = 0 so not broadcasting") NET_NL()
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Ped Events								
//╚═════════════════════════════════════════════════════════════════════════════╝

#IF FEATURE_HEIST_ISLAND
STRUCT SCRIPT_EVENT_DATA_PED_SPEECH_UPDATE
	STRUCT_EVENT_COMMON_DETAILS Details
	PED_SPEECH ePedSpeech
	INT iPed = 0
ENDSTRUCT

PROC BROADCAST_PED_SPEECH_DATA(INT iPed, PED_SPEECH ePedSpeech, BOOL bBroadcastToAllPlayers = TRUE)
	
	INT iPlayerFlags = SPECIFIC_PLAYER(PLAYER_ID())
	
	IF (bBroadcastToAllPlayers)
		iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	ENDIF
	
	IF (iPlayerFlags = 0)
		PRINTLN("[AM_MP_PEDS] BROADCAST_PED_SPEECH_DATA - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_PED_SPEECH_UPDATE Event
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_PED_SPEECH
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.ePedSpeech				= ePedSpeech
	Event.iPed						= iPed
	
	PRINTLN("[AM_MP_PEDS] BROADCAST_PED_SPEECH_DATA - Ped ID: ", iPed, " Speech: ", ENUM_TO_INT(ePedSpeech), " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_SET_MAX_LOCAL_PEDS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iMaxLocalPeds = 0
	BOOL bDebugPedLocation = FALSE
ENDSTRUCT

PROC BROADCAST_PED_EVENT_SET_MAX_LOCAL_PEDS(INT iMaxLocalPeds, BOOL bDebugPedLocation = FALSE)
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE)
	
	IF (iPlayerFlags = 0)
		PRINTLN("[AM_MP_PEDS] BROADCAST_PED_EVENT_SET_MAX_LOCAL_PEDS - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_SET_MAX_LOCAL_PEDS Event
	Event.Details.Type 				= SCRIPT_EVENT_SET_MAX_LOCAL_PEDS
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iMaxLocalPeds				= iMaxLocalPeds
	Event.bDebugPedLocation			= bDebugPedLocation
	
	PRINTLN("[AM_MP_PEDS] BROADCAST_PED_EVENT_SET_MAX_LOCAL_PEDS - Max Local Peds: ", iMaxLocalPeds, " Debug Ped Location: ", bDebugPedLocation, " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	
ENDPROC
#ENDIF	// FEATURE_HEIST_ISLAND

STRUCT SCRIPT_EVENT_DATA_PED_FADE_OUT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPed = 0
ENDSTRUCT

PROC BROADCAST_PED_FADE_OUT(INT iPed)
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE)
	
	IF (iPlayerFlags = 0)
		PRINTLN("[AM_MP_PEDS] BROADCAST_PED_FADE_OUT - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_PED_FADE_OUT Event
	Event.Details.Type 				= SCRIPT_EVENT_SET_PED_FADE_OUT
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iPed						= iPed
	
	PRINTLN("[AM_MP_PEDS] BROADCAST_PED_FADE_OUT - Ped ID: ", iPed, " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	
ENDPROC

PROC BROADCAST_PED_FADE_OUT_FOR_OTHER_PLAYERS(INT iPed)
	
	INT iPlayerFlags = ALL_PLAYERS(FALSE, TRUE)
	
	IF (iPlayerFlags = 0)
		PRINTLN("[AM_MP_PEDS] BROADCAST_PED_FADE_OUT_FOR_OTHER_PLAYERS - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_PED_FADE_OUT Event
	Event.Details.Type 				= SCRIPT_EVENT_SET_PED_FADE_OUT
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iPed						= iPed
	
	PRINTLN("[AM_MP_PEDS] BROADCAST_PED_FADE_OUT_FOR_OTHER_PLAYERS - Ped ID: ", iPed, " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_PED_CUSTOM_UPDATE_ACTION
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPed = 0
ENDSTRUCT

PROC BROADCAST_LAUNCH_CUSTOM_PED_UPDATE_ACTION(INT iPed)
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE)
	
	IF (iPlayerFlags = 0)
		PRINTLN("[AM_MP_PEDS] BROADCAST_PED_FADE_OUT - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_PED_CUSTOM_UPDATE_ACTION Event
	Event.Details.Type 				= SCRIPT_EVENT_LAUNCH_CUSTOM_PED_UPDATE_ACTION
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iPed						= iPed
	PRINTLN("[AM_MP_PEDS] BROADCAST_LAUNCH_CUSTOM_PED_UPDATE_ACTION - Ped ID: ", iPed, " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	
ENDPROC

PROC BROADCAST_LAUNCH_CUSTOM_PED_UPDATE_FOR_PLAYER(INT iPed, PLAYER_INDEX playerID)
	
	
	IF (playerID = INVALID_PLAYER_INDEX())
		PRINTLN("[AM_MP_PEDS] BROADCAST_PED_FADE_OUT - playerID = INVALID_PLAYER_INDEX() so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_PED_CUSTOM_UPDATE_ACTION Event
	Event.Details.Type 				= SCRIPT_EVENT_LAUNCH_CUSTOM_PED_UPDATE_ACTION
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iPed						= iPed
	PRINTLN("[AM_MP_PEDS] BROADCAST_LAUNCH_CUSTOM_PED_UPDATE_ACTION - Ped ID: ", iPed, " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(playerID))
	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Axe of Fury events								
//╚═════════════════════════════════════════════════════════════════════════════╝

#IF FEATURE_SUMMER_2020
STRUCT SCRIPT_EVENT_DATA_STRENGTH_TEST_SET_COUNTDOWN_TIMER
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_STRENGTH_TEST_EVENT_SET_COUNTDOWN_TIMER()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_SET_COUNTDOWN_TIMER - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_STRENGTH_TEST_SET_COUNTDOWN_TIMER countdownEvent
	countdownEvent.Details.Type 				= SCRIPT_EVENT_STRENGTH_TEST_SET_COUNTDOWN_TIMER
	countdownEvent.Details.FromPlayerIndex 		= PLAYER_ID()
	
	PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_SET_COUNTDOWN_TIMER - Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, countdownEvent, SIZE_OF(countdownEvent), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_STRENGTH_TEST_START_COUNTDOWN_TIMER
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_STRENGTH_TEST_EVENT_START_COUNTDOWN_TIMER()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_START_COUNTDOWN_TIMER - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_STRENGTH_TEST_START_COUNTDOWN_TIMER countdownEvent
	countdownEvent.Details.Type 				= SCRIPT_EVENT_STRENGTH_TEST_START_COUNTDOWN_TIMER
	countdownEvent.Details.FromPlayerIndex 		= PLAYER_ID()
	
	PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_START_COUNTDOWN_TIMER - Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, countdownEvent, SIZE_OF(countdownEvent), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_STRENGTH_TEST_REQUEST_HIGHSCORE
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

/// PURPOSE: Requests the highscore from the host of AM_MP_ARCADE.sc
PROC BROADCAST_STRENGTH_TEST_EVENT_REQUEST_HIGHSCORE()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_REQUEST_HIGHSCORE - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_STRENGTH_TEST_REQUEST_HIGHSCORE requestHighscoreEvent
	requestHighscoreEvent.Details.Type 				= SCRIPT_EVENT_STRENGTH_TEST_REQUEST_HIGHSCORE
	requestHighscoreEvent.Details.FromPlayerIndex 	= PLAYER_ID()
	
	PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_REQUEST_HIGHSCORE - Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, requestHighscoreEvent, SIZE_OF(requestHighscoreEvent), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_STRENGTH_TEST_SEND_HIGHSCORE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iHighscore
	BOOL bValidateHighscore = FALSE
ENDSTRUCT

/// PURPOSE: Sends the server BD highscore to those who requested it.
PROC BROADCAST_STRENGTH_TEST_EVENT_SEND_HIGHSCORE(INT iHighscore, PLAYER_INDEX playerID, BOOL bSendToAll = FALSE)
	
	SCRIPT_EVENT_DATA_STRENGTH_TEST_SEND_HIGHSCORE sendHighscoreEvent
	sendHighscoreEvent.Details.Type 				= SCRIPT_EVENT_STRENGTH_TEST_SEND_HIGHSCORE
	sendHighscoreEvent.Details.FromPlayerIndex 		= PLAYER_ID()
	sendHighscoreEvent.iHighscore					= iHighscore
	
	IF (bSendToAll)
		INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
		IF (iPlayerFlags = 0)
			PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_SEND_HIGHSCORE - playerflags = 0 so not broadcasting")
			EXIT
		ENDIF
		
		sendHighscoreEvent.bValidateHighscore = TRUE
		
		PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_SEND_HIGHSCORE - Highscore: ", iHighscore, " bSendToAll: TRUE Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, sendHighscoreEvent, SIZE_OF(sendHighscoreEvent), iPlayerFlags)
	ELSE
		IF (playerID = INVALID_PLAYER_INDEX())
			PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_SEND_HIGHSCORE - playerID is invalid so not broadcasting.")
			EXIT
		ENDIF
	
		PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_SEND_HIGHSCORE - Highscore: ", iHighscore, " bSendToAll: FALSE Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, sendHighscoreEvent, SIZE_OF(sendHighscoreEvent), SPECIFIC_PLAYER(playerID))
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_STRENGTH_TEST_VALIDATE_HIGHSCORE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iHighscore
ENDSTRUCT

/// PURPOSE: Sends an event to the host of AM_MP_aRCADE.sc with the latest highscore to validate.
PROC BROADCAST_STRENGTH_TEST_EVENT_VALIDATE_HIGHSCORE(INT iHighscore)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_VALIDATE_HIGHSCORE - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_STRENGTH_TEST_VALIDATE_HIGHSCORE validateHighscoreEvent
	validateHighscoreEvent.Details.Type 			= SCRIPT_EVENT_STRENGTH_TEST_VALIDATE_HIGHSCORE
	validateHighscoreEvent.Details.FromPlayerIndex 	= PLAYER_ID()
	validateHighscoreEvent.iHighscore				= iHighscore
	
	PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_VALIDATE_HIGHSCORE - Highscore: ", iHighscore, " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, validateHighscoreEvent, SIZE_OF(validateHighscoreEvent), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_STRENGTH_TEST_SET_HIGHSCORE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iHighScore
ENDSTRUCT

/// PURPOSE: Updates the headboard scaleform movie
PROC BROADCAST_STRENGTH_TEST_EVENT_SET_HIGHSCORE(INT iHighScore)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_SET_HIGHSCORE - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_STRENGTH_TEST_SET_HIGHSCORE highscoreEvent
	highscoreEvent.Details.Type 				= SCRIPT_EVENT_STRENGTH_TEST_SET_HIGHSCORE
	highscoreEvent.Details.FromPlayerIndex 		= PLAYER_ID()
	highscoreEvent.iHighScore					= iHighScore
	
	PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_SET_HIGHSCORE - Highscore: ", iHighScore, " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, highscoreEvent, SIZE_OF(highscoreEvent), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_STRENGTH_TEST_PERFORM_SCORE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iScore
	FLOAT fHoldTimeSecs
	FLOAT fCountUpTimeSecs
	FLOAT fCountDownTimeSecs
ENDSTRUCT

/// PURPOSE: Performs the score shooting up the neck of the arcade machine prop
PROC BROADCAST_STRENGTH_TEST_EVENT_PERFORM_SCORE(INT iScore, FLOAT fCountUpTimeSecs, FLOAT fHoldTimeSecs, FLOAT fCountDownTimeSecs)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_PERFORM_SCORE_EVENT - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_STRENGTH_TEST_PERFORM_SCORE scoreEvent
	scoreEvent.Details.Type 				= SCRIPT_EVENT_STRENGTH_TEST_PERFORM_SCORE
	scoreEvent.Details.FromPlayerIndex 		= PLAYER_ID()
	scoreEvent.iScore						= iScore
	scoreEvent.fHoldTimeSecs				= fHoldTimeSecs
	scoreEvent.fCountUpTimeSecs				= fCountUpTimeSecs
	scoreEvent.fCountDownTimeSecs			= fCountDownTimeSecs
	
	PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_PERFORM_SCORE_EVENT - Score: ", iScore, " Count Up Time Secs: ", scoreEvent.fCountUpTimeSecs, " Hold Time Secs: ", scoreEvent.fHoldTimeSecs, " Count Down Time Secs: ", scoreEvent.fCountDownTimeSecs, " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, scoreEvent, SIZE_OF(scoreEvent), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_STRENGTH_TEST_MOVE_NETWORK_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX playerID
	INT iClipsetHash
	INT iClipsetVariableHash
ENDSTRUCT

/// PURPOSE: Sends an events to all inside the Arcade with the Strength Test MoVE Network data
PROC BROADCAST_STRENGTH_TEST_EVENT_MOVE_NETWORK_DATA(PLAYER_INDEX playerID, INT iClipsetHash, INT iClipsetVariableHash)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_MOVE_NETWORK_DATA - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	IF (playerID = INVALID_PLAYER_INDEX())
		PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_MOVE_NETWORK_DATA - playerID is invalid so not broadcasting.")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_STRENGTH_TEST_MOVE_NETWORK_DATA moveNetworkEvent
	moveNetworkEvent.Details.Type 				= SCRIPT_EVENT_STRENGTH_TEST_MOVE_NETWORK_DATA
	moveNetworkEvent.Details.FromPlayerIndex 	= PLAYER_ID()
	moveNetworkEvent.playerID					= playerID
	moveNetworkEvent.iClipsetHash				= iClipsetHash
	moveNetworkEvent.iClipsetVariableHash		= iClipsetVariableHash
	
	PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_MOVE_NETWORK_DATA - Player: ", GET_PLAYER_NAME(playerID), " Player ID: ", NATIVE_TO_INT(playerID), " Clipset Hash: ", iClipsetHash, " Clipset Variable Hash: ", iClipsetVariableHash, " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, moveNetworkEvent, SIZE_OF(moveNetworkEvent), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_STRENGTH_TEST_RESET_PED_CAPSULE
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

/// PURPOSE: Sends an event instructing the local player to stop resizing the Strength Test minigame players ped capsule.
PROC BROADCAST_STRENGTH_TEST_EVENT_RESET_PED_CAPSULE()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_RESET_PED_CAPSULE - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_STRENGTH_TEST_RESET_PED_CAPSULE capsuleEvent
	capsuleEvent.Details.Type 				= SCRIPT_EVENT_STRENGTH_TEST_RESET_PED_CAPSULE
	capsuleEvent.Details.FromPlayerIndex 	= PLAYER_ID()
	
	PRINTLN("[AM_MP_ARCADE_STRENGTH_TEST] BROADCAST_STRENGTH_TEST_EVENT_RESET_PED_CAPSULE - Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, capsuleEvent, SIZE_OF(capsuleEvent), iPlayerFlags)
	
ENDPROC
#ENDIF

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Club Music events								
//╚═════════════════════════════════════════════════════════════════════════════╝

#IF FEATURE_HEIST_ISLAND
#IF IS_DEBUG_BUILD
FUNC STRING GET_CLUB_MUSIC_INTENSITY_NAME(CLUB_MUSIC_INTENSITY eClubIntensity)
	STRING sIntensityName = ""
	SWITCH eClubIntensity
		CASE CLUB_MUSIC_INTENSITY_NULL			sIntensityName = "CLUB_MUSIC_INTENSITY_NULL"		BREAK
		CASE CLUB_MUSIC_INTENSITY_LOW			sIntensityName = "CLUB_MUSIC_INTENSITY_LOW"			BREAK
		CASE CLUB_MUSIC_INTENSITY_MEDIUM		sIntensityName = "CLUB_MUSIC_INTENSITY_MEDIUM"		BREAK
		CASE CLUB_MUSIC_INTENSITY_HIGH			sIntensityName = "CLUB_MUSIC_INTENSITY_HIGH"		BREAK
		CASE CLUB_MUSIC_INTENSITY_HIGH_HANDS	sIntensityName = "CLUB_MUSIC_INTENSITY_HIGH_HANDS"	BREAK
		CASE CLUB_MUSIC_INTENSITY_TRANCE		sIntensityName = "CLUB_MUSIC_INTENSITY_TRANCE"		BREAK
		CASE CLUB_MUSIC_INTENSITY_TOTAL			sIntensityName = "CLUB_MUSIC_INTENSITY_TOTAL"		BREAK
	ENDSWITCH
	RETURN sIntensityName
ENDFUNC

STRUCT DEBUG_SCRIPT_EVENT_DATA_CLUB_MUSIC_RESET_TRACK
	STRUCT_EVENT_COMMON_DETAILS Details
	CLUB_DJS eDJ
ENDSTRUCT

PROC DEBUG_BROADCAST_CLUB_MUSIC_RESET_TRACK(CLUB_DJS eDJ)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[CLUB_MUSIC] DEBUG_BROADCAST_CLUB_MUSIC_RESET_TRACK - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	DEBUG_SCRIPT_EVENT_DATA_CLUB_MUSIC_RESET_TRACK Event
	Event.Details.Type 				= SCRIPT_EVENT_DEBUG_CLUB_MUSIC_RESET_TRACK
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.eDJ						= eDJ
	
	PRINTLN("[CLUB_MUSIC] DEBUG_BROADCAST_CLUB_MUSIC_RESET_TRACK - Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	
ENDPROC

PROC DEBUG_BROADCAST_CLUB_MUSIC_DJ(CLUB_DJS eSetDJ)
	
	INT iPlayerFlags = ALL_PLAYERS()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[CLUB_MUSIC] DEBUG_BROADCAST_CLUB_MUSIC_DJ - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	DEBUG_SCRIPT_EVENT_DATA_CLUB_MUSIC_RESET_TRACK Event
	Event.Details.Type 				= SCRIPT_EVENT_DEBUG_CLUB_MUSIC_DJ
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.eDJ						= eSetDJ
	
	PRINTLN("[CLUB_MUSIC] DEBUG_BROADCAST_CLUB_MUSIC_DJ - Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
ENDPROC

#ENDIF //IS_DEBUG_BUILD

STRUCT SCRIPT_EVENT_DATA_CLUB_MUSIC_INTENSITY
	STRUCT_EVENT_COMMON_DETAILS Details
	CLUB_MUSIC_INTENSITY eClubIntensity
ENDSTRUCT

PROC BROADCAST_CLUB_MUSIC_INTENSITY(CLUB_MUSIC_INTENSITY eClubIntensity)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[CLUB_MUSIC] BROADCAST_CLUB_MUSIC_INTENSITY - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_CLUB_MUSIC_INTENSITY Event
	Event.Details.Type 				= SCRIPT_EVENT_CLUB_MUSIC_INTENSITY
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.eClubIntensity			= eClubIntensity
	
	PRINTLN("[CLUB_MUSIC] BROADCAST_CLUB_MUSIC_INTENSITY - Intensity: ", GET_CLUB_MUSIC_INTENSITY_NAME(eClubIntensity), " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_CLUB_MUSIC_DJ_SWITCH_SCENE
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bStartScene
	CLUB_DJS eNextDJ
ENDSTRUCT

PROC BROADCAST_CLUB_MUSIC_DJ_SWITCH_SCENE(BOOL bStartScene, CLUB_DJS eNextDJ = CLUB_DJ_NULL)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[CLUB_MUSIC] BROADCAST_CLUB_MUSIC_DJ_SWITCH_SCENE - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_CLUB_MUSIC_DJ_SWITCH_SCENE Event
	Event.Details.Type 				= SCRIPT_EVENT_CLUB_MUSIC_DJ_SWITCH_SCENE
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bStartScene				= bStartScene
	Event.eNextDJ					= eNextDJ
	
	PRINTLN("[CLUB_MUSIC] BROADCAST_CLUB_MUSIC_DJ_SWITCH_SCENE - bStart: ", GET_STRING_FROM_BOOL(bStartScene), " next DJ: ", eNextDJ, " Sent by ", GET_PLAYER_NAME(PLAYER_ID()))
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
ENDPROC

STRUCT SCRIPT_EVENT_DATA_CLUB_MUSIC_UPDATE_DJ_PED
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bUpdateDJPeds
ENDSTRUCT

PROC BROADCAST_CLUB_MUSIC_UPDATE_DJ_PEDS_AFTER_SWITCH_SCENE(BOOL bUpdateDJPeds)
	
	INT iPlayerFlags = SPECIFIC_PLAYER(PLAYER_ID())
	
	IF (iPlayerFlags = 0)
		PRINTLN("[CLUB_MUSIC] BROADCAST_CLUB_MUSIC_UPDATE_DJ_PEDS_AFTER_SWITCH_SCENE - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_CLUB_MUSIC_UPDATE_DJ_PED Event
	Event.Details.Type 				= SCRIPT_EVENT_CLUB_MUSIC_UPDATE_DJ_PED_AFTER_SWITCH_SCENE
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bUpdateDJPeds 			= bUpdateDJPeds
	
	PRINTLN("[CLUB_MUSIC] BROADCAST_CLUB_MUSIC_UPDATE_DJ_PEDS_AFTER_SWITCH_SCENE - update DJ ped: ", GET_STRING_FROM_BOOL(bUpdateDJPeds), " Sent by ", GET_PLAYER_NAME(PLAYER_ID()))
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
ENDPROC

STRUCT SCRIPT_EVENT_DATA_CLUB_MUSIC_NEXT_INTENSITY
	STRUCT_EVENT_COMMON_DETAILS Details
	CLUB_MUSIC_INTENSITY eNextClubIntensity
ENDSTRUCT

PROC BROADCAST_CLUB_MUSIC_NEXT_INTENSITY(CLUB_MUSIC_INTENSITY eNextClubIntensity)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[CLUB_MUSIC] BROADCAST_CLUB_MUSIC_NEXT_INTENSITY - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_CLUB_MUSIC_NEXT_INTENSITY Event
	Event.Details.Type 				= SCRIPT_EVENT_CLUB_MUSIC_NEXT_INTENSITY
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.eNextClubIntensity		= eNextClubIntensity
	
	PRINTLN("[CLUB_MUSIC] BROADCAST_CLUB_MUSIC_NEXT_INTENSITY - Next Intensity: ", GET_CLUB_MUSIC_INTENSITY_NAME(eNextClubIntensity), " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_CLUB_MUSIC_REQUEST_INTENSITY
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_CLUB_MUSIC_REQUEST_INTENSITY()
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF (iPlayerFlags = 0)
		PRINTLN("[CLUB_MUSIC] BROADCAST_CLUB_MUSIC_NEXT_INTENSITY - playerflags = 0 so not broadcasting")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_CLUB_MUSIC_REQUEST_INTENSITY Event
	Event.Details.Type 				= SCRIPT_EVENT_CLUB_MUSIC_REQUEST_INTENSITY
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	
	PRINTLN("[CLUB_MUSIC] BROADCAST_CLUB_MUSIC_REQUEST_INTENSITY - Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_CLUB_MUSIC_SEND_INTENSITY_TO_PLAYER
	STRUCT_EVENT_COMMON_DETAILS Details
	CLUB_MUSIC_INTENSITY eClubIntensity
ENDSTRUCT

PROC BROADCAST_CLUB_MUSIC_SEND_INTENSITY_TO_PLAYER(CLUB_MUSIC_INTENSITY eClubIntensity, PLAYER_INDEX playerID)
	
	IF (playerID = INVALID_PLAYER_INDEX())
		PRINTLN("[CLUB_MUSIC] BROADCAST_CLUB_MUSIC_SEND_INTENSITY_TO_PLAYER - playerID is invalid so not broadcasting.")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_CLUB_MUSIC_SEND_INTENSITY_TO_PLAYER Event
	Event.Details.Type 				= SCRIPT_EVENT_CLUB_MUSIC_SEND_INTENSITY_TO_PLAYER
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.eClubIntensity			= eClubIntensity
	
	PRINTLN("[CLUB_MUSIC] BROADCAST_CLUB_MUSIC_SEND_INTENSITY_TO_PLAYER - Intensity: ", GET_CLUB_MUSIC_INTENSITY_NAME(eClubIntensity), " Sending To: ", GET_PLAYER_NAME(playerID), " Sent by ", GET_PLAYER_NAME(PLAYER_ID()), " at ", GET_CLOUD_TIME_AS_INT())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(playerID))
	
ENDPROC
#ENDIF //FEATURE_HEIST_ISLAND

//╔═════════════════════════════════════════════════════════════════════════════╗
//║							Player data request events							
//╚═════════════════════════════════════════════════════════════════════════════╝
ENUM PLAYER_REQUEST_DATA_TYPE
	PRDT_ARENA_CAREER = 0,
	PRDT_REQUEST_USE_OF_TURRET,
	PRDT_REQUEST_ENTRY_TO_SIMPLE_INTERIOR,
	PRDT_SIMPLE_INTERIOR_BUZZER_ENTRY_REPLY,
	PRDT_RELEASE_SIMPLE_INTERIOR_ENTRY_REQUEST
ENDENUM

#IF IS_DEBUG_BUILD
FUNC STRING DEBUG_GET_PLAYER_DATA_REQUEST_TYPE_STRING(PLAYER_REQUEST_DATA_TYPE eDataType)
	SWITCH eDataType
		CASE PRDT_ARENA_CAREER							RETURN "PRDT_ARENA_CAREER"
		CASE PRDT_REQUEST_USE_OF_TURRET					RETURN "PRDT_REQUEST_USE_OF_TURRET"
		CASE PRDT_REQUEST_ENTRY_TO_SIMPLE_INTERIOR		RETURN "PRDT_REQUEST_ENTRY_TO_SIMPLE_INTERIOR"
		CASE PRDT_SIMPLE_INTERIOR_BUZZER_ENTRY_REPLY	RETURN "PRDT_SIMPLE_INTERIOR_BUZZER_ENTRY_REPLY"
		CASE PRDT_RELEASE_SIMPLE_INTERIOR_ENTRY_REQUEST	RETURN "PRDT_RELEASE_SIMPLE_INTERIOR_ENTRY_REQUEST"
	ENDSWITCH
	
	RETURN "*INVALID*"
ENDFUNC
#ENDIF

STRUCT SCRIPT_EVENT_REQUEST_PLAYER_DATA_ARGS
	// Max args size is 49 words
	INT iArray[6] // 6
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_REQUEST_PLAYER_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_REQUEST_DATA_TYPE eDataType

	SCRIPT_EVENT_REQUEST_PLAYER_DATA_ARGS data
	
ENDSTRUCT


/// PURPOSE:
///    Sends an event to the specified player as a request for a set of data specified using eDataType
///    Can be used in conjunction with PLAYER_REQUEST_RESPONSE_EVENT_INFO to determine time since our last request
///    See functions in net_include.sch (search: BROADCAST_REQUEST_PLAYER_DATA)
///    args - generic data, the sender and responder are responsible for understanding the args meaning.
PROC BROADCAST_REQUEST_PLAYER_DATA_ARGS(PLAYER_INDEX piPlayer, PLAYER_REQUEST_DATA_TYPE eDataType, SCRIPT_EVENT_REQUEST_PLAYER_DATA_ARGS& data)
	
	//Common data
	SCRIPT_EVENT_DATA_REQUEST_PLAYER_DATA Event
	Event.Details.Type 				= SCRIPT_EVENT_REQUEST_PLAYER_DATA
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.eDataType					= eDataType
	Event.data 						= data
	
	INT iPlayerFlags = SPECIFIC_PLAYER(piPlayer)
		
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_REQUEST_PLAYER_DATA_ARGS - Requesting data from player ", NATIVE_TO_INT(piPlayer), " of type ", DEBUG_GET_PLAYER_DATA_REQUEST_TYPE_STRING(eDataType), " (", eDataType, ")")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		PRINTLN("BROADCAST_REQUEST_PLAYER_DATA_ARGS - playerflags = 0 so not broadcasting")		
	ENDIF	
ENDPROC

/// PURPOSE:
///    Sends an event to the specified player as a request for a set of data specified using eDataType
///    Can be used in conjunction with PLAYER_REQUEST_RESPONSE_EVENT_INFO to determine time since our last request
///    See functions in net_include.sch (search: BROADCAST_REQUEST_PLAYER_DATA)
PROC BROADCAST_REQUEST_PLAYER_DATA(PLAYER_INDEX piPlayer, PLAYER_REQUEST_DATA_TYPE eDataType)
	SCRIPT_EVENT_REQUEST_PLAYER_DATA_ARGS emptyArgs
	BROADCAST_REQUEST_PLAYER_DATA_ARGS(piPlayer, eDataType, emptyArgs)
ENDPROC 

STRUCT SCRIPT_EVENT_DATA_PLAYER_DATA_RESPONSE
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_REQUEST_DATA_TYPE eDataType
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_REQUEST_PLAYER_DATA_RESPONSE_INT
	//This needs to be at the top to allow us to determine which struct to use when retrieving the event data. this struct includes STRUCT_EVENT_COMMON_DETAILS
	SCRIPT_EVENT_DATA_PLAYER_DATA_RESPONSE eResponseData
	//Max size of array = 49 (50 - eResponseData.eDataType)
	INT iArray[21]
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_REQUEST_PLAYER_DATA_RESPONSE_SMALL_INT
	//This needs to be at the top to allow us to determine which struct to use when retrieving the event data. this struct includes STRUCT_EVENT_COMMON_DETAILS
	SCRIPT_EVENT_DATA_PLAYER_DATA_RESPONSE eResponseData
	//Max size of array = 49 (50 - eResponseData.eDataType)
	INT iReply
ENDSTRUCT

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					PLAYER ARENA VEHICLE NAME																	
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_REQUEST_PLAYER_VEHICLE_NAME
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iPVDisplaySlot
	TEXT_LABEL_63 sVehicleName
	BOOL bCallBack
ENDSTRUCT

PROC BROADCAST_REQUEST_PLAYER_ARENA_VEHICLE_NAME(PLAYER_INDEX piRemotePlayer, INT iPVDisplaySlot, TEXT_LABEL_63 sVehName, BOOL bCallBack)

	SCRIPT_EVENT_DATA_REQUEST_PLAYER_VEHICLE_NAME Event
	Event.Details.Type 				= SCRIPT_EVENT_REQUEST_PLAYER_VEHICLE_NAME
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iPVDisplaySlot 			= iPVDisplaySlot
	Event.bCallBack					= bCallBack
	
	IF bCallBack
		Event.sVehicleName			= sVehName
	ENDIF
	
	PRINTLN("BROADCAST_REQUEST_PLAYER_ARENA_VEHICLE_NAME: ", bCallBack, " iPVDisplaySlot: ", iPVDisplaySlot, " sVehName: ", sVehName)
	
	INT iPlayerFlags = SPECIFIC_PLAYER(piRemotePlayer)
		
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_REQUEST_PLAYER_DATA_ARGS - broadcasting to ", NATIVE_TO_INT(piRemotePlayer))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		PRINTLN("BROADCAST_REQUEST_PLAYER_DATA_ARGS - playerflags = 0 so not broadcasting")		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					REMOTE DRONE SCRIPT																	
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_REMOTE_DRONE_SCRIPT
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bStartScript
ENDSTRUCT

PROC BROADCAST_REMOTE_DRONE_SCRIPT(PLAYER_INDEX piRemotePlayer, BOOL bStartScript)

	SCRIPT_EVENT_DATA_REMOTE_DRONE_SCRIPT Event
	Event.Details.Type 				= SCRIPT_EVENT_REMOTE_DRONE_SCRIPT
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bStartScript 				= bStartScript
	
	INT iPlayerFlags = SPECIFIC_PLAYER(piRemotePlayer)
		
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_REMOTE_DRONE_SCRIPT - broadcasting to ", NATIVE_TO_INT(piRemotePlayer))
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		PRINTLN("BROADCAST_REMOTE_DRONE_SCRIPT - playerflags = 0 so not broadcasting")		
	ENDIF	
ENDPROC

STRUCT ARENA_SPECATOR_TURRET_EVENT_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTurretIndex
	TIME_DATATYPE tCooldownComplete
ENDSTRUCT

PROC ARENA_SPECTATOR_TURRET_UPDATE_MISSILE_CD(ARENA_SPECATOR_TURRET_EVENT_DATA& event)
	IF PLAYER_ID() = NETWORK_GET_HOST_OF_SCRIPT(FREEMODE_SCRIPT())
		CDEBUG3LN(DEBUG_NET_TURRET, "ARENA SPEC - _ARENA_SPECTATOR_TURRET_UPDATE_MISSILE_CD - (iTurretIndex = ", event.iTurretIndex," tCooldownComplete = ",NATIVE_TO_INT(event.tCooldownComplete),")")
		GlobalServerBD_BlockB.arenaSpectatorTurretServer.tMissileCooldown[event.iTurretIndex] = event.tCooldownComplete	
	ELSE
		CDEBUG3LN(DEBUG_NET_TURRET, "ARENA SPEC - _ARENA_SPECTATOR_TURRET_UPDATE_MISSILE_CD - I'm not the host...")
	ENDIF
ENDPROC

PROC ARENA_SPECTATOR_TURRET_PROCCESS_MISSILE_FIRED_EVENT(INT iEventId)
	ARENA_SPECATOR_TURRET_EVENT_DATA event
	IF GET_EVENT_DATA(SCRIPT_EVENT_QUEUE_NETWORK, iEventId, event, SIZE_OF(event)) 
		ARENA_SPECTATOR_TURRET_UPDATE_MISSILE_CD(event)
	ELSE
		CDEBUG3LN(DEBUG_NET_TURRET, "ARENA SPEC - ARENA_SPECTATOR_TURRET_PROCCESS_MISSILE_FIRED_EVENT - failed to get data")
	ENDIF
ENDPROC

PROC ARENA_SPECTATOR_TURRET_BROADCAST_MISSILE_FIRED(INT iTurretIndex, TIME_DATATYPE tCooldownComplete)
	ARENA_SPECATOR_TURRET_EVENT_DATA event
	event.Details.Type 				= SCRIPT_EVENT_ARENA_SPECTATOR_TURRET_MISSILE_FIRED
	event.Details.FromPlayerIndex	= PLAYER_ID()
	event.iTurretIndex 				= iTurretIndex
	event.tCooldownComplete 		= tCooldownComplete
	
	PLAYER_INDEX pHost = NETWORK_GET_HOST_OF_SCRIPT(FREEMODE_SCRIPT())
	
	IF pHost = PLAYER_ID()
		ARENA_SPECTATOR_TURRET_UPDATE_MISSILE_CD(event)
		CDEBUG3LN(DEBUG_NET_TURRET, "ARENA SPEC - ARENA_SPECTATOR_TURRET_BROADCAST_MISSILE_FIRED - SERVER (iTurretIndex = ",iTurretIndex," tCooldownComplete = ",NATIVE_TO_INT(tCooldownComplete),")")
	ELSE
		INT iPlayerFlags = SPECIFIC_PLAYER(pHost)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, event, SIZE_OF(event), iPlayerFlags)
		CDEBUG3LN(DEBUG_NET_TURRET, "ARENA SPEC - ARENA_SPECTATOR_TURRET_BROADCAST_MISSILE_FIRED (iTurretIndex = ",iTurretIndex," tCooldownComplete = ",NATIVE_TO_INT(tCooldownComplete),")")
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_SURVIVAL_AIR_VEHICLE_DESTROYED
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX piDestroyerPlayerID
ENDSTRUCT

PROC BROADCAST_SURVIVAL_AIR_VEHICLE_DESTROYED(PLAYER_INDEX piDestroyer)
	SCRIPT_EVENT_DATA_SURVIVAL_AIR_VEHICLE_DESTROYED event
	event.Details.Type = SCRIPT_EVENT_CASINO_SURVIVAL_AIR_VEHICLE_DESTROYED
	event.Details.FromPlayerIndex = PLAYER_ID()
	event.piDestroyerPlayerID = piDestroyer
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE)
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_SURVIVAL_AIR_VEHICLE_DESTROYED - broadcasting to all players")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)		
	ELSE
		PRINTLN("BROADCAST_SURVIVAL_AIR_VEHICLE_DESTROYED - playerflags = 0 so not broadcasting")		
	ENDIF

ENDPROC

STRUCT SCRIPT_EVENT_DATA_SURVIVAL_HEAVY_UNIT_KILLED
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX piDestroyerPlayerID
ENDSTRUCT

PROC BROADCAST_SURVIVAL_HEAVY_UNIT_KILLED(PLAYER_INDEX piDestroyer)
	SCRIPT_EVENT_DATA_SURVIVAL_HEAVY_UNIT_KILLED event
	event.Details.Type = SCRIPT_EVENT_SURVIVAL_HEAVY_UNIT_KILLED
	event.Details.FromPlayerIndex = PLAYER_ID()
	event.piDestroyerPlayerID = piDestroyer
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE)
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_SURVIVAL_HEAVY_UNIT_KILLED - broadcasting to all players")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)		
	ELSE
		PRINTLN("BROADCAST_SURVIVAL_HEAVY_UNIT_KILLED - playerflags = 0 so not broadcasting")		
	ENDIF

ENDPROC


//╔═════════════════════════════════════════════════════════════════════════════╗
//║					PLAYER TRANSACTION EVENT									
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_REQUEST_CASH_TRANSACTION
	STRUCT_EVENT_COMMON_DETAILS Details
	CASH_TRANSACTION_EVENT transaction
ENDSTRUCT

PROC REQUEST_CASH_TRANSACTION_SCRIPT()
	REQUEST_SCRIPT("AM_ARENA_SHP")
ENDPROC

/// PURPOSE:
///    Requests a transaction to be run. This will be picked up based on active tuneables
/// PARAMS:
///    transactionDetails 	- Details of the transaction to run
///    iGivenSlot 			- The transaction slot assigned to this transaction
PROC BROADCAST_REQUEST_CASH_TRANSACTION(CASH_TRANSACTIONS_DETAILS transactionDetails, INT iGivenSlot)
	
	IF iGivenSlot < 0
		SCRIPT_ASSERT("BROADCAST_REQUEST_CASH_TRANSACTION - iGivenTransactionSlot < 0")
		EXIT
	ENDIF
	
	SCRIPT_EVENT_DATA_REQUEST_CASH_TRANSACTION Event
	Event.Details.Type 				= SCRIPT_EVENT_REQUEST_CASH_TRANSACTION
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.transaction.eDetails 		= transactionDetails.eEssentialData
	Event.transaction.iSlot			= iGivenSlot
	
	INT iPlayerFlags = SPECIFIC_PLAYER(Event.Details.FromPlayerIndex)
	
	IF g_sMPTunables.bBLOCK_NS_TRANS
	AND NOT g_sMPTunables.bSC_RUN_TRANS
	AND NOT g_sMPTunables.bBG_RUN_TRANS
		PRINTLN("BROADCAST_REQUEST_CASH_TRANSACTION - Skip for BLOCK_*_TRANS")
		EXIT
	ENDIF
		
	IF NOT (iPlayerFlags = 0)
		PRINTLN("[CASH] BROADCAST_REQUEST_CASH_TRANSACTION - broadcasting to local player. Transaction slot: ", iGivenSlot)
		REQUEST_CASH_TRANSACTION_SCRIPT()
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		PRINTLN("BROADCAST_REQUEST_CASH_TRANSACTION - playerflags = 0 so not broadcasting")		
	ENDIF	
ENDPROC

#IF FEATURE_FREEMODE_ARCADE
STRUCT SCRIPT_EVENT_DATA_REQUEST_SUI_PURCHASE
	STRUCT_EVENT_COMMON_DETAILS Details
	TRANSACTION_CURRENCY eCurrency
	SCRIPT_UNLOCKABLE_ITEM eItem
ENDSTRUCT

/// PURPOSE:
///    Requests a transaction to be run. This will be picked up based on active tuneables
FUNC BOOL BROADCAST_REQUEST_SUI_PURCHASE(TRANSACTION_CURRENCY eCurrency, SCRIPT_UNLOCKABLE_ITEM eItem)
	
	IF g_TransitionSessionNonResetVars.SUIPurchase.eTransactionState = TRANSACTION_STATE_PENDING
		SCRIPT_ASSERT("BROADCAST_REQUEST_SUI_PURCHASE - Transaction already in progress!")
		RETURN FALSE
	ELIF eItem = SUI_UNLOCK_INVALID
		SCRIPT_ASSERT("BROADCAST_REQUEST_SUI_PURCHASE - Invalid item!")
		RETURN FALSE
	ENDIF
		
	SCRIPT_EVENT_DATA_REQUEST_SUI_PURCHASE Event
	Event.Details.Type 				= SCRIPT_EVENT_REQUEST_SUI_PURCHASE
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.eCurrency 				= eCurrency
	Event.eItem						= eItem
	
	g_TransitionSessionNonResetVars.SUIPurchase.eTransactionState = TRANSACTION_STATE_PENDING
	g_TransitionSessionNonResetVars.SUIPurchase.iItem = ENUM_TO_INT(eItem)
	
	INT iPlayerFlags = SPECIFIC_PLAYER(Event.Details.FromPlayerIndex)
		
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_REQUEST_SUI_PURCHASE - broadcasting to local player. item: ", eItem, " currency: ", eCurrency)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
		RETURN TRUE
	ELSE
		PRINTLN("BROADCAST_REQUEST_SUI_PURCHASE - playerflags = 0 so not broadcasting")		
	ENDIF
	
	RETURN FALSE
ENDFUNC
#ENDIF

#IF IS_DEBUG_BUILD
//╔═════════════════════════════════════════════════════════════════════════════╗
//║					PLAYER WEAPON AND VEHICLE DAMAGE MODIFIER					
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_PLAYER_DAMAGE_MODIFIER
	STRUCT_EVENT_COMMON_DETAILS Details 
	FLOAT fPlyrDamMod
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_MISSION_DIFF_MODIFIER
	STRUCT_EVENT_COMMON_DETAILS Details 
	FLOAT fpedHealth
	FLOAT fpedAccuracy
	INT iPedRespawns
ENDSTRUCT

//PURPOSE: Updates the Player's Weapon Damage Modifier to the Value Broadcast
PROC BROADCAST_UPDATE_PLAYER_WEAPON_DAMAGE_MODIFIER(FLOAT fPlyrWeapDamMod,INT iPlayerFlags)
	SCRIPT_EVENT_DATA_PLAYER_DAMAGE_MODIFIER Event
	Event.Details.Type = SCRIPT_EVENT_UPDATE_PLAYER_WEAPON_DAMAGE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.fPlyrDamMod = fPlyrWeapDamMod
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_UPDATE_PLAYER_WEAPON_DAMAGE_MODIFIER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//PURPOSE: Updates the Player's Vehicle Damage Modifier to the Value Broadcast
PROC BROADCAST_UPDATE_PLAYER_VEHICLE_DAMAGE_MODIFIER(FLOAT fPlyrVehDamMod,INT iPlayerFlags)
	SCRIPT_EVENT_DATA_PLAYER_DAMAGE_MODIFIER Event
	Event.Details.Type = SCRIPT_EVENT_UPDATE_PLAYER_VEHICLE_DAMAGE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.fPlyrDamMod = fPlyrVehDamMod
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_UPDATE_PLAYER_VEHICLE_DAMAGE_MODIFIER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//PURPOSE: Updates the Ai Damage Modifier to the Value Broadcast
PROC BROADCAST_UPDATE_AI_DAMAGE_MODIFIER(FLOAT fAiDamMod,INT iPlayerFlags)
	SCRIPT_EVENT_DATA_PLAYER_DAMAGE_MODIFIER Event
	Event.Details.Type = SCRIPT_EVENT_UPDATE_AI_DAMAGE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.fPlyrDamMod = fAiDamMod
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_UPDATE_AI_DAMAGE_MODIFIER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC
//PURPOSE: Updates the Ai Damage Modifier to the Value Broadcast
PROC BROADCAST_UPDATE_MISSION_DIFF_MODIFIER(FLOAT fhealth, FLOAT faccuracy,INT irespawns,INT iPlayerFlags)

	SCRIPT_EVENT_DATA_MISSION_DIFF_MODIFIER Event
	Event.Details.Type = SCRIPT_EVENT_UPDATE_MISSION_DIFFICULTY
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.fpedHealth = fhealth
	Event.fpedAccuracy = faccuracy
	Event.ipedRespawns = irespawns
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_UPDATE_MISSION_DIFF_MODIFIER - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Bunker business debug events																
//╚═════════════════════════════════════════════════════════════════════════════╝

ENUM DEBUG_BUNKER_BUSINESS_UPDATE_TYPE
	BB_UPDATE_SUPPLIES = 0,
	BB_UPDATE_RESEARCH,
	BB_UPDATE_PRODUCT
ENDENUM

STRUCT SCRIPT_EVENT_DATA_BUNKER_BUSINESS_UPDATE
	STRUCT_EVENT_COMMON_DETAILS Details 
	DEBUG_BUNKER_BUSINESS_UPDATE_TYPE eType
	INT iUpdateToPercent
ENDSTRUCT

//PURPOSE: sends an event to the local players gang boss to modify their bunker business product totals
PROC BROADCAST_UPDATE_BUNKER_BUSINESS_DATA(PLAYER_INDEX piGangBoss, DEBUG_BUNKER_BUSINESS_UPDATE_TYPE eUpdateType, INT iUpdateToPercent)
	
	//Common data
	SCRIPT_EVENT_DATA_BUNKER_BUSINESS_UPDATE Event
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_BOSS_BUNKER_DATA
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	
	//Bunker data
	Event.eType 			= eUpdateType
	Event.iUpdateToPercent 	= iUpdateToPercent
	
	INT iPlayerFlags = 0
	
	IF piGangBoss != INVALID_PLAYER_INDEX()
		SET_BIT(iPlayerFlags, NATIVE_TO_INT(piGangBoss))
	ENDIF
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_UPDATE_BUNKER_BUSINESS_DATA - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Business Hub debug events								
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_BUSINESS_HUB_UPDATE
	STRUCT_EVENT_COMMON_DETAILS Details
	BUSINESS_TYPE eBusinessType
	INT iUpdateToPercent
ENDSTRUCT

//PURPOSE: sends an event to the local players gang boss to modify their bunker business product totals
PROC BROADCAST_UPDATE_BUSINESS_HUB_DATA(PLAYER_INDEX piGangBoss, BUSINESS_TYPE eBusinessType, INT iUpdateToPercent)
	
	//Common data
	SCRIPT_EVENT_DATA_BUSINESS_HUB_UPDATE Event
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_BOSS_BUSINESS_HUB_DATA
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	
	//Business Hub data
	Event.iUpdateToPercent 	= iUpdateToPercent
	Event.eBusinessType		= eBusinessType
	
	INT iPlayerFlags = 0
	
	IF piGangBoss != INVALID_PLAYER_INDEX()
		SET_BIT(iPlayerFlags, NATIVE_TO_INT(piGangBoss))
	ENDIF
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_UPDATE_BUSINESS_HUB_DATA - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_BUSINESS_HUB_SETUP_UPDATE
	STRUCT_EVENT_COMMON_DETAILS Details
	MEGA_BUSINESS_MISSION_VARIATION eSetupVar
ENDSTRUCT

//PURPOSE: sends an event to the local players gang boss to modify their bunker business product totals
PROC BROADCAST_UPDATE_BUSINESS_HUB_SETUP_DATA(PLAYER_INDEX piGangBoss, MEGA_BUSINESS_MISSION_VARIATION eSetupVar)
	
	//Common data
	SCRIPT_EVENT_DATA_BUSINESS_HUB_SETUP_UPDATE Event
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_BOSS_BUSINESS_HUB_SETUP
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	
	//Business Hub data
	Event.eSetupVar = eSetupVar
	
	INT iPlayerFlags = 0
	
	IF piGangBoss != INVALID_PLAYER_INDEX()
		SET_BIT(iPlayerFlags, NATIVE_TO_INT(piGangBoss))
	ENDIF
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_UPDATE_BUSINESS_HUB_DATA - called - Sending to ", iPlayerFlags, " eSetupVar = ", eSetupVar)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_UPDATE_BUSINESS_HUB_DATA - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_NIGHTCLUB_BINK_VIDEO_TEST
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX pNightclubOwner
	INT iVideoOption
ENDSTRUCT

PROC BROADCAST_UPDATE_NIGHTCLUB_BINK_VIDEO(PLAYER_INDEX piNightclubOwner, INT iVideoOption)
	
	//Common data
	SCRIPT_EVENT_DATA_NIGHTCLUB_BINK_VIDEO_TEST Event
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_NIGHTCLUB_BINK_VIDEO
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.pNightclubOwner 			= piNightclubOwner
	Event.iVideoOption 				= iVideoOption
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE)
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_UPDATE_NIGHTCLUB_BINK_VIDEO - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_NIGHTCLUB_DRY_ICE_TEST
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX pNightclubOwner
	INT iDryIceOption
ENDSTRUCT

PROC BROADCAST_UPDATE_NIGHTCLUB_DRY_ICE(PLAYER_INDEX piNightclubOwner, INT iDryIceOption)
	
	//Common data
	SCRIPT_EVENT_DATA_NIGHTCLUB_DRY_ICE_TEST Event
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_NIGHTCLUB_DRY_ICE
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.pNightclubOwner 			= piNightclubOwner
	Event.iDryIceOption 			= iDryIceOption
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE)
	
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_UPDATE_NIGHTCLUB_DRY_ICE - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
	
ENDPROC

 //FEATURE_BUSINESS_BATTLES

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Arena debug events								
//╚═════════════════════════════════════════════════════════════════════════════╝

STRUCT SCRIPT_EVENT_DATA_ARENA_WHEEL_SPIN_MINIGAME_REWARD
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iRewardIndex
ENDSTRUCT

PROC BROADCAST_UPDATE_ARENA_WHEEL_SPIN_MINIGAME_REWARD(PLAYER_INDEX pArenaBoxHost, INT iRewardIndex)
	
	//Common data
	SCRIPT_EVENT_DATA_ARENA_WHEEL_SPIN_MINIGAME_REWARD Event
	Event.Details.Type 				= SCRIPT_EVENT_UPDATE_WHEEL_SPIN_MINIGAME_REWARD
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iRewardIndex 				= iRewardIndex
	
	PRINTLN("[WHEEL_SPIN] BROADCAST_UPDATE_ARENA_WHEEL_SPIN_MINIGAME_REWARD - M MENU DEBUG USED! I am sending an event to the host of the Arena Box script to change the Reward ID to: ", iRewardIndex)
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(pArenaBoxHost))
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_GIVE_BOSS_CASINO_CHIPS
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_GIVE_BOSS_CASINO_CHIPS()
	
	//Common data
	SCRIPT_EVENT_DATA_GIVE_BOSS_CASINO_CHIPS Event
	Event.Details.Type 				= SCRIPT_EVENT_GIVE_BOSS_CASINO_CHIPS
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	
	PLAYER_INDEX playerBoss = GB_GET_LOCAL_PLAYER_GANG_BOSS()	
	
	IF playerBoss != INVALID_PLAYER_INDEX()
		IF NETWORK_IS_PLAYER_ACTIVE(playerBoss)
			PRINTLN("BROADCAST_GIVE_BOSS_CASINO_CHIPS - M MENU DEBUG USED! I am sending an event to my boss.")
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), SPECIFIC_PLAYER(playerBoss))
		ELSE
			PRINTLN("BROADCAST_GIVE_BOSS_CASINO_CHIPS - M MENU DEBUG USED! FAIL Boss player = inactive")
		ENDIF
	ELSE
		PRINTLN("BROADCAST_GIVE_BOSS_CASINO_CHIPS - M MENU DEBUG USED! FAIL Boss player = INVALID")
	ENDIF
	
ENDPROC
 //FEATURE_ARENA_WARS
#ENDIF //IS_DEBUG_BUILD

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Casino debug events								
//╚═════════════════════════════════════════════════════════════════════════════╝
#IF FEATURE_CASINO
STRUCT SCRIPT_EVENT_DATA_CASINO_LUCKY_WHEEL_SPIN
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCurrentSpinIndex
	BOOL bStartSpin
ENDSTRUCT

PROC BROADCAST_CASINO_LUCKY_WHEEL_SPIN(INT iCurrentSpin, BOOL bStartSpin)
	
	//Common data
	SCRIPT_EVENT_DATA_CASINO_LUCKY_WHEEL_SPIN Event
	Event.Details.Type 				= SCRIPT_EVENT_CASINO_LUCKY_WHEEL_SPIN
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iCurrentSpinIndex 		= iCurrentSpin
	Event.bStartSpin				= bStartSpin
	PRINTLN("BROADCAST_CASINO_LUCKY_WHEEL_SPIN iCurrentSpin: ", iCurrentSpin, " bStartSpin: ", bStartSpin)
	
	INT iPlayerFlags = ALL_PLAYERS()
	
	IF iPlayerFlags != -1
		PRINTLN("BROADCAST_CASINO_LUCKY_WHEEL_SPIN - sending event")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		PRINTLN("BROADCAST_CASINO_LUCKY_WHEEL_SPIN - iPlayerFlags is invalid")
	ENDIF
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_INSIDE_TRACK_MAIN_EVENT_REWARD
	STRUCT_EVENT_COMMON_DETAILS Details
	INSIDE_TRACK_RACE_DATA sRaceData
ENDSTRUCT

PROC BROADCAST_INSIDE_TRACK_MAIN_EVENT_REWARD(INSIDE_TRACK_RACE_DATA &sRaceData)
	
	//Common data
	SCRIPT_EVENT_DATA_INSIDE_TRACK_MAIN_EVENT_REWARD Event
	Event.Details.Type 				= SCRIPT_EVENT_INSIDE_TRACK_MAIN_EVENT_REWARD
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	
	PRINTLN("[INSIDE_TRACK] CLONE_INSIDE_TRACK_RACE_DATA")
	
	INT i
	
	Event.sRaceData.iBS							= sRaceData.iBS
	Event.sRaceData.eGameState					= sRaceData.eGameState
	REPEAT iCONST_INSIDE_TRACK_LANE_COUNT i
		Event.sRaceData.eHorsesRacing[i]		= sRaceData.eHorsesRacing[i]
		Event.sRaceData.iHorseTimes[i]			= sRaceData.iHorseTimes[i]
	ENDREPEAT
	Event.sRaceData.iWinningSegment				= sRaceData.iWinningSegment
	Event.sRaceData.iSeed						= sRaceData.iSeed
	Event.sRaceData.iDuration					= sRaceData.iDuration
	Event.sRaceData.iPositionList				= sRaceData.iPositionList
	REPEAT INSIDE_TRACK_RACE_TIMER_COUNT i
		Event.sRaceData.stTimer[i].StartTime	= sRaceData.stTimer[i].StartTime
		Event.sRaceData.stTimer[i].PauseTime	= sRaceData.stTimer[i].PauseTime
		Event.sRaceData.stTimer[i].TimerBits	= sRaceData.stTimer[i].TimerBits
	ENDREPEAT
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE)
	
	PRINTLN("BROADCAST_INSIDE_TRACK_MAIN_EVENT_REWARD - reward winners iSeed:", sRaceData.iSeed, ".")
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_INSIDE_TRACK_MAIN_EVENT_PLACED_BET
	STRUCT_EVENT_COMMON_DETAILS Details
	INSIDE_TRACK_BET_DATA sBetData
	INT iSeed
ENDSTRUCT

PROC BROADCAST_INSIDE_TRACK_MAIN_EVENT_PLACED_BET(INSIDE_TRACK_BET_DATA &sBetData, INT iSeed)
	
	//Common data
	SCRIPT_EVENT_DATA_INSIDE_TRACK_MAIN_EVENT_PLACED_BET Event
	Event.Details.Type 				= SCRIPT_EVENT_INSIDE_TRACK_MAIN_EVENT_PLACED_BET
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	
	Event.sBetData.tl63Gamertag		= sBetData.tl63Gamertag
	Event.sBetData.iSelection		= sBetData.iSelection
	Event.sBetData.iStake			= sBetData.iStake
	Event.iSeed						= iSeed
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT(TRUE)
	
	PRINTLN("BROADCAST_INSIDE_TRACK_MAIN_EVENT_PLACED_BET - place bet \"", sBetData.tl63Gamertag, "\", iSelection:", sBetData.iSelection, ", iStake:", sBetData.iStake, ", iSeed:", iSeed, ".")
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_INSIDE_TRACK_MAIN_EVENT_COMPLETED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iSeed
ENDSTRUCT

PROC BROADCAST_INSIDE_TRACK_MAIN_EVENT_COMPLETED(INT iSeed)
	
	//Common data
	SCRIPT_EVENT_DATA_INSIDE_TRACK_MAIN_EVENT_COMPLETED Event
	Event.Details.Type 				= SCRIPT_EVENT_INSIDE_TRACK_MAIN_EVENT_COMPLETED
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iSeed 					= iSeed
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT(TRUE)
	
	PRINTLN("BROADCAST_INSIDE_TRACK_MAIN_EVENT_COMPLETED - iSeed:", iSeed, ".")
	
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_CASINO_LUCKY_WHEEL_WINNER_BINK_EVENT_COMPLETED
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bTriggerWinnerBink = FALSE
ENDSTRUCT

PROC BROADCAST_LUCKY_WHEEL_WINNER_BINK_EVENT_COMPLETED()
	//Common data
	SCRIPT_EVENT_DATA_CASINO_LUCKY_WHEEL_WINNER_BINK_EVENT_COMPLETED Event
	Event.Details.Type 				= SCRIPT_EVENT_CASINO_LUCKY_WHEEL_WINNER_BINK
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bTriggerWinnerBink 		= TRUE
	
	PRINTLN("[LUCKY_WHEEL_BINK] BROADCAST_LUCKY_WHEEL_WINNER_BINK_EVENT_COMPLETED - I am sending an event to all participants of AM_MP_CASINO to trigger the winner bink video")
	
	INT iPlayerFlags = ALL_PLAYERS()
	
	IF iPlayerFlags != -1
		PRINTLN("BROADCAST_LUCKY_WHEEL_WINNER_BINK_EVENT_COMPLETED - sending event")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		PRINTLN("BROADCAST_LUCKY_WHEEL_WINNER_BINK_EVENT_COMPLETED - iPlayerFlags is invalid")
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_CASINO_UPDATED_STEAL_PAINTING_STATE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCurrentCutPaintingState
	INT iCurrentPaintingIndex
	INT iObj
ENDSTRUCT

PROC BROADCAST_CASINO_UPDATED_STEAL_PAINTING_STATE(INT iCurrentCutPaintingState, INT iCurrentPaintingIndex, INT iObj)	
	//Common data
	SCRIPT_EVENT_DATA_CASINO_UPDATED_STEAL_PAINTING_STATE Event
	Event.Details.Type 				= SCRIPT_EVENT_CASINO_UPDATED_STEAL_PAINTING_STATE
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.iCurrentCutPaintingState	= iCurrentCutPaintingState
	Event.iCurrentPaintingIndex		= iCurrentPaintingIndex
	Event.iObj						= iObj
	
	PRINTLN("[CUT_PAINTING_STATE][CutPainting] BROADCAST_CASINO_UPDATED_STEAL_PAINTING_STATE - I am sending an event to all participants updating the state of painting ", iCurrentPaintingIndex, " being cut to state ", iCurrentCutPaintingState)  	// [ML] Maybe just to the server?
	
	INT iPlayerFlags = ALL_PLAYERS()
	
	IF iPlayerFlags != -1
		PRINTLN("BROADCAST_CASINO_UPDATED_STEAL_PAINTING_STATE - sending event")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		PRINTLN("BROADCAST_CASINO_UPDATED_STEAL_PAINTING_STATE - iPlayerFlags is invalid")
	ENDIF
ENDPROC

#ENDIF

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Arcade cabinet animation events								║			
//╚═════════════════════════════════════════════════════════════════════════════╝
#IF FEATURE_CASINO_HEIST
STRUCT SCRIPT_EVENT_DATA_ARCADE_CABINET_ANIM
	STRUCT_EVENT_COMMON_DETAILS Details
	ARCADE_CABINET_ANIM_CLIPS eAnimToPlay
	BOOL bHoldLastFrame = FALSE
	BOOL bLoopAnim = FALSE
	FLOAT fBlendInDelta = REALLY_SLOW_BLEND_IN
	FLOAT fBlendOutDelta = REALLY_SLOW_BLEND_OUT
	ENTITY_INDEX enToPlayAnim 
ENDSTRUCT

/// PURPOSE:
///    Play arcade cabinet animation 
/// PARAMS:
///    eAnimEvent - pass in struct to avoid event spam for same animation
///    eAnimClip - new anim clip to play
PROC PLAY_ARCADE_CABINET_ANIMATION(ARCADE_CABINET_ANIM_EVENT_STRUCT &eAnimEvent, ARCADE_CABINET_ANIM_CLIPS eAnimClip)
	
	//Common data
	SCRIPT_EVENT_DATA_ARCADE_CABINET_ANIM Event
	Event.Details.Type 				= SCRIPT_EVENT_PLAY_ARCADE_CABINET_ANIM
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.eAnimToPlay				= eAnimClip
	Event.bHoldLastFrame			= eAnimEvent.bHoldLastFrame
	Event.bLoopAnim					= eAnimEvent.bLoopAnim
	Event.fBlendInDelta				= eAnimEvent.fBlendInDelta
	Event.fBlendOutDelta			= eAnimEvent.fBlendOutDelta
	Event.enToPlayAnim				= eAnimEvent.enToPlayAnim
	
	DEBUG_PRINTCALLSTACK()
	PRINTLN("[AM_ARC_CAB] - PLAY_ARCADE_CABINET_ANIMATION anim clip: ", GET_ARCADE_CABINET_ANIMATION_NAME(eAnimClip), " bLoopAnim: ", Event.bLoopAnim, " bHoldLastFrame: ", Event.bHoldLastFrame,
			" Event.fBlendInDelta: ", Event.fBlendInDelta, " Event.fBlendOutDelta: ", Event.fBlendOutDelta)
	
	BOOL bAllowSpam = FALSE
	
	IF eAnimClip = ARCADE_CABINET_ANIM_CLIP_EXIT
		IF IS_BIT_SET(globalPlayerBD[NATIVE_TO_INT(PLAYER_ID())].sArcadeManagerGlobalPlayerBD.iArcadeCabinetBS, ARCADE_CABINET_GLOBAL_BD_PLAYER_READY_TO_PLAY)
			CLEAR_BIT(globalPlayerBD[NATIVE_TO_INT(PLAYER_ID())].sArcadeManagerGlobalPlayerBD.iArcadeCabinetBS, ARCADE_CABINET_GLOBAL_BD_PLAYER_READY_TO_PLAY)
			bAllowSpam = TRUE
			PRINTLN("[AM_ARC_CAB] - SET_PLAYER_READY_TO_PLAY_ARCADE_GAME - FALSE")
		ENDIF	
	ENDIF
	
	eAnimEvent.bEventSent = FALSE
	
	IF NOT HAS_NET_TIMER_STARTED(eAnimEvent.sAnimEventSpamTimer)
		START_NET_TIMER(eAnimEvent.sAnimEventSpamTimer)
	ENDIF
	
	BOOL bSendEvent = TRUE
	
	
	IF eAnimEvent.ePreviousAnimClip = eAnimClip
	AND !bAllowSpam
		IF HAS_NET_TIMER_STARTED(eAnimEvent.sAnimEventSpamTimer)
		AND NOT HAS_NET_TIMER_EXPIRED(eAnimEvent.sAnimEventSpamTimer, 1000)
			bSendEvent = FALSE
		ELSE	
			RESET_NET_TIMER(eAnimEvent.sAnimEventSpamTimer)
		ENDIF
	ELSE
		PRINTLN("[AM_ARC_CAB] - PLAY_ARCADE_CABINET_ANIMATION new clip: ", GET_ARCADE_CABINET_ANIMATION_NAME(eAnimClip), " previous: ", GET_ARCADE_CABINET_ANIMATION_NAME(eAnimEvent.ePreviousAnimClip))
		eAnimEvent.ePreviousAnimClip = eAnimClip
		RESET_NET_TIMER(eAnimEvent.sAnimEventSpamTimer)
	ENDIF
	
	IF bSendEvent
		INT iPlayerFlags = SPECIFIC_PLAYER(PLAYER_ID())
		
		IF iPlayerFlags != -1
			PRINTLN("[AM_ARC_CAB] - PLAY_ARCADE_CABINET_ANIMATION - sending event")
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
			eAnimEvent.bEventSent = TRUE
		ELSE
			PRINTLN("[AM_ARC_CAB] - PLAY_ARCADE_CABINET_ANIMATION - iPlayerFlags is invalid")
		ENDIF
	ELSE
		PRINTLN("[AM_ARC_CAB] - PLAY_ARCADE_CABINET_ANIMATION - bSendEvent false")
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Arcade cabinet Claw crane event								║			
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_CLAW_CRANE_ANIM
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bPrizeAnim
	BOOL bBoth
	FLOAT fPrizeInitialHeading
	VECTOR vPrizeInitialCoords
ENDSTRUCT

PROC STOP_CLAW_CRANE_PROP_ANIM(BOOL bPrizeAnim, BOOL bBoth, VECTOR vPrizeInitialCoords, FLOAT fPrizeInitialHeading)
	
	//Common data
	SCRIPT_EVENT_DATA_CLAW_CRANE_ANIM Event
	Event.Details.Type 				= SCRIPT_EVENT_STOP_CLAW_ANIM
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.bPrizeAnim				= bPrizeAnim
	Event.bBoth						= bBoth
	Event.vPrizeInitialCoords		= vPrizeInitialCoords
	Event.fPrizeInitialHeading		= fPrizeInitialHeading

	PRINTLN("[AM_ARC_CAB] - STOP_CLAW_CRANE_PROP_ANIM bPrizeAnim: ", bPrizeAnim, " bBoth: ", bBoth, " vPrizeInitialCoords: ", vPrizeInitialCoords, " fPrizeInitialHeading: ", fPrizeInitialHeading)
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT()
	
	IF iPlayerFlags != -1
		PRINTLN("[AM_ARC_CAB] - STOP_CLAW_CRANE_PROP_ANIM - sending event")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		PRINTLN("[AM_ARC_CAB] - STOP_CLAW_CRANE_PROP_ANIM - iPlayerFlags is invalid")
	ENDIF

ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Arcade cabinet AI Context event								║			
//╚═════════════════════════════════════════════════════════════════════════════╝
STRUCT SCRIPT_EVENT_DATA_ARCADE_CABINET_AI_CONTEXT
	STRUCT_EVENT_COMMON_DETAILS Details
	TEXT_LABEL_63 stContext, stPreviousContext
	SPEECH_PARAMS spParams
	ARCADE_CAB_MANAGER_SLOT sCabinetSlot
	ARCADE_CABINETS eArcadeCabinet
	BOOL bOverNetwork = FALSE
	BOOL bUseConvo = FALSE
ENDSTRUCT

PROC PLAY_ARCADE_CABINET_AI_CONTEXT(ARCADE_CABINET_AI_CONTEXT_STRUCT &sAIContextDetail, BOOL bOverNetwork)
	//Common data
	SCRIPT_EVENT_DATA_ARCADE_CABINET_AI_CONTEXT Event
	Event.Details.Type 				= SCRIPT_EVENT_PLAY_ARCADE_CABINET_AI_CONTEXT
	Event.Details.FromPlayerIndex 	= PLAYER_ID()
	Event.stContext 				= sAIContextDetail.stContext		
	Event.spParams					= sAIContextDetail.spParams
	Event.bOverNetwork				= bOverNetwork
	Event.sCabinetSlot				= sAIContextDetail.sCabinetSlot
	Event.eArcadeCabinet			= sAIContextDetail.eArcadeCabinet
	Event.bUseConvo					= sAIContextDetail.bUseConvo
	
	DEBUG_PRINTCALLSTACK()
	
	PRINTLN("[AM_ARC_CAB] - PLAY_ARCADE_CABINET_AI_CONTEXT stContext: ", sAIContextDetail.stContext, " stParams: ", sAIContextDetail.spParams, " overNetwork: ", bOverNetwork,
			" Slot: ", sAIContextDetail.sCabinetSlot, " cabinet type: ", GET_ARCADE_CABINET_NAME(Event.eArcadeCabinet), " bUseConvo: ", sAIContextDetail.bUseConvo)
	
	IF NOT HAS_NET_TIMER_STARTED(sAIContextDetail.sAIContextEventSpamTimer)
		START_NET_TIMER(sAIContextDetail.sAIContextEventSpamTimer)
	ENDIF
	
	BOOL bSendEvent = TRUE
	
	IF ARE_STRINGS_EQUAL(sAIContextDetail.stPreviousContext, Event.stContext)
		IF HAS_NET_TIMER_STARTED(sAIContextDetail.sAIContextEventSpamTimer)
		AND NOT HAS_NET_TIMER_EXPIRED(sAIContextDetail.sAIContextEventSpamTimer, 1000)
			bSendEvent = FALSE
		ELSE	
			RESET_NET_TIMER(sAIContextDetail.sAIContextEventSpamTimer)
		ENDIF
	ELSE
		PRINTLN("[AM_ARC_CAB] - PLAY_ARCADE_CABINET_AI_CONTEXT new context: ", Event.stContext, " previous: ", sAIContextDetail.stPreviousContext)
		sAIContextDetail.stPreviousContext = Event.stContext
		RESET_NET_TIMER(sAIContextDetail.sAIContextEventSpamTimer)
	ENDIF
	
	sAIContextDetail.bEventSent = FALSE
	
	IF bSendEvent
		
		INT iPlayerFlags = SPECIFIC_PLAYER(PLAYER_ID())
		
		IF bOverNetwork
			iPlayerFlags = ALL_PLAYERS(TRUE)
		ENDIF
		
		IF iPlayerFlags != 0
			PRINTLN("[AM_ARC_CAB] - PLAY_ARCADE_CABINET_AI_CONTEXT - sending event")
			sAIContextDetail.bEventSent = TRUE
			SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
		ELSE
			PRINTLN("[AM_ARC_CAB] - PLAY_ARCADE_CABINET_AI_CONTEXT - iPlayerFlags is invalid")
		ENDIF
	ELSE
		PRINTLN("[AM_ARC_CAB] - PLAY_ARCADE_CABINET_AI_CONTEXT - bSendEvent false")
	ENDIF
ENDPROC

//╔═════════════════════════════════════════════════════════════════════════════╗
//║					Update Arcade cabinet event									║			
//╚═════════════════════════════════════════════════════════════════════════════╝

/// PURPOSE:
///    Update arcade cabinet props
PROC UPDATE_ARCADE_CABINET_PROPS(BOOL bIncludeLocalPlayer)
	//Common data
	STRUCT_EVENT_COMMON_DETAILS Event
	Event.Type 				= SCRIPT_EVENT_UPDATE_ARCADE_CABINET_PROPS
	Event.FromPlayerIndex 	= PLAYER_ID()

	INT iPlayerFlags = ALL_PLAYERS(bIncludeLocalPlayer)
	
	IF iPlayerFlags != 0
		PRINTLN("[AM_ARC_CAB] - UPDATE_ARCADE_CABINET_PROPS - sending event")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)
	ELSE
		PRINTLN("[AM_ARC_CAB] - UPDATE_ARCADE_CABINET_PROPS - iPlayerFlags is invalid")
	ENDIF
ENDPROC
#ENDIF


// ═════════════════╡  BETTING STRUCTS  ╞═════════════════

STRUCT EVENT_STRUCT_PLAYER_AVAILABLE_FOR_BETTING
	STRUCT_EVENT_COMMON_DETAILS 	Details
	BETTING_ID						bettingID
	INT								iStatValue
	BOOL							bTeamBetting
	INT								iTeam
	BOOL							bTutorial
ENDSTRUCT

STRUCT EVENT_STRUCT_PLAYER_LEFT_BETTING
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

STRUCT EVENT_STRUCT_BETTING_POOL_LOCKED
	STRUCT_EVENT_COMMON_DETAILS		Details
	BETTING_ID						bettingID
ENDSTRUCT

STRUCT EVENT_STRUCT_BETTING_VIRTUAL_CASH_BET
	STRUCT_EVENT_COMMON_DETAILS		Details
	INT								iBettingIndex
	INT								iCashDelta
ENDSTRUCT

STRUCT EVENT_STRUCT_BETTING_VIRTUAL_CASH_REJECTED
	STRUCT_EVENT_COMMON_DETAILS		Details
	INT								iBettingIndex
	INT								iCashDelta
ENDSTRUCT


#IF IS_DEBUG_BUILD
STRUCT EVENT_STRUCT_DEBUG_TOGGLE_BETTING
	STRUCT_EVENT_COMMON_DETAILS	Details
ENDSTRUCT
#ENDIF

// ═════════════════╡  FM CORONA  ╞═════════════════

STRUCT EVENT_STRUCT_CORONA_PLAYER_ANIM
	STRUCT_EVENT_COMMON_DETAILS	Details
	INT iAnimationType
	INT iAnimation
	INT iVoteID
	BOOL bPlaying
ENDSTRUCT

STRUCT EVENT_STRUCT_CORONA_PLAYER_OUTFIT
	STRUCT_EVENT_COMMON_DETAILS	Details
	INT iOutfit
	INT iMask
	INT iTeam
	BOOL bForceEquip
ENDSTRUCT

STRUCT EVENT_STRUCT_CORONA_PLAYER_OUTFIT_FROM_LEADER
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iOutfit
	INT iMask
	INT iTeam
	PLAYER_INDEX playerID
	BOOL bStyleChange
ENDSTRUCT

STRUCT EVENT_STRUCT_CORONA_ACCESS_LEVEL_FROM_LEADER
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iAccessLevel
ENDSTRUCT

STRUCT EVENT_STRUCT_CORONA_OUTFIT_STYLE_FROM_MEMBER
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iStyle
	INT iTeam
	PLAYER_INDEX playerID
ENDSTRUCT

STRUCT EVENT_STRUCT_CORONA_MASK_STYLE_FROM_MEMBER
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iStyle
	INT iTeam
	PLAYER_INDEX playerID
ENDSTRUCT

STRUCT EVENT_STRUCT_CORONA_VERSUS_OUTFIT_CHANGE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iOutfitStyle
	BOOL bBackgroundUpdate
	#IF IS_DEBUG_BUILD
	INT iUniqueId
	#ENDIF
ENDSTRUCT

STRUCT EVENT_STRUCT_CORONA_VERSUS_OUTFIT_UPDATED
	STRUCT_EVENT_COMMON_DETAILS Details
	#IF IS_DEBUG_BUILD
	INT iUniqueId
	#ENDIF
ENDSTRUCT


STRUCT EVENT_STRUCT_MOCAP_PLAYER_ANIM
	STRUCT_EVENT_COMMON_DETAILS	Details
	INT iAnimationType
	INT iAnimation
	BOOL bPlaying
ENDSTRUCT

STRUCT EVENT_STRUCT_CORONA_PLAYER_PURCHASED_ARMOR
	STRUCT_EVENT_COMMON_DETAILS Details
	PED_COMP_NAME_ENUM eArmorType
ENDSTRUCT

STRUCT EVENT_STRUCT_TRANSITION_PARAMETER_CHANGED
	STRUCT_EVENT_COMMON_DETAILS	Details
	STRUCT_TRANSITION_PARAMETER_EVENT Params
	INT iFrame
ENDSTRUCT

STRUCT EVENT_STRUCT_YOURE_GOING_TO_FOLLOW_ME
	STRUCT_EVENT_COMMON_DETAILS	Details
	STRUCT_FOLLOW_INVITE_EVENT sFollowHandle
ENDSTRUCT

STRUCT EVENT_STRUCT_CORONA_SYNC_TEAMS
	STRUCT_EVENT_COMMON_DETAILS	Details
	INT iYourTeam
	INT iYourRole
	BOOL bForceLaunching
ENDSTRUCT

STRUCT EVENT_STRUCT_PLAYER_WARPED_BECAUSE_OF_INVITE
	STRUCT_EVENT_COMMON_DETAILS	Details
	TEXT_LABEL_63 tl63MissionName
	INT iMissionType
	INT iSubMissionType
ENDSTRUCT
// ═════════════════╡  CORONA POSITIONING STRUCT  ╞═════════════════

STRUCT EVENT_STRUCT_PLAYER_CLEAR_CORONA_SLOT
	STRUCT_EVENT_COMMON_DETAILS 	Details
ENDSTRUCT

STRUCT EVENT_STRUCT_PLAYER_JOINED_VOTE
	STRUCT_EVENT_COMMON_DETAILS 	Details
	INT								iVoteID
ENDSTRUCT

#IF IS_DEBUG_BUILD
STRUCT EVENT_STRUCT_DEBUG_TOGGLE_CORONA_POS
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

STRUCT EVENT_STRUCT_DEBUG_TOGGLE_CORONA_TIMER
	STRUCT_EVENT_COMMON_DETAILS Details
	BOOL bDisableTimer
	INT iVoteID
ENDSTRUCT

#ENDIF

STRUCT EVENT_STRUCT_CORONA_SCTV_LAUNCH_JOB
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_HIT_TARGET
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iProp
ENDSTRUCT

PROC BROADCAST_PLAYER_HIT_TARGET(INT iProp)
	SCRIPT_EVENT_DATA_HIT_TARGET Event
	Event.Details.Type = SCRIPT_EVENT_HIT_TARGET
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iProp = iProp
	
	#IF IS_DEBUG_BUILD	
		STRING sNameSender = GET_PLAYER_NAME(PLAYER_ID())
		PRINTLN("[CS_FINISH] BROADCAST_PLAYER_HIT_TARGET, ", sNameSender, " has hit the target ",Event.iProp) 
	#ENDIF

	INT iPlayerFlags = ALL_PLAYERS(FALSE,FALSE)
	IF NOT (iPlayerFlags = 0)
		PRINTLN("[CS_FULL_UPDATE] BROADCAST_PLAYER_HIT_TARGET ")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("[CS_FULL_UPDATE] BROADCAST_PLAYER_HIT_TARGET - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_RESET_TARGETS
	STRUCT_EVENT_COMMON_DETAILS Details
ENDSTRUCT

PROC BROADCAST_PLAYER_RESET_TARGETS()
	SCRIPT_EVENT_DATA_RESET_TARGETS Event
	Event.Details.Type = SCRIPT_EVENT_RESET_TARGETS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	
	#IF IS_DEBUG_BUILD	
		STRING sNameSender = GET_PLAYER_NAME(PLAYER_ID())
		PRINTLN("[CS_FINISH] BROADCAST_PLAYER_RESET_TARGETS, ", sNameSender) 
	#ENDIF

	INT iPlayerFlags = ALL_PLAYERS(TRUE,FALSE)
	IF NOT (iPlayerFlags = 0)
		PRINTLN("[CS_FULL_UPDATE] BROADCAST_PLAYER_RESET_TARGETS ")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("[CS_FULL_UPDATE] BROADCAST_PLAYER_RESET_TARGETS - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_SET_ARENA_ANNOUNCER_SOUND_BS
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iType
	INT iSoundBSToPlay
	BOOL bPlayOnce
	BOOL bMakeSingular
	BOOL bMakePlural
	BOOL bInterrupt
ENDSTRUCT

PROC BROADCAST_SET_ARENA_ANNOUNCER_SOUND_BS_EVENT(INT iType, INT iSoundBSToPlay, BOOL bPlayOnce = FALSE, BOOL bMakeSingular = FALSE, BOOL bMakePlural = FALSE, BOOL bInterrupt = FALSE)
	SCRIPT_EVENT_DATA_SET_ARENA_ANNOUNCER_SOUND_BS Event
	Event.Details.Type = SCRIPT_EVENT_SET_ARENA_ANNOUNCER_SOUND_BS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iType = iType
	Event.iSoundBSToPlay = iSoundBSToPlay
	Event.bPlayOnce = bPlayOnce
	Event.bMakeSingular = bMakeSingular
	Event.bMakePlural = bMakePlural
	Event.bInterrupt = bInterrupt
	
	PRINTLN("[LM][ArenaAnnouncer] -----------------------BROADCAST_SET_ARENA_ANNOUNCER_SOUND_BS_EVENT---------------------")
	PRINTLN("[LM][ArenaAnnouncer][BROADCAST_SET_ARENA_ANNOUNCER_SOUND_BS_EVENT] - iType: ", iType, " iSoundBSToPlay: ", iSoundBSToPlay, " bPlayOnce: ", bPlayOnce, " bMakeSingular: ", bMakeSingular, " bMakePlural: ", bMakePlural, " bInterrupt: ", bInterrupt)

	INT iPlayerFlags = ALL_PLAYERS(TRUE,FALSE)
	IF NOT (iPlayerFlags = 0)
		PRINTLN("[LM][ArenaAnnouncer] BROADCAST_SET_ARENA_ANNOUNCER_SOUND_BS_EVENT ")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("[LM][ArenaAnnouncer] BROADCAST_SET_ARENA_ANNOUNCER_SOUND_BS_EVENT - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_FMMC_CLEAR_FIRE_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	VECTOR vPos
	FLOAT iRadius
ENDSTRUCT

PROC BROADCAST_FMMC_CLEAR_FIRE_EVENT(VECTOR vPos, FLOAT iRadius)
	SCRIPT_EVENT_DATA_FMMC_CLEAR_FIRE_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_FMMC_CLEAR_FIRE_EVENT
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iRadius = iRadius
	Event.vPos = vPos

	PRINTLN("-----------------------BROADCAST_FMMC_CLEAR_FIRE_EVENT---------------------")
	PRINTLN("[BROADCAST_FMMC_CLEAR_FIRE_EVENT] - vPos: ", vPos, " iRadius: ", iRadius)

	INT iPlayerFlags = ALL_PLAYERS(TRUE, FALSE)
	IF NOT (iPlayerFlags = 0)
		PRINTLN("BROADCAST_FMMC_CLEAR_FIRE_EVENT ")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("BROADCAST_FMMC_CLEAR_FIRE_EVENT - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_DATA_NOTIFY_DAMAGER_OF_FIRE_TRAP_DAMAGE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTrapInstigator
ENDSTRUCT

PROC BROADCAST_NOTIFY_DAMAGER_OF_FIRE_TRAP_DAMAGE(INT iTrapActivator)	// Need to specify damager playerID so only they process
	SCRIPT_EVENT_DATA_NOTIFY_DAMAGER_OF_FIRE_TRAP_DAMAGE Event
	Event.Details.Type = SCRIPT_EVENT_NOTIFY_DAMAGER_OF_FIRE_TRAP_DAMAGE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTrapInstigator = iTrapActivator
	PRINTLN("[MJL] -----------------------BROADCAST_NOTIFY_DAMAGER_OF_FIRE_TRAP_DAMAGE---------------------")
	PRINTLN("[MJL][BROADCAST_NOTIFY_DAMAGER_OF_FIRE_TRAP_DAMAGE] - iTrapActivator: ", iTrapActivator)
	
	INT_TO_PLAYERINDEX(iTrapActivator)
	INT iPlayerFlags = SPECIFIC_PLAYER(INT_TO_PLAYERINDEX(iTrapActivator))	//	 Broadcast just to specific player who is activating the fire trap
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("[MJL] BROADCAST_NOTIFY_DAMAGER_OF_FIRE_TRAP_DAMAGE ")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("[MJL] BROADCAST_NOTIFY_DAMAGER_OF_FIRE_TRAP_DAMAGE - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF

ENDPROC

// Used to mark a vehicle as having had its wanted level set on theft, used to avoid it being set again later
STRUCT SCRIPT_EVENT_DATA_NOTIFY_WANTED_SET_FOR_VEHICLE
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iVeh
ENDSTRUCT

PROC BROADCAST_NOTIFY_WANTED_SET_FOR_VEHICLE(INT iVeh)

SCRIPT_EVENT_DATA_NOTIFY_WANTED_SET_FOR_VEHICLE Event
	Event.Details.Type = SCRIPT_EVENT_NOTIFY_WANTED_SET_FOR_VEHICLE
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iVeh = iVeh
	PRINTLN("[MJL] -----------------------BROADCAST_NOTIFY_WANTED_SET_FOR_VEHICLE---------------------")
	PRINTLN("[MJL][BROADCAST_NOTIFY_WANTED_SET_FOR_VEHICLE] - iVeh: ", iVeh)
	
	INT iPlayerFlags = ALL_PLAYERS(TRUE)
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("[MJL] BROADCAST_NOTIFY_WANTED_SET_FOR_VEHICLE ")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("[MJL] BROADCAST_NOTIFY_WANTED_SET_FOR_VEHICLE - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF

ENDPROC

#IF FEATURE_CASINO_HEIST

STRUCT SCRIPT_EVENT_DATA_SET_CASINO_HEIST_MISSION_CONFIG_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	CASINO_HEIST_MISSION_CONFIGURATION_DATA	sData
ENDSTRUCT

PROC BROADCAST_SET_CASINO_HEIST_MISSION_CONFIG_DATA()
	SCRIPT_EVENT_DATA_SET_CASINO_HEIST_MISSION_CONFIG_DATA Event
	Event.Details.Type = SCRIPT_EVENT_SET_CASINO_HEIST_MISSION_CONFIG_DATA
	Event.Details.FromPlayerIndex = PLAYER_ID()
	COPY_SCRIPT_STRUCT(Event.sData, g_sCasinoHeistMissionConfigData, SIZE_OF(g_sCasinoHeistMissionConfigData))
	PRINTLN("[CASINO_HEIST] | BROADCAST_SET_CASINO_HEIST_MISSION_CONFIG_DATA - called")
	
	INT iPlayerFlags
	
	IF (GlobalplayerBD_FM[NATIVE_TO_INT(PLAYER_ID())].eCoronaStatus != CORONA_STATUS_IDLE)	// IS_PLAYER_IN_CORONA
		iPlayerFlags = ALL_PLAYERS_IN_MY_TRANSITION_SESSION(FALSE)
		PRINTLN("[CASINO_HEIST] | BROADCAST_SET_CASINO_HEIST_MISSION_CONFIG_DATA - In a corona, send to all players in my transition session")
	ELIF GB_IS_LOCAL_PLAYER_BOSS_OF_A_GANG()
		iPlayerFlags = ALL_PLAYERS_IN_MY_GANG(FALSE)
		PRINTLN("[CASINO_HEIST] | BROADCAST_SET_CASINO_HEIST_MISSION_CONFIG_DATA - Boss of a gang, send to all players in my gang")
	ELSE
		iPlayerFlags = 0
		PRINTLN("[CASINO_HEIST] | BROADCAST_SET_CASINO_HEIST_MISSION_CONFIG_DATA - No conditions, wont be broadcasting")
	ENDIF
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("[CASINO_HEIST] | BROADCAST_SET_CASINO_HEIST_MISSION_CONFIG_DATA ")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("[CASINO_HEIST] | BROADCAST_SET_CASINO_HEIST_MISSION_CONFIG_DATA - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_CASINO_PLAY_HEIST_CUTSCENE
	STRUCT_EVENT_COMMON_DETAILS Details
	CASINO_HEIST_FLOW_CUTSCENES eCutscene
ENDSTRUCT

STRUCT SCRIPT_EVENT_DATA_SCOPE_OUT_CASINO_MAIN_ENTRANCE_PHOTOGRAPHED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iMissionID
	INT iPhoto
	PLAYER_INDEX piWhoDunnit
ENDSTRUCT

PROC BROADCAST_CASINO_FM_MISSION_SCOPE_OUT_PHOTO_TAKEN(INT iPhoto, INT iMissionID)
	SCRIPT_EVENT_DATA_SCOPE_OUT_CASINO_MAIN_ENTRANCE_PHOTOGRAPHED Event
	Event.Details.Type = SCRIPT_EVENT_SCOPE_OUT_CASINO_MAIN_ENTRANCE_PHOTOGRAPHED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iMissionID = iMissionID
	Event.piWhoDunnit = PLAYER_ID()
	Event.iPhoto = iPhoto
	
	IF NOT (ALL_PLAYERS() = 0)
		PRINTLN("[GB_CASINO] - BROADCAST_CASINO_FM_MISSION_SCOPE_OUT_MAIN_ENTRANCE_PHOTO_TAKEN - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
	ELSE
		NET_PRINT("[GB_CASINO] - BROADCAST_CASINO_FM_MISSION_SCOPE_OUT_MAIN_ENTRANCE_PHOTO_TAKEN - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_VAULT_KEY_CARDS_2_OUTFIT_EQUIPED
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iMissionID
	PLAYER_INDEX piWhoDunnit
ENDSTRUCT

PROC BROADCAST_CASINO_FM_MISSION_VAULT_KEY_CARDS_2_OUTFIT_EQUIPED(INT iMissionID)
	SCRIPT_EVENT_DATA_VAULT_KEY_CARDS_2_OUTFIT_EQUIPED Event
	Event.Details.Type = SCRIPT_EVENT_VAULT_KEY_CARDS_2_OUTFIT_EQUIPED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iMissionID = iMissionID
	Event.piWhoDunnit = PLAYER_ID()
	
	IF NOT (ALL_PLAYERS() = 0)
		PRINTLN("[GB_CASINO] - BROADCAST_CASINO_FM_MISSION_VAULT_KEY_CARDS_2_OUTFIT_EQUIPED - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS())	
	ELSE
		NET_PRINT("[GB_CASINO] - BROADCAST_CASINO_FM_MISSION_VAULT_KEY_CARDS_2_OUTFIT_EQUIPED - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

#ENDIF

#IF FEATURE_COPS_N_CROOKS
STRUCT SCRIPT_EVENT_DATA_COPSCROOKS_GIVE_CROOK_HELD_CASH
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iCash
ENDSTRUCT
PROC BROADCAST_EVENT_COPSCROOKS_GIVE_CROOK_HELD_CASH(INT iCash)
	SCRIPT_EVENT_DATA_COPSCROOKS_GIVE_CROOK_HELD_CASH Event
	Event.Details.Type = SCRIPT_EVENT_COPSCROOKS_GIVE_CROOK_HELD_CASH
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iCash = iCash
	
	INT iPlayersFlag = SPECIFIC_PLAYER(Event.Details.FromPlayerIndex)
	
	IF iPlayersFlag != 0
		PRINTLN("[COPS_CROOKS] [CASH] BROADCAST_EVENT_COPSCROOKS_GIVE_CROOK_HELD_CASH - Event sent. Local player receiving $", Event.iCash)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		PRINTLN("[COPS_CROOKS] [CASH] BROADCAST_EVENT_COPSCROOKS_GIVE_CROOK_HELD_CASH - Event not sent. iPlayersFlag = 0.")
	ENDIF	
ENDPROC

STRUCT SCRIPT_EVENT_ARCADE_LOBBY_LEADER_LEAVING_LOBBY_ALONE
	STRUCT_EVENT_COMMON_DETAILS Details
	PLAYER_INDEX piSuccessor
ENDSTRUCT
#ENDIF

STRUCT SCRIPT_EVENT_DATA_COLLECT_COLLECTIBLE
	STRUCT_EVENT_COMMON_DETAILS Details
	CollectableType eCollectible
	INT iWhichCollectible
	BOOL bCollected
	BOOL bDelivered
	BOOL bPrintMessage
ENDSTRUCT

PROC BROADCAST_EVENT_COLLECT_COLLECTIBLE(CollectableType eCollectible, INT iWhichCollectible, BOOL bCollected, BOOL bPrintMessage = FALSE, BOOL bDelivered = FALSE)
	SCRIPT_EVENT_DATA_COLLECT_COLLECTIBLE Event
	Event.Details.Type = SCRIPT_EVENT_COLLECTIBLE_COLLECTED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.eCollectible = eCollectible
	Event.iWhichCollectible = iWhichCollectible
	Event.bCollected = bCollected
	Event.bDelivered = bDelivered
	Event.bPrintMessage = bPrintMessage

	INT iPlayersFlag = SPECIFIC_PLAYER(Event.Details.FromPlayerIndex)

	IF iPlayersFlag != 0
		PRINTLN("[KW Collectables] BROADCAST_EVENT_COLLECT_COLLECTIBLE - Event sent. ")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayersFlag)	
	ELSE
		PRINTLN("[KW Collectables] BROADCAST_EVENT_COLLECT_COLLECTIBLE - Event not sent. iPlayersFlag = 0.")
	ENDIF
ENDPROC

#IF IS_DEBUG_BUILD
STRUCT SCRIPT_EVENT_DATA_FM_CONTENT_MISSION_DEBUG
	STRUCT_EVENT_COMMON_DETAILS Details
	FM_CONTENT_MISSION_DEBUG_EVENT eDebugEvent
	STRUCT_MISSION_INSTANCE_INFO sMII
ENDSTRUCT

FUNC STRING GET_FM_CONTENT_MISSION_DEBUG_EVENT_STRING(FM_CONTENT_MISSION_DEBUG_EVENT eEvent)
	SWITCH eEvent
		CASE FM_CONTENT_DEBUG_J_SKIP		RETURN "FM_CONTENT_DEBUG_J_SKIP"
		CASE FM_CONTENT_DEBUG_S_PASS		RETURN "FM_CONTENT_DEBUG_S_PASS"
		CASE FM_CONTENT_DEBUG_F_FAIL		RETURN "FM_CONTENT_DEBUG_F_FAIL"
		CASE FM_CONTENT_DEBUG_T_KILL		RETURN "FM_CONTENT_DEBUG_T_KILL"
	ENDSWITCH
	RETURN "INVALID"
ENDFUNC

PROC BROADCAST_EVENT_FM_CONTENT_MISSION_DEBUG(FM_CONTENT_MISSION_DEBUG_EVENT eDebugEvent, STRUCT_MISSION_INSTANCE_INFO sMII)
	SCRIPT_EVENT_DATA_FM_CONTENT_MISSION_DEBUG EventData
	EventData.eDebugEvent = eDebugEvent
	EventData.Details.FromPlayerIndex = PLAYER_ID()
	EventData.Details.Type = SCRIPT_EVENT_FM_CONTENT_MISSION_DEBUG
	EventData.sMII = sMII
	
	INT iPlayerFlags = ALL_PLAYERS_ON_SCRIPT(TRUE)
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, EventData, SIZE_OF(EventData), iPlayerFlags)
ENDPROC
#ENDIF

 // #IF FEATURE_TARGET_RACES

#IF FEATURE_HEIST_ISLAND

STRUCT SCRIPT_EVENT_DATA_SET_HEIST_ISLAND_MISSION_CONFIG_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	HEIST_ISLAND_CONFIG	sData
ENDSTRUCT

PROC BROADCAST_SET_HEIST_ISLAND_MISSION_CONFIG_DATA()
	IF NOT GB_IS_LOCAL_PLAYER_BOSS_OF_A_GANG()
		PRINTLN("[HEIST_ISLAND] | BROADCAST_SET_HEIST_ISLAND_MISSION_CONFIG_DATA - Not the boss of a gang, not sending.")
		EXIT
	ENDIF

	SCRIPT_EVENT_DATA_SET_HEIST_ISLAND_MISSION_CONFIG_DATA Event
	Event.Details.Type = SCRIPT_EVENT_SET_HEIST_ISLAND_CONFIG_DATA
	Event.Details.FromPlayerIndex = PLAYER_ID()
	COPY_SCRIPT_STRUCT(Event.sData, g_sHeistIslandConfig, SIZE_OF(g_sHeistIslandConfig))
	PRINTLN("[HEIST_ISLAND] | BROADCAST_SET_HEIST_ISLAND_MISSION_CONFIG_DATA - called")
	
	INT iPlayerFlags
	
	iPlayerFlags = ALL_PLAYERS_IN_MY_GANG()
	PRINTLN("[HEIST_ISLAND] | BROADCAST_SET_HEIST_ISLAND_MISSION_CONFIG_DATA - iPlayerFlags = ALL_PLAYERS_IN_MY_GANG()")
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("[HEIST_ISLAND] | BROADCAST_SET_HEIST_ISLAND_MISSION_CONFIG_DATA - Send event")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("[HEIST_ISLAND] | BROADCAST_SET_HEIST_ISLAND_MISSION_CONFIG_DATA - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_DATA_NHPG_PREP_COMPLETION
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iType
	INT iItemType
ENDSTRUCT

PROC BROADCAST_NHPG_PREP_COMPLETION(INT iType, INT iItemType = -1)
	SCRIPT_EVENT_DATA_NHPG_PREP_COMPLETION Event
	Event.Details.Type = SCRIPT_EVENT_NHPG_PREP_COMPLETED
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iType = iType
	Event.iItemType = iItemType
	PRINTLN("[NHPG] | BROADCAST_NHPG_PREP_COMPLETION - called with type ", iType," and item type ", iItemType)
	
	INT iPlayerFlags
	
	iPlayerFlags = ALL_PLAYERS()
	PRINTLN("[NHPG] | BROADCAST_NHPG_PREP_COMPLETION - iPlayerFlags = ALL_PLAYERS()")
	
	IF NOT (iPlayerFlags = 0)
		PRINTLN("[NHPG] | BROADCAST_NHPG_PREP_COMPLETION - Send event")
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	#IF IS_DEBUG_BUILD	
	ELSE
		PRINTLN("[NHPG] | BROADCAST_NHPG_PREP_COMPLETION - playerflags = 0 so not broadcasting") 
	#ENDIF
	ENDIF
ENDPROC

#ENDIF

// ══════════════════════════════════════════════════════════════════╡  OTHER STUFF  ╞══════════════════════════════════════════════════════════════════════


//// PURPOSE:
 ///    Takes a peek into the Q and checks if an event exists.
 /// PARAMS:
 ///    event - The event to check.
 /// RETURNS:
 ///    True if we have an event of type event in this frames event Q.
FUNC BOOL RECEIVED_EVENT(EVENT_NAMES eventId)
	IF GET_EVENT_EXISTS(SCRIPT_EVENT_QUEUE_NETWORK, eventId)	
		RETURN TRUE
	ENDIF
	RETURN FALSE
ENDFUNC

/// PURPOSE:
///    Terminates this script and does any other necessary general cleanup
PROC TERMINATE_THIS_MULTIPLAYER_THREAD(SCRIPT_TIMER theTimer)
	NET_PRINT_TIME() NET_PRINT_THREAD_ID() NET_PRINT(GET_THIS_SCRIPT_NAME())
	NET_PRINT(" TERMINATE_THIS_MULTIPLAYER_THREAD ()") NET_NL()
	IF theTimer.bInitialisedTimer
		IF ABSI(GET_TIME_DIFFERENCE(GET_NETWORK_TIME(),theTimer.Timer)) >= 1000
			NET_PRINT(" TERMINATE_THIS_MULTIPLAYER_THREAD () setting mission finished") NET_NL()
			NETWORK_SET_MISSION_FINISHED()
		ENDIF
	ENDIF
	TERMINATE_THIS_THREAD()
ENDPROC

/// PURPOSE:
///    Terminates this script and does any other necessary general cleanup
PROC TERMINATE_THIS_MULTIPLAYER_THREAD_NO_ARGS()
	NET_PRINT_TIME() NET_PRINT_THREAD_ID() NET_PRINT(GET_THIS_SCRIPT_NAME())
	NET_PRINT(" TERMINATE_THIS_MULTIPLAYER_THREAD_NO_ARGS()") NET_NL()
	TERMINATE_THIS_THREAD()
ENDPROC

// ********************************************************************************************************************
// 				GLOBAL EVENTS WHICH NEED TO BE PROCESSED BY ALL SCRIPTS
// ********************************************************************************************************************



FUNC BOOL IS_SCRIPT_BAILS_PROCESSING()
	RETURN g_b_is_ScriptBailProcessing
ENDFUNC


PROC SET_SCRIPT_BAILS_PROCESSING(BOOL bHasEntered)
	#IF IS_DEBUG_BUILD
		DEBUG_PRINTCALLSTACK()
		IF bHasEntered
			NET_NL()NET_PRINT("<<<SET_SCRIPT_BAILS_PROCESSING = TRUE >>> ")
		ELSE
			NET_NL()NET_PRINT("<<<SET_SCRIPT_BAILS_PROCESSING = FALSE >>> ")
		ENDIF
	#ENDIF
	g_b_is_ScriptBailProcessing = bHasEntered
ENDPROC



/// PURPOSE:
///    Checks to see if we have RECEIVED a match end event, the game is not in progress, or the main
///    game mode script is not running, and if so, kills the script.
FUNC BOOL SHOULD_THIS_MULTIPLAYER_THREAD_TERMINATE()

	#IF IS_DEBUG_BUILD
		PROCESS_BOTS()
	#ENDIF
	
	IF g_Private_IsMultiplayerCreatorRunning = FALSE
		IF NOT NETWORK_IS_GAME_IN_PROGRESS()	
			NET_PRINT_TIME() NET_PRINT_THREAD_ID() NET_PRINT(GET_THIS_SCRIPT_NAME())
			NET_PRINT(" SHOULD_THIS_MULTIPLAYER_SCRIPT_TERMINATE NETWORK_IS_GAME_IN_PROGRESS() = FALSE, bail.") NET_NL()
			RETURN(TRUE)
		ENDIF
	ENDIF
	
	IF SHOULD_TRANSITION_SESSION_KILL_ALL_MP_SCRIPTS()
		NET_PRINT_TIME() NET_PRINT_THREAD_ID() NET_PRINT(GET_THIS_SCRIPT_NAME())
		NET_PRINT(" SHOULD_THIS_MULTIPLAYER_SCRIPT_TERMINATE SHOULD_TRANSITION_SESSION_KILL_ALL_MP_SCRIPTS = TRUE") NET_NL()		
		RETURN(TRUE)
	ENDIF
	
	IF g_b_MainTransitionKillFreemodeScripts
		NET_PRINT_TIME() NET_PRINT_THREAD_ID() NET_PRINT(GET_THIS_SCRIPT_NAME())
		NET_PRINT(" SHOULD_THIS_MULTIPLAYER_SCRIPT_TERMINATE IS_MAINTRANSITION_KILLING_MULTIPLAYER_SCRIPTS = TRUE") NET_NL()		
		RETURN(TRUE)	
	ENDIF
	
	
	IF IS_SCRIPT_BAILS_PROCESSING()
		NET_PRINT_TIME() NET_PRINT_THREAD_ID() NET_PRINT(GET_THIS_SCRIPT_NAME())
		NET_PRINT(" SHOULD_THIS_MULTIPLAYER_SCRIPT_TERMINATE IS_SCRIPT_BAILS_PROCESSING = TRUE") NET_NL()		
		RETURN(TRUE)
	ENDIF
	
	IF RECEIVED_EVENT(EVENT_NETWORK_END_MATCH)	
		//Don't kill if the transition sesssions don't want that
		IF NOT IS_TRANSITION_SESSIONS_ACCEPTING_INVITE_WAIT_FOR_CLEAN()
			NET_PRINT_TIME() NET_PRINT_THREAD_ID() NET_PRINT(GET_THIS_SCRIPT_NAME())
			NET_PRINT(" SHOULD_THIS_MULTIPLAYER_SCRIPT_TERMINATE RECEIVED match end event") NET_NL()		
			RETURN(TRUE)
		#IF IS_DEBUG_BUILD
		ELSE
			NET_PRINT("[TS] SHOULD_THIS_MULTIPLAYER_SCRIPT_TERMINATE RECEIVED match end event - IGNORING - IS_TRANSITION_SESSIONS_ACCEPTING_INVITE_WAIT_FOR_CLEAN") NET_NL()		
		#ENDIF		
		ENDIF
	ENDIF
		
	IF RECEIVED_EVENT(EVENT_NETWORK_SESSION_END)	
		NET_PRINT_TIME() NET_PRINT_THREAD_ID() NET_PRINT(GET_THIS_SCRIPT_NAME())
		NET_PRINT(" SHOULD_THIS_MULTIPLAYER_SCRIPT_TERMINATE RECEIVED session end event") NET_NL()		
		RETURN(TRUE)
	ENDIF	
	
	IF NOT NETWORK_IS_SIGNED_ONLINE() // is player signed into psn network
		NET_PRINT_TIME() NET_PRINT_THREAD_ID() NET_PRINT(GET_THIS_SCRIPT_NAME())
		NET_PRINT(" SHOULD_THIS_MULTIPLAYER_SCRIPT_TERMINATE - NETWORK_IS_SIGNED_ONLINE = FALSE") NET_NL()
		RETURN(TRUE)
	ENDIF
	
	//IF GET_NUMBER_OF_THREADS_RUNNING_THIS_SCRIPT(GET_LAUNCH_SCRIPT()) = 0
	IF GET_HASH_OF_LAUNCH_SCRIPT_NAME_SCRIPT() != 0
	#IF FEATURE_FREEMODE_ARCADE
	AND NOT (g_Private_HudState = HUD_STATE_CNC_LOBBY)
	#ENDIF	
	
		IF GET_NUMBER_OF_THREADS_RUNNING_THE_SCRIPT_WITH_THIS_HASH(GET_HASH_OF_LAUNCH_SCRIPT_NAME_SCRIPT()) = 0
			NET_PRINT_TIME() NET_PRINT(GET_LAUNCH_SCRIPT_NAME())
			NET_PRINT_TIME() NET_PRINT_THREAD_ID() NET_PRINT(GET_THIS_SCRIPT_NAME())
			NET_PRINT(" SHOULD_THIS_MULTIPLAYER_SCRIPT_TERMINATE Launch script not running, bail.") NET_NL()
			RETURN(TRUE)	
		ENDIF
	ENDIF
	
//	IF FM_EVENT_IS_PLAYER_ON_ANY_FM_EVENT(PLAYER_ID())
//		IF !FM_EVENT_IS_PLAYER_CRITICAL_TO_FM_EVENT(PLAYER_ID())
//			IF FM_EVENT_PASSIVE_MODE_WARNING_ACTIVE(PLAYER_ID())
//				IF g_MultiplayerSettings.g_bPassiveModeSetting
//					SET_FREEMODE_AMBIENT_EVENT_PASSIVE_MODE_WARNING_FLAG(FALSE)
//					NET_PRINT_TIME() NET_PRINT_THREAD_ID() NET_PRINT(GET_THIS_SCRIPT_NAME())
//					NET_PRINT(" SHOULD_THIS_MULTIPLAYER_SCRIPT_TERMINATE RECEIVED session end event. Passive mode is active, Freemode Event should terminate") NET_NL()		
//					RETURN(TRUE)
//				ENDIF
//			ENDIF
//		ENDIF
//	ENDIF

	RETURN(FALSE)
	
	
ENDFUNC

// called inside PROCESS_TICKER_MESSAGE_EVENT
FUNC BOOL ShouldBGScriptInterceptCodeEvent(EVENT_NAMES eEvent)
	INT i
	INT iEvent = ENUM_TO_INT(eEvent)
	REPEAT g_sBlockedEventsCatchAll.iNumberOfBlockedCodeEvents i
		IF (g_sBlockedEventsCatchAll.iListOfBlockedCodeEvents[i] = iEvent)
			PRINTLN("ShouldBGScriptInterceptGeneralEvent - iEvent = ", iEvent)
			RETURN TRUE
		ENDIF
	ENDREPEAT
	RETURN FALSE
ENDFUNC


// ══════════════════════════════════════════════════════════════════╡  DEBUG FUNCTIONS  ╞══════════════════════════════════════════════════════════════════════



#IF IS_DEBUG_BUILD
//╔═════════════════════════════════════════════════════════════════════════════╗
//║							DEBUG MENU EVENT																
//╚═════════════════════════════════════════════════════════════════════════════╝

// ═════════════════╡  DATA STRUCTURES  ╞═════════════════
STRUCT SCRIPT_EVENT_DATA_DEBUG_MENU_EVENT
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iEventID
ENDSTRUCT

PROC BROADCAST_DEBU_MENU_EVENT(INT iPlayerFlags,INT iEventID)
	SCRIPT_EVENT_DATA_DEBUG_MENU_EVENT Event
	Event.Details.Type = SCRIPT_EVENT_DEBUG_MENU_EVENT
	Event.iEventID =  iEventID
	Event.Details.FromPlayerIndex = PLAYER_ID()
	IF NOT (iPlayerFlags = 0)
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), iPlayerFlags)	
	ELSE
		NET_PRINT("BROADCAST_DEBU_MENU_EVENT - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF	
ENDPROC

FUNC STRING GET_EVENT_STRING(EVENT_NAMES inEvent)
	SWITCH inEvent
		CASE EVENT_NETWORK_PLAYER_JOIN_SESSION				RETURN("PLAYER_JOIN_SESSION")
		CASE EVENT_NETWORK_PLAYER_LEFT_SESSION				RETURN("PLAYER_LEFT_SESSION")
		CASE EVENT_NETWORK_PLAYER_JOIN_SCRIPT				RETURN("PLAYER_JOIN_SCRIPT")
		CASE EVENT_NETWORK_PLAYER_LEFT_SCRIPT				RETURN("PLAYER_LEFT_SCRIPT")
		CASE EVENT_NETWORK_SESSION_START					RETURN("SESSION_START")
		CASE EVENT_NETWORK_START_MATCH						RETURN("START_MATCH")
		CASE EVENT_NETWORK_END_MATCH						RETURN("END_MATCH")
		CASE EVENT_NETWORK_SESSION_END						RETURN("SESSION_END")
		CASE EVENT_NETWORK_PLAYER_SPAWN						RETURN("PLAYER_SPAWN")			
		CASE EVENT_NETWORK_PLAYER_COLLECTED_PICKUP			RETURN("PLAYER_COLLECTED_PICKUP")
		CASE EVENT_NETWORK_PLAYER_COLLECTED_AMBIENT_PICKUP	RETURN("PLAYER_COLLECTED_AMBIENT_PICKUP")
		CASE EVENT_NETWORK_INVITE_ARRIVED					RETURN("INVITE_ARRIVED")
		CASE EVENT_NETWORK_INVITE_ACCEPTED					RETURN("INVITE_ACCEPTED")
		CASE EVENT_NETWORK_INVITE_CONFIRMED					RETURN("INVITE_CONFIRMED")
		CASE EVENT_NETWORK_SUMMON							RETURN("SUMMON")
		CASE EVENT_NETWORK_SCRIPT_EVENT						RETURN("SCRIPT_EVENT")
		CASE EVENT_NETWORK_PLAYER_SIGNED_OFFLINE			RETURN("PLAYER_SIGNED_OFFLINE")
		CASE EVENT_NETWORK_SIGN_IN_STATE_CHANGED			RETURN("SIGN_IN_STATE_CHANGED")
		CASE EVENT_NETWORK_NETWORK_BAIL						RETURN("NETWORK_BAIL")
		CASE EVENT_NETWORK_HOST_MIGRATION					RETURN("NETWORK_HOST_MIGRATION")
		CASE EVENT_NETWORK_FIND_SESSION						RETURN("FIND_SESSION")
		CASE EVENT_NETWORK_JOIN_SESSION						RETURN("JOIN_SESSION")
		CASE EVENT_NETWORK_HOST_SESSION						RETURN("HOST_SESSION")
		CASE EVENT_NETWORK_PLAYER_ARREST					RETURN("PLAYER_ARREST")
		CASE EVENT_NETWORK_PRIMARY_CLAN_CHANGED				RETURN("PRIMARY_CLAN_CHANGED")
		CASE EVENT_NETWORK_PED_LEFT_BEHIND					RETURN("PED_LEFT_BEHIND")
		CASE EVENT_NETWORK_CLAN_KICKED						RETURN("EVENT_NETWORK_CLAN_KICKED")
	ENDSWITCH
	RETURN("GET_EVENT_STRING = unknown event")
ENDFUNC


PROC PRINT_RECIEVED_EVENTS()
	
	EVENT_NAMES AllEvents[24]
	INT i
	
	AllEvents[0]  = EVENT_NETWORK_PLAYER_JOIN_SESSION
	AllEvents[1]  = EVENT_NETWORK_PLAYER_LEFT_SESSION
	AllEvents[2]  = EVENT_NETWORK_PLAYER_JOIN_SCRIPT
	AllEvents[3]  = EVENT_NETWORK_PLAYER_LEFT_SCRIPT
	AllEvents[4]  = EVENT_NETWORK_SESSION_START
	AllEvents[5]  = EVENT_NETWORK_START_MATCH
	AllEvents[6]  = EVENT_NETWORK_END_MATCH
	AllEvents[7]  = EVENT_NETWORK_SESSION_END
	AllEvents[8]  = EVENT_NETWORK_PLAYER_SPAWN
	AllEvents[9]  = EVENT_NETWORK_PLAYER_COLLECTED_PICKUP
	AllEvents[10] = EVENT_NETWORK_PLAYER_COLLECTED_AMBIENT_PICKUP
	AllEvents[11] = EVENT_NETWORK_INVITE_ARRIVED
	AllEvents[12] = EVENT_NETWORK_INVITE_ACCEPTED
	AllEvents[13] = EVENT_NETWORK_INVITE_CONFIRMED
	AllEvents[14] = EVENT_NETWORK_SUMMON
	AllEvents[15] = EVENT_NETWORK_PLAYER_SIGNED_OFFLINE
	AllEvents[16] = EVENT_NETWORK_SIGN_IN_STATE_CHANGED
	AllEvents[17] = EVENT_NETWORK_NETWORK_BAIL
	AllEvents[18] = EVENT_NETWORK_HOST_MIGRATION
	AllEvents[19] = EVENT_NETWORK_FIND_SESSION
	AllEvents[20] = EVENT_NETWORK_JOIN_SESSION
	AllEvents[21] = EVENT_NETWORK_HOST_SESSION
	AllEvents[22] = EVENT_NETWORK_SCRIPT_EVENT
	AllEvents[23] = EVENT_NETWORK_PLAYER_ARREST

	REPEAT COUNT_OF(AllEvents) i
		IF RECEIVED_EVENT(AllEvents[i])
			NET_PRINT_TIME() NET_PRINT_THREAD_ID() NET_PRINT(GET_THIS_SCRIPT_NAME())
			NET_PRINT(" received event ") 
			NET_PRINT(GET_EVENT_STRING(AllEvents[i]))
			NET_NL()
		ENDIF
	ENDREPEAT
	
ENDPROC

PROC CREATE_EVENTS_WIDGET()
	START_WIDGET_GROUP("Events")
		ADD_WIDGET_BOOL("bPrintEventQueue", bPrintEventQueue)
		ADD_WIDGET_BOOL("bSendTestScriptEvent", bSendTestScriptEvent)
		ADD_WIDGET_INT_SLIDER("iTestScriptEventType", iTestScriptEventType, -1, 99, 1)
		ADD_WIDGET_INT_SLIDER("iTestScriptEventData", iTestScriptEventData, -1, 99, 1)
	STOP_WIDGET_GROUP()
ENDPROC

PROC PROCESS_EVENTS_WIDGET()
	
	EVENT_NAMES ThisScriptEvent
	INT iCount
	
	IF (bSendTestScriptEvent)
		
		SWITCH INT_TO_ENUM(SCRIPTED_EVENT_TYPES, iTestScriptEventType)
			CASE SCRIPT_EVENT_TICKER_MESSAGE
				SCRIPT_EVENT_DATA_TICKER_MESSAGE TickerData
				TickerData.TickerEvent = INT_TO_ENUM(TICKER_EVENTS, iTestScriptEventData)
				BROADCAST_TICKER_EVENT(TickerData, ALL_PLAYERS())
			BREAK
			CASE SCRIPT_EVENT_GENERAL
				BROADCAST_GENERAL_EVENT(INT_TO_ENUM( GENERAL_EVENT_TYPE, iTestScriptEventData),ALL_PLAYERS()) 
			BREAK
			CASE SCRIPT_EVENT_JOINABLE_SCRIPT
////				JOINABLE_MP_MISSION_DATA JoinableMissionData
////				JoinableMissionData.Mission = INT_TO_ENUM(MP_MISSION, iTestScriptEventData)
//				BROADCAST_JOINABLE_MP_MISSION_EVENT(JoinableMissionData)										
			BREAK
		ENDSWITCH
		
		bSendTestScriptEvent = FALSE
	ENDIF
	
	IF (bPrintEventQueue)
		IF (GET_NUMBER_OF_EVENTS(SCRIPT_EVENT_QUEUE_NETWORK) > 0)
			NET_PRINT("============================| CNC Event Queue |==============================") NET_NL()
			NET_PRINT(" Script: ") NET_PRINT_SCRIPT() NET_NL()
			REPEAT GET_NUMBER_OF_EVENTS(SCRIPT_EVENT_QUEUE_NETWORK) iCount
				ThisScriptEvent = GET_EVENT_AT_INDEX(SCRIPT_EVENT_QUEUE_NETWORK, iCount)		
				NET_PRINT("   ")
				NET_PRINT_INT(iCount)
				NET_PRINT(". ")
				NET_PRINT(GET_EVENT_STRING(ThisScriptEvent))
				NET_NL()					
			ENDREPEAT
			NET_PRINT("=============================================================================") NET_NL()		
		ENDIF
	ENDIF	

ENDPROC

#IF FEATURE_COPS_N_CROOKS
STRUCT SCRIPT_EVENT_AWARD_TOKENS_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iTokens
ENDSTRUCT

PROC BROADCAST_AWARD_ALL_PLAYERS_TOKENS(INT iTokens)
	
	IF INT_TO_ENUM(MP_GAMEMODE, NETWORK_GET_GAME_MODE()) = GAMEMODE_FM
		g_iFailedToAwardTokensReason = DBG_TOKEN_AWARD_FAIL_REASON_FM
		EXIT
	ELIF INT_TO_ENUM(MP_GAMEMODE, NETWORK_GET_GAME_MODE()) = GAMEMODE_FAKE_MP
		g_iFailedToAwardTokensReason = DBG_TOKEN_AWARD_FAIL_REASON_FAKE_MP
		EXIT
	ENDIF
	
	SCRIPT_EVENT_AWARD_TOKENS_DATA Event
	Event.Details.Type = SCRIPT_EVENT_AWARD_TOKENS
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iTokens = iTokens
	
	g_iPlayersBS 		= ALL_PLAYERS(TRUE, FALSE)
	g_iTokensAwarded 	= iTokens
	g_iTimeAwarded 		= GET_GAME_TIMER()
	
	IF NOT (g_iPlayersBS = 0)
		PRINTLN("     ----->    BROADCAST_AWARD_ALL_PLAYERS_TOKENS - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT(), " current mode: ", NETWORK_GET_GAME_MODE())
		SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), g_iPlayersBS)	
	ELSE
		NET_PRINT("BROADCAST_AWARD_ALL_PLAYERS_TOKENS - playerflags = 0 so not broadcasting") NET_NL()		
	ENDIF
ENDPROC

STRUCT SCRIPT_EVENT_AWARD_CNCXP_DATA
	STRUCT_EVENT_COMMON_DETAILS Details
	INT iXP
ENDSTRUCT

PROC BROADCAST_AWARD_ALL_PLAYERS_CNCXP(INT iXP)
	
	SCRIPT_EVENT_AWARD_CNCXP_DATA Event
	Event.Details.Type = SCRIPT_EVENT_AWARD_ALL_PLAYERS_CNCXP
	Event.Details.FromPlayerIndex = PLAYER_ID()
	Event.iXP = iXP

	PRINTLN("     ----->    BROADCAST_AWARD_ALL_PLAYERS_CNCXP - iXP = ",iXP," SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT(), " current mode: ", NETWORK_GET_GAME_MODE())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE, FALSE))	
ENDPROC
#ENDIF

PROC BROADCAST_TEST_DLC_INTRO()
	
	IF INT_TO_ENUM(MP_GAMEMODE, NETWORK_GET_GAME_MODE()) != GAMEMODE_FM
		PRINTLN("BROADCAST_TEST_DLC_INTRO, not in freemode aborting")
		EXIT
	ENDIF
	
	STRUCT_EVENT_COMMON_DETAILS Event
	#IF FEATURE_HEIST_ISLAND
	Event.Type = SCRIPT_EVENT_TEST_DLC_INTRO
	#ENDIF
	Event.FromPlayerIndex = PLAYER_ID()
	
	PRINTLN("     ----->   BROADCAST_TEST_DLC_INTRO - SENT BY ", GET_PLAYER_NAME(PLAYER_ID())," at ",GET_CLOUD_TIME_AS_INT(), " current mode: ", NETWORK_GET_GAME_MODE())
	SEND_TU_SCRIPT_EVENT(SCRIPT_EVENT_QUEUE_NETWORK, Event, SIZE_OF(Event), ALL_PLAYERS(TRUE, FALSE))	

ENDPROC
#ENDIF

