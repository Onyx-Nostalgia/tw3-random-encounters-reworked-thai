
@addField(CR4Player) 
saved var random_encounters_reworked: CRandomEncounters;

@addMethod(CR4Player)
public function getRandomEncountersReworked(): CRandomEncounters {
  if (!this.random_encounters_reworked) {
    this.random_encounters_reworked = new CRandomEncounters in this;
  }

  return this.random_encounters_reworked;
}

@wrapMethod(CR4Player)
function OnSpawned(spawnData: SEntitySpawnData) {
  var rer: CRandomEncounters;

  wrappedMethod(spawnData);

  rer = this.getRandomEncountersReworked();
  rer.start();
}
struct RER_Constants {
  var version: float;
  
  default version = 3.04;
  
}


struct RER_ConstantInfluences {
  var kills_them: float;
  
  default kills_them = -1.5;
  
  var friend_with: float;
  
  default friend_with = 2.5;
  
  var no_influence: float;
  
  default no_influence = 0;
  
  var low_indirect_influence: float;
  
  default low_indirect_influence = 1;
  
  var high_indirect_influence: float;
  
  default high_indirect_influence = 2;
  
  var low_bad_influence: float;
  
  default low_bad_influence = -0.5;
  
  var high_bad_influence: float;
  
  default high_bad_influence = -1;
  
  var self_influence: float;
  
  default self_influence = 3;
  
}


struct RER_ConstantCreatureTypes {
  var small_creature_begin: CreatureType;
  
  default small_creature_begin = CreatureHUMAN;
  
  var small_creature_begin_no_humans: CreatureType;
  
  default small_creature_begin_no_humans = CreatureENDREGA;
  
  var small_creature_max: CreatureType;
  
  default small_creature_max = CreatureARACHAS;
  
  var large_creature_begin: CreatureType;
  
  default large_creature_begin = CreatureARACHAS;
  
  var large_creature_max: CreatureType;
  
  default large_creature_max = CreatureMAX;
  
}

latent function RER_tryRefillRandomContainer(master: CRandomEncounters) {
  var inGameConfigWrapper: CInGameConfigWrapper;
  var containers: array<CGameplayEntity>;
  var number_of_containers: int;
  var only_empty_containers: bool;
  var container: W3Container;
  var has_added: bool;
  var radius: float;
  var i: int;
  var menu_chance_multiplier: float;
  NLOG("container refill called");
  inGameConfigWrapper = theGame.GetInGameConfigWrapper();
  radius = StringToFloat(inGameConfigWrapper.GetVarValue('RERcontainerRefill', 'RERcontainerRefillRadius'));
  number_of_containers = StringToInt(inGameConfigWrapper.GetVarValue('RERcontainerRefill', 'RERcontainerRefillNumberOfContainers'));
  only_empty_containers = inGameConfigWrapper.GetVarValue('RERcontainerRefill', 'RERcontainerRefillOnlyEmptyContainers');
  menu_chance_multiplier = StringToFloat(inGameConfigWrapper.GetVarValue('RERcontainerRefill', 'RERcontainerRefillChanceMultiplier'));
  FindGameplayEntitiesInRange(containers, thePlayer, radius, 50+number_of_containers*10, , , , 'W3Container');
  for (i = 0; i<containers.Size(); i += 1) {
    if (number_of_containers<=0) {
      break;
    }
    
    
    container = (W3Container)(containers[i]);
    
    if (container) {
      if (only_empty_containers && !container.IsEmpty()) {
        continue;
      }
      
      master.loot_manager.rollAndGiveItemsTo(container.GetInventory(), menu_chance_multiplier);
      number_of_containers -= 1;
    }
    
  }
  
}

enum RER_Biome {
  BiomeForest = 0,
  BiomeSwamp = 1,
  BiomeWater = 2,
}


enum RER_RegionConstraint {
  RER_RegionConstraint_NONE = 0,
  RER_RegionConstraint_ONLY_WHITEORCHARD = 1,
  RER_RegionConstraint_ONLY_VELEN = 2,
  RER_RegionConstraint_ONLY_SKELLIGE = 3,
  RER_RegionConstraint_ONLY_TOUSSAINT = 4,
  RER_RegionConstraint_NO_WHITEORCHARD = 5,
  RER_RegionConstraint_NO_VELEN = 6,
  RER_RegionConstraint_NO_SKELLIGE = 7,
  RER_RegionConstraint_NO_TOUSSAINT = 8,
}


class RER_CreaturePreferences {
  public function reset(): RER_CreaturePreferences {
    var creature_type: CreatureType;
    this.only_biomes.Clear();
    this.disliked_biomes.Clear();
    this.liked_biomes.Clear();
    return this;
  }
  
  public var creature_type: CreatureType;
  
  public function setCreatureType(type: CreatureType): RER_CreaturePreferences {
    var only_biomes: array<RER_Biome>;
    this.creature_type = type;
    return this;
  }
  
  public var only_biomes: array<RER_Biome>;
  
  public function addOnlyBiome(biome: RER_Biome): RER_CreaturePreferences {
    var disliked_biomes: array<RER_Biome>;
    this.only_biomes.PushBack(biome);
    return this;
  }
  
  public var disliked_biomes: array<RER_Biome>;
  
  public function addDislikedBiome(biome: RER_Biome): RER_CreaturePreferences {
    var liked_biomes: array<RER_Biome>;
    this.disliked_biomes.PushBack(biome);
    return this;
  }
  
  public var liked_biomes: array<RER_Biome>;
  
  public function addLikedBiome(biome: RER_Biome): RER_CreaturePreferences {
    var chance_day: int;
    var chance_night: int;
    this.liked_biomes.PushBack(biome);
    return this;
  }
  
  public var chance_day: int;
  
  public var chance_night: int;
  
  public function setChances(day, night: int): RER_CreaturePreferences {
    var is_night: bool;
    this.chance_day = day;
    this.chance_night = night;
    return this;
  }
  
  public var is_night: bool;
  
  public function setIsNight(value: bool): RER_CreaturePreferences {
    var city_spawn_allowed: bool;
    this.is_night = value;
    return this;
  }
  
  public var city_spawn_allowed: bool;
  
  public function setCitySpawnAllowed(value: bool): RER_CreaturePreferences {
    var region_constraint: RER_RegionConstraint;
    this.city_spawn_allowed = value;
    return this;
  }
  
  public var region_constraint: RER_RegionConstraint;
  
  default region_constraint = RER_RegionConstraint_NONE;
  
  public function setRegionConstraint(constraint: RER_RegionConstraint): RER_CreaturePreferences {
    var external_factors_coefficient: float;
    this.region_constraint = constraint;
    return this;
  }
  
  public var external_factors_coefficient: float;
  
  public function setExternalFactorsCoefficient(value: float): RER_CreaturePreferences {
    var is_near_water: bool;
    this.external_factors_coefficient = value;
    return this;
  }
  
  public var is_near_water: bool;
  
  public function setIsNearWater(value: bool): RER_CreaturePreferences {
    var is_in_forest: bool;
    this.is_near_water = value;
    return this;
  }
  
  public var is_in_forest: bool;
  
  public function setIsInForest(value: bool): RER_CreaturePreferences {
    var is_in_swamp: bool;
    this.is_in_forest = value;
    return this;
  }
  
  public var is_in_swamp: bool;
  
  public function setIsInSwamp(value: bool): RER_CreaturePreferences {
    var current_region: string;
    this.is_in_swamp = value;
    return this;
  }
  
  public var current_region: string;
  
  public function setCurrentRegion(region: string): RER_CreaturePreferences {
    var is_in_city: bool;
    this.current_region = region;
    return this;
  }
  
  public var is_in_city: bool;
  
  public function setIsInCity(city: bool): RER_CreaturePreferences {
    this.is_in_city = city;
    return this;
  }
  
  public function getChances(): int {
    var i: int;
    var can_spawn: bool;
    var spawn_chances: int;
    var is_in_disliked_biome: bool;
    var is_in_liked_biome: bool;
    if (this.is_in_city && !this.city_spawn_allowed) {
      return 0;
    }
    
    can_spawn = true;
    if (!RER_isRegionConstraintValid(this.region_constraint, this.current_region)) {
      can_spawn = false;
    }
    
    if (!can_spawn) {
      return 0;
    }
    
    can_spawn = false;
    for (i = 0; i<this.only_biomes.Size(); i += 1) {
      if (this.only_biomes[i]==BiomeSwamp && this.is_in_swamp) {
        can_spawn = true;
      }
      
      
      if (this.only_biomes[i]==BiomeForest && this.is_in_forest) {
        can_spawn = true;
      }
      
      
      if (this.only_biomes[i]==BiomeWater && this.is_near_water) {
        can_spawn = true;
      }
      
    }
    
    if (this.only_biomes.Size()>0 && !can_spawn) {
      NLOG("creature removed from only biome, for "+this.creature_type);
      return 0;
    }
    
    if (this.is_night) {
      spawn_chances = this.chance_night;
    }
    else  {
      spawn_chances = this.chance_day;
      
    }
    
    is_in_disliked_biome = false;
    for (i = 0; i<this.disliked_biomes.Size(); i += 1) {
      if (this.disliked_biomes[i]==BiomeSwamp && this.is_in_swamp) {
        is_in_disliked_biome = true;
      }
      
      
      if (this.disliked_biomes[i]==BiomeForest && this.is_in_forest) {
        is_in_disliked_biome = true;
      }
      
      
      if (this.disliked_biomes[i]==BiomeWater && this.is_near_water) {
        is_in_disliked_biome = true;
      }
      
    }
    
    if (is_in_disliked_biome) {
      spawn_chances = this.applyCoefficientToCreatureDivide(spawn_chances);
    }
    
    is_in_liked_biome = false;
    for (i = 0; i<this.liked_biomes.Size(); i += 1) {
      if (this.liked_biomes[i]==BiomeSwamp && this.is_in_swamp) {
        is_in_liked_biome = true;
      }
      
      
      if (this.liked_biomes[i]==BiomeForest && this.is_in_forest) {
        is_in_liked_biome = true;
      }
      
      
      if (this.liked_biomes[i]==BiomeWater && this.is_near_water) {
        is_in_liked_biome = true;
      }
      
    }
    
    if (is_in_disliked_biome) {
      spawn_chances = this.applyCoefficientToCreature(spawn_chances);
    }
    
    return spawn_chances;
  }
  
  public function fillSpawnRoller(spawn_roller: SpawnRoller): RER_CreaturePreferences {
    spawn_roller.setCreatureCounter(this.creature_type, this.getChances());
    return this.reset();
  }
  
  public function fillSpawnRollerThirdParty(spawn_roller: SpawnRoller): RER_CreaturePreferences {
    spawn_roller.setThirdPartyCreatureCounter(this.creature_type, this.getChances());
    return this.reset();
  }
  
  private function applyCoefficientToCreature(chances: int): int {
    return (int)((chances*this.external_factors_coefficient));
  }
  
  private function applyCoefficientToCreatureDivide(chances: int): int {
    return (int)((chances/this.external_factors_coefficient));
  }
  
}


function RER_isRegionConstraintValid(constraint: RER_RegionConstraint, region: string): bool {
  return constraint==RER_RegionConstraint_NONE || constraint==RER_RegionConstraint_NO_VELEN && region!="no_mans_land" && region!="novigrad" || constraint==RER_RegionConstraint_NO_SKELLIGE && region!="skellige" && region!="kaer_morhen" || constraint==RER_RegionConstraint_NO_TOUSSAINT && region!="bob" || constraint==RER_RegionConstraint_NO_WHITEORCHARD && region!="prolog_village" || constraint==RER_RegionConstraint_ONLY_TOUSSAINT && region=="bob" || constraint==RER_RegionConstraint_ONLY_WHITEORCHARD && region=="prolog_village" || constraint==RER_RegionConstraint_ONLY_SKELLIGE && (region=="skellige" || region=="kaer_morhen") || constraint==RER_RegionConstraint_ONLY_VELEN && (region=="no_mans_land" || region=="novigrad");
}

enum EHumanType {
  HT_BANDIT = 0,
  HT_NOVBANDIT = 1,
  HT_SKELBANDIT = 2,
  HT_SKELBANDIT2 = 3,
  HT_CANNIBAL = 4,
  HT_RENEGADE = 5,
  HT_PIRATE = 6,
  HT_SKELPIRATE = 7,
  HT_NILFGAARDIAN = 8,
  HT_WITCHHUNTER = 9,
  HT_MAX = 10,
  HT_NONE = 11,
}


enum CreatureType {
  CreatureHUMAN = 0,
  CreatureENDREGA = 1,
  CreatureGHOUL = 2,
  CreatureALGHOUL = 3,
  CreatureNEKKER = 4,
  CreatureDROWNER = 5,
  CreatureROTFIEND = 6,
  CreatureWOLF = 7,
  CreatureWRAITH = 8,
  CreatureHARPY = 9,
  CreatureSPIDER = 10,
  CreatureCENTIPEDE = 11,
  CreatureDROWNERDLC = 12,
  CreatureBOAR = 13,
  CreatureBEAR = 14,
  CreaturePANTHER = 15,
  CreatureSKELETON = 16,
  CreatureECHINOPS = 17,
  CreatureKIKIMORE = 18,
  CreatureBARGHEST = 19,
  CreatureSKELWOLF = 20,
  CreatureSKELBEAR = 21,
  CreatureWILDHUNT = 22,
  CreatureBERSERKER = 23,
  CreatureSIREN = 24,
  CreatureHAG = 25,
  CreatureARACHAS = 26,
  CreatureDRACOLIZARD = 27,
  CreatureGARGOYLE = 28,
  CreatureLESHEN = 29,
  CreatureWEREWOLF = 30,
  CreatureFIEND = 31,
  CreatureEKIMMARA = 32,
  CreatureKATAKAN = 33,
  CreatureGOLEM = 34,
  CreatureELEMENTAL = 35,
  CreatureNIGHTWRAITH = 36,
  CreatureNOONWRAITH = 37,
  CreatureCHORT = 38,
  CreatureCYCLOP = 39,
  CreatureTROLL = 40,
  CreatureFOGLET = 41,
  CreatureBRUXA = 42,
  CreatureFLEDER = 43,
  CreatureGARKAIN = 44,
  CreatureDETLAFF = 45,
  CreatureGIANT = 46,
  CreatureSHARLEY = 47,
  CreatureWIGHT = 48,
  CreatureGRYPHON = 49,
  CreatureCOCKATRICE = 50,
  CreatureBASILISK = 51,
  CreatureWYVERN = 52,
  CreatureFORKTAIL = 53,
  CreatureSKELTROLL = 54,
  CreatureMAX = 55,
  CreatureNONE = 56,
}


enum EncounterType {
  EncounterType_DEFAULT = 0,
  EncounterType_HUNT = 1,
  EncounterType_CONTRACT = 2,
  EncounterType_HUNTINGGROUND = 3,
  EncounterType_MAX = 4,
}


enum OutOfCombatRequest {
  OutOfCombatRequest_TROPHY_CUTSCENE = 0,
  OutOfCombatRequest_TROPHY_NONE = 1,
}


enum TrophyVariant {
  TrophyVariant_PRICE_LOW = 0,
  TrophyVariant_PRICE_MEDIUM = 1,
  TrophyVariant_PRICE_HIGH = 2,
}


enum RER_Difficulty {
  RER_Difficulty_EASY = 0,
  RER_Difficulty_MEDIUM = 1,
  RER_Difficulty_HARD = 2,
  RER_Difficulty_RANDOM = 3,
}


enum StaticEncountersVariant {
  StaticEncountersVariant_LUCOLIVIER = 0,
  StaticEncountersVariant_AELTOTH = 1,
}

exec function rerslowboot(optional enabled: bool) {
  if (enabled) {
    RER_removeIgnoreSlowBootFact();
  }
  else  {
    RER_createIgnoreSlowBootFact();
    
  }
  
}


exec function rersetcontractreputation(value: int) {
  NDEBUG("last value: "+RER_getContractReputationFactValue());
  RER_setContractReputationFactValue(value);
}


exec function rerresetbountylevel() {
  var rer_entity: CRandomEncounters;
  if (!getRandomEncounters(rer_entity)) {
    NDEBUG("No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  rer_entity.bounty_manager.resetBountyLevel();
}


exec function rergetbountyreward(level: int) {
  var rer_entity: CRandomEncounters;
  if (!getRandomEncounters(rer_entity)) {
    NDEBUG("No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  RER_giveItemForBountyLevelAndCurrentRegion(rer_entity, thePlayer.GetInventory(), level);
}


exec function rerdebug(value: bool) {
  RER_toggleDebug(value);
}


exec function rerloot(optional category: RER_LootCategory) {
  var rer_entity: CRandomEncounters;
  if (!getRandomEncounters(rer_entity)) {
    NDEBUG("No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  rer_entity.loot_manager.rollAndGiveItemsTo(thePlayer.GetInventory(), 1.0, , category);
}


exec function reruninstall() {
  var entities: array<CEntity>;
  var i: int;
  theGame.GetEntitiesByTag('RandomEncountersReworked_Entity', entities);
  for (i = 0; i<entities.Size(); i += 1) {
    ((CNewNPC)(entities[i])).Destroy();
  }
  
  theGame.GetEntitiesByTag('RER_bounty_master', entities);
  for (i = 0; i<entities.Size(); i += 1) {
    ((CNewNPC)(entities[i])).Destroy();
  }
  
  RER_removeContractReputationFact();
  NDEBUG("RER Uninstall finished.");
}


exec function rerclearcontractstorage() {
  var rer_entity: CRandomEncounters;
  if (!getRandomEncounters(rer_entity)) {
    NDEBUG("No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  rer_entity.storages.contract.completed_contracts.Clear();
}


exec function rergotobountymaster() {
  var rer_entity: CRandomEncounters;
  if (!getRandomEncounters(rer_entity)) {
    NDEBUG("No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  thePlayer.Teleport(rer_entity.bounty_manager.bounty_master_manager.bounty_master_entity.GetWorldPosition());
}


function RER_getRandomItemFromDefinition(definition: name): name {
  var main: SCustomNode;
  var i: int;
  main = theGame.GetDefinitionsManager().GetCustomDefinition(definition);
  for (i = 0; i<main.subNodes.Size(); i += 1) {
    NLOG("RER_getRandomItemFromDefinition, main.subNodes[i] = "+main.subNodes[i].nodeName);
  }
  
  return '';
}


exec function rerhorde(type: CreatureType, optional count: int) {
  var request: RER_HordeRequest;
  var rer_entity: CRandomEncounters;
  if (count<=0) {
    count = 10;
  }
  
  request = new RER_HordeRequest in thePlayer;
  request.init();
  request.setCreatureCounter(type, count);
  if (!getRandomEncounters(rer_entity)) {
    NDEBUG("No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  rer_entity.horde_manager.sendRequest(request);
}


exec function rerclearecosystems() {
  var rer_entity: CRandomEncounters;
  if (!getRandomEncounters(rer_entity)) {
    NDEBUG("No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  rer_entity.ecosystem_manager.resetAllEcosystems();
}


exec function rerecosystemupdate(power_change: float) {
  var rer_entity: CRandomEncounters;
  if (!getRandomEncounters(rer_entity)) {
    NDEBUG("No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  rer_entity.ecosystem_manager.updatePowerForCreatureInCurrentEcosystemAreas(CreatureGHOUL, power_change, thePlayer.GetWorldPosition());
}


exec function rergetpincoord() {
  var id: int;
  var index: int;
  var x: float;
  var y: float;
  var type: int;
  var area: int;
  theGame.GetCommonMapManager().GetIdOfFirstUser1MapPin(id);
  theGame.GetCommonMapManager().GetUserMapPinByIndex(theGame.GetCommonMapManager().GetUserMapPinIndexById(id), id, area, x, y, type);
  NDEBUG("x: "+CeilF(x)+" y: "+CeilF(y));
  NLOG("pincoords x: "+CeilF(x)+" y: "+CeilF(y));
}


exec function rertptopin() {
  var id: int;
  var index: int;
  var x: float;
  var y: float;
  var type: int;
  var area: int;
  theGame.GetCommonMapManager().GetIdOfFirstUser1MapPin(id);
  theGame.GetCommonMapManager().GetUserMapPinByIndex(theGame.GetCommonMapManager().GetUserMapPinIndexById(id), id, area, x, y, type);
  thePlayer.DebugTeleportToPin(x, y);
}


exec function rerabandonbounty() {
  var rer_entity: CRandomEncounters;
  if (!getRandomEncounters(rer_entity)) {
    NDEBUG("No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  rer_entity.bounty_manager.abandonBounty();
  NDEBUG("The bounty was removed.");
}


exec function rergpc() {
  var entities: array<CGameplayEntity>;
  var rotation: EulerAngles;
  var message: string;
  var i: int;
  FindGameplayEntitiesInRange(entities, thePlayer, 25, 10, , FLAG_Attitude_Hostile+FLAG_ExcludePlayer+FLAG_OnlyAliveActors, thePlayer, 'CNewNPC');
  rotation = thePlayer.GetWorldRotation();
  message += "position: "+VecToString(thePlayer.GetWorldPosition())+"<br/>";
  message += "rotation: <br/>";
  message += " - pitch = "+rotation.Pitch+"<br/>";
  message += " - yaw = "+rotation.Yaw+"<br/>";
  message += " - roll = "+rotation.Roll+"<br/>";
  if (entities.Size()>0) {
    message += "nearby entities:<br/>";
  }
  
  for (i = 0; i<entities.Size(); i += 1) {
    message += " - "+StrAfterFirst(entities[i].ToString(), "::")+"<br/>";
  }
  
  NDEBUG(message);
}


exec function rerkillall() {
  var entities: array<CEntity>;
  var i: int;
  theGame.GetEntitiesByTag('RandomEncountersReworked_Entity', entities);
  for (i = 0; i<entities.Size(); i += 1) {
    ((CNewNPC)(entities[i])).Destroy();
  }
  
}


exec function rerkillbountymaster() {
  var entities: array<CEntity>;
  var i: int;
  theGame.GetEntitiesByTag('RER_bounty_master', entities);
  for (i = 0; i<entities.Size(); i += 1) {
    ((CNewNPC)(entities[i])).Destroy();
  }
  
}


exec function rerbounty(optional seed: int) {
  var rer_entity: CRandomEncounters;
  var exec_runner: RER_ExecRunner;
  if (!getRandomEncounters(rer_entity)) {
    NDEBUG("No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  exec_runner = new RER_ExecRunner in rer_entity;
  exec_runner.init(rer_entity, CreatureNONE);
  exec_runner.seed = seed;
  exec_runner.GotoState('RunChallengeMode');
}


exec function rertestbook() {
  var popup_data: BookPopupFeedback;
  var id: SItemUniqueId;
  popup_data = new BookPopupFeedback in thePlayer;
  popup_data.SetMessageTitle("Surrounding ecosystem");
  popup_data.SetMessageText("The area is 65% filled with bears, 10% wolves, 2% leshens and other creatures.");
  popup_data.curInventory = thePlayer.GetInventory();
  popup_data.PauseGame = true;
  popup_data.bookItemId = id;
  theGame.RequestMenu('PopupMenu', popup_data);
}


exec function rerbestiarycanspawn(creature: CreatureType) {
  var rer_entity: CRandomEncounters;
  var exec_runner: RER_ExecRunner;
  if (!getRandomEncounters(rer_entity)) {
    LogAssert(false, "No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  exec_runner = new RER_ExecRunner in rer_entity;
  exec_runner.init(rer_entity, creature);
  exec_runner.GotoState('RunBestiaryCanSpawn');
}


exec function rera(optional creature: CreatureType) {
  _rer_start_ambush(creature);
}


exec function rer_start_ambush(optional creature: CreatureType) {
  _rer_start_ambush(creature);
}


function _rer_start_ambush(optional creature: CreatureType) {
  var rer_entity: CRandomEncounters;
  var exec_runner: RER_ExecRunner;
  if (!getRandomEncounters(rer_entity)) {
    LogAssert(false, "No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  exec_runner = new RER_ExecRunner in rer_entity;
  exec_runner.init(rer_entity, creature);
  exec_runner.GotoState('RunCreatureAmbush');
}


exec function rerh(optional creature: CreatureType) {
  _rer_start_hunt(creature);
}


exec function rer_start_hunt(optional creature: CreatureType) {
  _rer_start_hunt(creature);
}


function _rer_start_hunt(optional creature: CreatureType) {
  var rer_entity: CRandomEncounters;
  var exec_runner: RER_ExecRunner;
  if (!getRandomEncounters(rer_entity)) {
    LogAssert(false, "No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  exec_runner = new RER_ExecRunner in rer_entity;
  exec_runner.init(rer_entity, creature);
  exec_runner.GotoState('RunCreatureHunt');
}


exec function rerhg(optional creature: CreatureType) {
  _rer_start_huntingground(creature);
}


exec function rer_start_huntingground(optional creature: CreatureType) {
  _rer_start_huntingground(creature);
}


function _rer_start_huntingground(optional creature: CreatureType) {
  var rer_entity: CRandomEncounters;
  var exec_runner: RER_ExecRunner;
  if (!getRandomEncounters(rer_entity)) {
    LogAssert(false, "No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  exec_runner = new RER_ExecRunner in rer_entity;
  exec_runner.init(rer_entity, creature);
  exec_runner.GotoState('RunCreatureHuntingGround');
}


exec function rerhu(optional human_type: EHumanType, optional count: int) {
  _rer_start_human(human_type, count);
}


exec function rer_start_human(optional human_type: EHumanType, optional count: int) {
  _rer_start_human(human_type, count);
}


function _rer_start_human(optional human_type: EHumanType, optional count: int) {
  var rer_entity: CRandomEncounters;
  var exec_runner: RER_ExecRunner;
  if (!getRandomEncounters(rer_entity)) {
    LogAssert(false, "No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  exec_runner = new RER_ExecRunner in rer_entity;
  exec_runner.init(rer_entity, CreatureNONE);
  exec_runner.human_type = human_type;
  exec_runner.count = count;
  exec_runner.GotoState('RunHumanAmbush');
}


exec function rer_test_camera(optional scene_id: int) {
  var rer_entity: CRandomEncounters;
  var exec_runner: RER_ExecRunner;
  if (!getRandomEncounters(rer_entity)) {
    LogAssert(false, "No entity found with tag <RandomEncounterTag>");
    return ;
  }
  
  exec_runner = new RER_ExecRunner in rer_entity;
  exec_runner.init(rer_entity, CreatureNONE);
  exec_runner.count = scene_id;
  exec_runner.GotoState('TestCameraScenePlayer');
}


statemachine class RER_ExecRunner extends CEntity {
  var master: CRandomEncounters;
  
  var creature: CreatureType;
  
  var human_type: EHumanType;
  
  var count: int;
  
  var seed: int;
  
  public function init(master: CRandomEncounters, creature: CreatureType) {
    this.master = master;
    this.creature = creature;
  }
  
}


state RunCreatureAmbush in RER_ExecRunner {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_ExecRunner - State RunCreatureAmbush");
    this.RunCreatureAmbush_main();
  }
  
  entry function RunCreatureAmbush_main() {
    createRandomCreatureAmbush(parent.master, parent.creature);
  }
  
}


state RunCreatureHuntingGround in RER_ExecRunner {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_ExecRunner - State RunCreatureHuntingGround");
    this.RunCreatureHuntingGround_main();
  }
  
  entry function RunCreatureHuntingGround_main() {
    if (parent.creature==CreatureNONE) {
      createRandomCreatureHuntingGround(parent.master, new RER_BestiaryEntryNull in parent.master);
    }
    else  {
      createRandomCreatureHuntingGround(parent.master, parent.master.bestiary.entries[parent.creature]);
      
    }
    
  }
  
}


state RunCreatureHunt in RER_ExecRunner {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_ExecRunner - State RunCreatureHunt");
    this.RunCreatureHunt_main();
  }
  
  entry function RunCreatureHunt_main() {
    createRandomCreatureHunt(parent.master, parent.creature);
  }
  
}


state RunHumanAmbush in RER_ExecRunner {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_ExecRunner - State RunHumanAmbush");
    this.RunHumanAmbush_main(parent.human_type, parent.count);
  }
  
  entry function RunHumanAmbush_main(human_type: EHumanType, count: int) {
    var composition: CreatureAmbushWitcherComposition;
    composition = new CreatureAmbushWitcherComposition in parent.master;
    composition.init(parent.master.settings);
    composition.setBestiaryEntry(parent.master.bestiary.human_entries[human_type]).setNumberOfCreatures(count).spawn(parent.master);
  }
  
}


state TestCameraScenePlayer in RER_ExecRunner {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_ExecRunner - State TestCameraScenePlayer");
    if (parent.count==0) {
      this.TestCameraScenePlayer_main();
    }
    else  {
      this.TestCameraScenePlayer_one();
      
    }
    
  }
  
  entry function TestCameraScenePlayer_main() {
    var scene: RER_CameraScene;
    var camera: RER_StaticCamera;
    scene.position_type = RER_CameraPositionType_ABSOLUTE;
    scene.position = theCamera.GetCameraPosition()+Vector(0.3, 0, 1);
    scene.look_at_target_type = RER_CameraTargetType_NODE;
    scene.look_at_target_node = thePlayer;
    scene.velocity_type = RER_CameraVelocityType_FORWARD;
    scene.velocity = Vector(0.001, 0.001, 0);
    scene.duration = 6;
    scene.position_blending_ratio = 0.01;
    scene.rotation_blending_ratio = 0.01;
    scene.duration = 5;
    camera = RER_getStaticCamera();
    camera.playCameraScene(scene, true);
  }
  
  entry function TestCameraScenePlayer_one() {
    var scene: RER_CameraScene;
    var camera: RER_StaticCamera;
    scene.position_type = RER_CameraPositionType_ABSOLUTE;
    scene.position = thePlayer.GetWorldPosition()+Vector(5, 0, 5);
    scene.look_at_target_type = RER_CameraTargetType_STATIC;
    scene.look_at_target_static = thePlayer.GetWorldPosition();
    scene.velocity_type = RER_CameraVelocityType_RELATIVE;
    scene.velocity = Vector(0, 0.05, 0);
    scene.position_blending_ratio = 0.01;
    scene.rotation_blending_ratio = 0.01;
    scene.duration = 10;
    camera = RER_getStaticCamera();
    camera.playCameraScene(scene);
  }
  
}


state RunBestiaryCanSpawn in RER_ExecRunner {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_ExecRunner - State RunBestiaryCanSpawn");
    this.RunBestiaryCanSpawn_main(parent.human_type, parent.count);
  }
  
  entry function RunBestiaryCanSpawn_main(human_type: EHumanType, count: int) {
    var manager: CWitcherJournalManager;
    var can_spawn_creature: bool;
    manager = theGame.GetJournalManager();
    can_spawn_creature = bestiaryCanSpawnEnemyTemplateList(parent.master.bestiary.entries[parent.creature].template_list, manager);
    NDEBUG("Can spawn creature ["+parent.creature+"] = "+can_spawn_creature);
  }
  
}


state RunChallengeMode in RER_ExecRunner {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_ExecRunner - State RunChallengeMode");
    this.RunChallengeMode_main();
  }
  
  entry function RunChallengeMode_main() {
    parent.master.bounty_manager.startBounty(parent.seed);
    NDEBUG("A bounty was created with the seed "+RER_yellowFont(parent.seed));
    parent.GotoState('Waiting');
  }
  
}


state Waiting in RER_ExecRunner {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_ExecRunner - State Waiting");
  }
  
}

function RER_getPlayerLevelFactValue(): int {
  return FactsQueryLatestValue("rer_player_level_fact_id");
}


function RER_setPlayerLevelFactValue(value: int) {
  FactsSet("rer_player_level_fact_id", Max(value, 0));
}

class RER_TrackerGlossary extends SU_GlossaryEntry {
  default entry_unique_id = 'RER_TrackerGlossary';
  
  function getDescription(): string {
    var tracker: RER_TrackerStorage;
    var message: string;
    var total_encounters_spawned: int;
    var count: int;
    var idxa193b2cd9f664a66b5494032be21c28b: int;
    var total_encounters_killed: int;
    var idxa1611d7d063b4e7c8beb2ba23297fbe8: int;
    var total_encounters_recycled: int;
    var idx128a45831163447c89eb5390cd30a099: int;
    var total_creatures_spawned: int;
    var idx21a817855f4746fba935e2a0f2a237c5: int;
    var master: CRandomEncounters;
    var i: int;
    tracker = RER_getTrackerStorage();
    if (!tracker) {
      NLOG("RER_addTrackerGlossary - no tracker storage found");
      return "ERROR: failed to retrieve RER Tracker Storage";
    }
    
    message = "";
    total_encounters_spawned = 0;
    for (idxa193b2cd9f664a66b5494032be21c28b = 0; idxa193b2cd9f664a66b5494032be21c28b < tracker.encounters_spawned.Size(); idxa193b2cd9f664a66b5494032be21c28b += 1) {
      count = tracker.encounters_spawned[idxa193b2cd9f664a66b5494032be21c28b];
      total_encounters_spawned += count;
    }
    message += "Encounters spawned: "+total_encounters_spawned;
    message += "<br/> - "+tracker.encounters_spawned[EncounterType_DEFAULT]+" Ambushes";
    message += "<br/> - "+tracker.encounters_spawned[EncounterType_HUNT]+" Monster hunts";
    message += "<br/> - "+tracker.encounters_spawned[EncounterType_HUNTINGGROUND]+" Hunting grounds";
    message += "<br/>";
    message += "<br/>";
    total_encounters_killed = 0;
    for (idxa1611d7d063b4e7c8beb2ba23297fbe8 = 0; idxa1611d7d063b4e7c8beb2ba23297fbe8 < tracker.encounters_killed.Size(); idxa1611d7d063b4e7c8beb2ba23297fbe8 += 1) {
      count = tracker.encounters_killed[idxa1611d7d063b4e7c8beb2ba23297fbe8];
      total_encounters_killed += count;
    }
    message += "Encounters killed: "+total_encounters_killed;
    message += "<br/> - "+tracker.encounters_killed[EncounterType_DEFAULT]+" Ambushes";
    message += "<br/> - "+tracker.encounters_killed[EncounterType_HUNT]+" Monster hunts";
    message += "<br/> - "+tracker.encounters_killed[EncounterType_HUNTINGGROUND]+" Hunting grounds";
    message += "<br/>";
    message += "<br/>";
    total_encounters_recycled = 0;
    for (idx128a45831163447c89eb5390cd30a099 = 0; idx128a45831163447c89eb5390cd30a099 < tracker.encounters_recycled.Size(); idx128a45831163447c89eb5390cd30a099 += 1) {
      count = tracker.encounters_recycled[idx128a45831163447c89eb5390cd30a099];
      total_encounters_recycled += count;
    }
    message += "Encounters missed: "+total_encounters_recycled;
    message += "<br/> - "+tracker.encounters_recycled[EncounterType_DEFAULT]+" Ambushes";
    message += "<br/> - "+tracker.encounters_recycled[EncounterType_HUNT]+" Monster hunts";
    message += "<br/> - "+tracker.encounters_recycled[EncounterType_HUNTINGGROUND]+" Hunting grounds";
    message += "<br/>";
    message += "<br/>";
    total_creatures_spawned = 0;
    for (idx21a817855f4746fba935e2a0f2a237c5 = 0; idx21a817855f4746fba935e2a0f2a237c5 < tracker.creatures_spawned.Size(); idx21a817855f4746fba935e2a0f2a237c5 += 1) {
      count = tracker.creatures_spawned[idx21a817855f4746fba935e2a0f2a237c5];
      total_creatures_spawned += count;
    }
    message += "Creatures spawned: "+total_creatures_spawned;
    if (!getRandomEncounters(master)) {
      return message;
    }
    
    for (i = 0; i<CreatureMAX; i += 1) {
      if (tracker.creatures_spawned[i]<=0) {
        continue;
      }
      
      
      message += "<br/> - "+tracker.creatures_spawned[i]+" "+getCreatureNameFromCreatureType(master.bestiary, i);
    }
    
    return message;
  }
  
}


function RER_addTrackerGlossary() {
  var book: RER_TrackerGlossary;
  book = new RER_TrackerGlossary in thePlayer;
  book.drop_down_label = "Random Encounters Reworked";
  book.drop_down_tag = 'RandomEncountersReworked';
  book.title = "Tracking data";
  SU_addGlossaryEntry(book);
}

latent function makeGroupComposition(encounter_type: EncounterType, random_encounters_class: CRandomEncounters) {
  if (encounter_type==EncounterType_HUNT) {
    NLOG("spawning - HUNT");
    createRandomCreatureHunt(random_encounters_class, CreatureNONE);
    if (random_encounters_class.settings.geralt_comments_enabled && !isPlayerInScene()) {
      thePlayer.PlayVoiceset(90, "MiscFreshTracks");
    }
    
  }
  else if (encounter_type==EncounterType_DEFAULT) {
    NLOG("spawning - AMBUSH");
    
    createRandomCreatureAmbush(random_encounters_class, CreatureNONE);
    
    if (random_encounters_class.settings.geralt_comments_enabled && !isPlayerInScene()) {
      thePlayer.PlayVoiceset(90, "BattleCryBadSituation");
    }
    
    
  }
  else if (encounter_type==EncounterType_HUNTINGGROUND) {
    NLOG("spawning - HUNTINGGROUND");
    
    createRandomCreatureHuntingGround(random_encounters_class, new RER_BestiaryEntryNull in random_encounters_class);
    
  }
  else  {
    NDEBUG("RER Error: an encounter was supposed to start but the encounter type is unknown = "+encounter_type);
    
  }
  
}


abstract class CompositionSpawner {
  var _bestiary_entry: RER_BestiaryEntry;
  
  var _bestiary_entry_null: bool;
  
  default _bestiary_entry_null = true;
  
  public function setBestiaryEntry(bentry: RER_BestiaryEntry): CompositionSpawner {
    var _number_of_creatures: int;
    this._bestiary_entry = bentry;
    this._bestiary_entry_null = bentry.isNull();
    return this;
  }
  
  var _number_of_creatures: int;
  
  default _number_of_creatures = 0;
  
  public function setNumberOfCreatures(count: int): CompositionSpawner {
    var spawn_position: Vector;
    var spawn_position_force: bool;
    this._number_of_creatures = count;
    return this;
  }
  
  var spawn_position: Vector;
  
  var spawn_position_force: bool;
  
  default spawn_position_force = false;
  
  public function setSpawnPosition(position: Vector): CompositionSpawner {
    var _random_position_max_radius: float;
    this.spawn_position = position;
    this.spawn_position_force = true;
    return this;
  }
  
  var _random_position_max_radius: float;
  
  default _random_position_max_radius = 200;
  
  public function setRandomPositionMaxRadius(radius: float): CompositionSpawner {
    var _random_positition_min_radius: float;
    this._random_position_max_radius = radius;
    return this;
  }
  
  var _random_positition_min_radius: float;
  
  default _random_positition_min_radius = 150;
  
  public function setRandomPositionMinRadius(radius: float): CompositionSpawner {
    var _group_positions_density: float;
    this._random_positition_min_radius = radius;
    return this;
  }
  
  var _group_positions_density: float;
  
  default _group_positions_density = 0.01;
  
  public function setGroupPositionsDensity(density: float): CompositionSpawner {
    var automatic_kill_threshold_distance: float;
    this._group_positions_density = density;
    return this;
  }
  
  var automatic_kill_threshold_distance: float;
  
  default automatic_kill_threshold_distance = 200;
  
  public function setAutomaticKillThresholdDistance(distance: float): CompositionSpawner {
    var allow_trophy: bool;
    this.automatic_kill_threshold_distance = distance;
    return this;
  }
  
  var allow_trophy: bool;
  
  default allow_trophy = true;
  
  public function setAllowTrophy(value: bool): CompositionSpawner {
    var allow_trophy_pickup_scene: bool;
    this.allow_trophy = value;
    return this;
  }
  
  var allow_trophy_pickup_scene: bool;
  
  default allow_trophy_pickup_scene = false;
  
  public function setAllowTrophyPickupScene(value: bool): CompositionSpawner {
    var encounter_type: EncounterType;
    this.allow_trophy_pickup_scene = value;
    return this;
  }
  
  var encounter_type: EncounterType;
  
  default encounter_type = EncounterType_DEFAULT;
  
  public function setEncounterType(encounter_type: EncounterType): CompositionSpawner {
    var master: CRandomEncounters;
    var bestiary_entry: RER_BestiaryEntry;
    var initial_position: Vector;
    var created_entities: array<CEntity>;
    this.encounter_type = encounter_type;
    return this;
  }
  
  var master: CRandomEncounters;
  
  var bestiary_entry: RER_BestiaryEntry;
  
  var initial_position: Vector;
  
  var created_entities: array<CEntity>;
  
  public latent function spawn(master: CRandomEncounters) {
    var i: int;
    var success: bool;
    this.master = master;
    this.bestiary_entry = this.getBestiaryEntry(master);
    if (this.bestiary_entry.isNull()) {
      return ;
    }
    
    if (!this.getInitialPosition(this.initial_position, master)) {
      NLOG("could not find proper spawning position");
      return ;
    }
    
    success = this.beforeSpawningEntities();
    if (!success) {
      return ;
    }
    
    this.created_entities = this.bestiary_entry.spawn(master, this.initial_position, this._number_of_creatures, this._group_positions_density, this.encounter_type);
    if (this.created_entities.Size()<=0) {
      return ;
    }
    
    for (i = 0; i<this.created_entities.Size(); i += 1) {
      this.forEachEntity(this.created_entities[i]);
    }
    
    success = this.afterSpawningEntities();
    if (!success) {
      return ;
    }
    
  }
  
  protected latent function beforeSpawningEntities(): bool {
    return true;
  }
  
  protected latent function forEachEntity(entity: CEntity) {
  }
  
  protected latent function afterSpawningEntities(): bool {
    return true;
  }
  
  protected latent function getBestiaryEntry(master: CRandomEncounters): RER_BestiaryEntry {
    var bestiary_entry: RER_BestiaryEntry;
    if (this._bestiary_entry_null) {
      bestiary_entry = master.bestiary.getRandomEntryFromBestiary(master, this.encounter_type);
      return bestiary_entry;
    }
    
    return this._bestiary_entry;
  }
  
  protected function getInitialPosition(out initial_position: Vector, master: CRandomEncounters): bool {
    var attempt: bool;
    if (this.spawn_position_force) {
      initial_position = this.spawn_position;
      return true;
    }
    
    attempt = getRandomPositionBehindCamera(initial_position, this._random_position_max_radius, this._random_positition_min_radius, 10);
    initial_position = SUH_moveCoordinatesAwayFromSafeAreas(initial_position, master.addon_manager.addons_data.exception_areas);
    return attempt;
  }
  
}

function RER_addKillingSpreeCustomLootToEntities(loot_manager: RER_LootManager, entities: array<CEntity>, ecosystem_strength: float) {
  var increase_per_point: float;
  var entity: CEntity;
  var idx605529fbc9c9482c82251c4217feb062: int;
  NLOG("RER_addKillingSpreeCustomLootToEntities: ecosystem strength = "+ecosystem_strength*100);
  if (ecosystem_strength<1 && ecosystem_strength!=0) {
    ecosystem_strength = 1/ecosystem_strength;
  }
  
  NLOG("RER_addKillingSpreeCustomLootToEntities: ecosystem strength = "+ecosystem_strength*100);
  increase_per_point = StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('RERkillingSpreeCustomLoot', 'RERkillingSpreeChanceIncreasePerImpactPoint'));
  for (idx605529fbc9c9482c82251c4217feb062 = 0; idx605529fbc9c9482c82251c4217feb062 < entities.Size(); idx605529fbc9c9482c82251c4217feb062 += 1) {
    entity = entities[idx605529fbc9c9482c82251c4217feb062];
    loot_manager.rollAndGiveItemsTo(((CGameplayEntity)(entity)).GetInventory(), ecosystem_strength*increase_per_point);
    
    ((CGameplayEntity)(entity)).GetInventory().UpdateLoot();
  }
}

statemachine class CRandomEncounters {
  var rExtra: CModRExtra;
  
  var settings: RE_Settings;
  
  var resources: RE_Resources;
  
  var spawn_roller: SpawnRoller;
  
  var events_manager: RER_EventsManager;
  
  var bestiary: RER_Bestiary;
  
  var static_encounter_manager: RER_StaticEncounterManager;
  
  var ecosystem_manager: RER_EcosystemManager;
  
  saved var storages: RER_StorageCollection;
  
  var bounty_manager: RER_BountyManager;
  
  var horde_manager: RER_HordeManager;
  
  var contract_manager: RER_ContractManager;
  
  var addon_manager: RER_AddonManager;
  
  var loot_manager: RER_LootManager;
  
  var boot_time: float;
  
  var ticks_before_spawn: float;
  
  var ecosystem_frequency_multiplier: float;
  
  var mod_power: float;
  
  public function start() {
    NLOG("Random Encounters Reworked - CRandomEncounters::start()");
    theInput.RegisterListener(this, 'OnRefreshSettings', 'OnRefreshSettings');
    theInput.RegisterListener(this, 'OnSpawnMonster', 'RandomEncounter');
    theInput.RegisterListener(this, 'OnRER_enabledToggle', 'OnRER_enabledToggle');
    rExtra = new CModRExtra in this;
    settings = new RE_Settings in this;
    resources = new RE_Resources in this;
    spawn_roller = new SpawnRoller in this;
    events_manager = new RER_EventsManager in this;
    bestiary = new RER_Bestiary in this;
    static_encounter_manager = new RER_StaticEncounterManager in this;
    ecosystem_manager = new RER_EcosystemManager in this;
    bounty_manager = new RER_BountyManager in this;
    horde_manager = new RER_HordeManager in this;
    contract_manager = new RER_ContractManager in this;
    addon_manager = new RER_AddonManager in this;
    loot_manager = new RER_LootManager in this;
    this.boot_time = theGame.GetEngineTimeAsSeconds();
    this.GotoState('Initialising');
  }
  
  public function hasJustBooted(): bool {
    return theGame.GetEngineTimeAsSeconds()-this.boot_time<=30;
  }
  
  public function getModPower(): float {
    return this.mod_power;
  }
  
  public function refreshModPower() {
    var game_time: GameTime;
    var power: float;
    if (RER_doesIgnoreSlowBootFactExist()) {
      NLOG("CRandomEncounters::refreshModPower(): ignore slowbot fact found");
      power = 1;
    }
    else  {
      NLOG("CRandomEncounters::refreshModPower(): calculating mod power from gametime");
      
      game_time = theGame.CalculateTimePlayed();
      
      power = ClampF(((float)((GameTimeDays(game_time)*24+GameTimeHours(game_time))))/10.0, 0, 1);
      
    }
    
    NLOG("CRandomEncounters::refreshModPower(): power = "+power);
    this.mod_power = power;
  }
  
  event OnRefreshSettings(action: SInputAction) {
    NLOG("settings refreshed");
    if (IsPressed(action)) {
      this.settings.loadXMLSettingsAndShowNotification();
      this.events_manager.start();
      this.bestiary.init();
      this.bestiary.loadSettings();
      this.GotoState('Loading');
    }
    
  }
  
  event OnSpawnMonster(action: SInputAction) {
    NLOG("on spawn event");
    if (this.ticks_before_spawn>5) {
      this.ticks_before_spawn = 5;
    }
    
  }
  
  event OnRER_enabledToggle(action: SInputAction) {
    if (IsPressed(action)) {
      NLOG("RER enabled state toggle");
      this.settings.toggleEnabledSettings();
      if (!this.settings.hide_next_notifications) {
        if (this.settings.is_enabled) {
          displayRandomEncounterEnabledNotification();
        }
        else  {
          displayRandomEncounterDisabledNotification();
          
        }
        
      }
      
    }
    
  }
  
  public function refreshEcosystemFrequencyMultiplier() {
    this.ecosystem_frequency_multiplier = this.ecosystem_manager.getEcosystemAreasFrequencyMultiplier(this.ecosystem_manager.getCurrentEcosystemAreas());
  }
  
  public function getPlaythroughSeed(): int {
    var out_of_combat_requests: array<OutOfCombatRequest>;
    if (this.storages.general.playthrough_seed==0) {
      this.storages.general.playthrough_seed = RandRange(1000000, 0);
      this.storages.general.save();
    }
    
    return this.storages.general.playthrough_seed;
  }
  
  private var out_of_combat_requests: array<OutOfCombatRequest>;
  
  public function requestOutOfCombatAction(request: OutOfCombatRequest): bool {
    var i: int;
    var already_added: bool;
    already_added = false;
    return !already_added;
  }
  
  private function shouldPlayTrophyCutScene(): bool {
    return RandRange(100)<=this.settings.trophy_pickup_scene_chance;
  }
  
  timer function lootTrophiesAndPlayCutscene(optional delta: float, optional id: Int32) {
    var scene: CStoryScene;
    var will_play_cutscene: bool;
    will_play_cutscene = lootTrophiesInRadius();
    RER_tutorialTryShowTrophy();
    if (will_play_cutscene) {
      NLOG("playing out of combat cutscene");
      scene = (CStoryScene)(LoadResource("dlc\modtemplates\randomencounterreworkeddlc\data\mh_taking_trophy_no_dialogue.w2scene", true));
      theGame.GetStorySceneSystem().PlayScene(scene, "Input");
      if (RandRange(10)<2) {
        REROL_hang_your_head_from_sadle_sync();
      }
      else if (RandRange(10)<2) {
        REROL_someone_pay_for_trophy_sync();
        
      }
      else if (RandRange(10)<2) {
        REROL_good_size_wonder_if_someone_pay_sync();
        
      }
      
    }
    
  }
  
  event OnDestroyed() {
    var ents: array<CEntity>;
    var i: int;
    NLOG("On destroyed called on RER main class");
    theGame.GetEntitiesByTag('RandomEncountersReworked_Entity', ents);
    NLOG("found "+ents.Size()+" RER entities");
  }
  
  event OnDeath(damageAction: W3DamageAction) {
    NLOG("On death called on RER main class");
  }
  
}


function getRandomEncounters(out rer_entity: CRandomEncounters): bool {
  rer_entity = thePlayer.getRandomEncountersReworked();
  if (rer_entity) {
    return true;
  }
  
  return false;
}

statemachine class RER_MonsterClue extends W3MonsterClue {
  public var voiceline_type: name;
  
  default voiceline_type = 'RER_MonsterClue';
  
  event OnInteraction(actionName: string, activator: CEntity) {
    if (activator==thePlayer && thePlayer.IsActionAllowed(EIAB_InteractionAction)) {
      super.OnInteraction(actionName, activator);
      if (this.GetCurrentStateName()!='Interacting') {
        this.GotoState('Interacting');
      }
      
    }
    
  }
  
}


state Waiting in RER_MonsterClue {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_MonsterClue - State Waiting");
  }
  
}


state Interacting in RER_MonsterClue {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_MonsterClue - State Interacting");
    this.start();
  }
  
  entry function start() {
    RER_tutorialTryShowClue();
    this.playOneliner();
    this.playAnimation();
    parent.GotoState('Waiting');
  }
  
  latent function playOneliner() {
    NLOG("voiceline_type = "+parent.voiceline_type);
    switch (parent.voiceline_type) {
      case 'RER_MonsterClueNekker':
      this.displayHudText(CreatureNEKKER);
      REROL_tracks_a_nekker(true);
      break;
      
      case 'RER_MonsterClueDrowner':
      this.displayHudText(CreatureDROWNER);
      REROL_more_drowners(true);
      break;
      
      case 'RER_MonsterClueGhoul':
      this.displayHudText(CreatureGHOUL);
      REROL_ghouls_there_is_corpses(true);
      break;
      
      case 'RER_MonsterClueAlghoul':
      this.displayHudText(CreatureALGHOUL);
      REROL_ghouls_there_is_corpses(true);
      break;
      
      case 'RER_MonsterClueFiend':
      this.displayHudText(CreatureFIEND);
      REROL_a_fiend(true);
      break;
      
      case 'RER_MonsterClueChort':
      this.displayHudText(CreatureCHORT);
      REROL_a_fiend(true);
      break;
      
      case 'RER_MonsterClueWerewolf':
      this.displayHudText(CreatureWEREWOLF);
      REROL_a_werewolf(true);
      break;
      
      case 'RER_MonsterClueLeshen':
      this.displayHudText(CreatureLESHEN);
      REROL_a_leshen_a_young_one(true);
      break;
      
      case 'RER_MonsterClueKatakan':
      this.displayHudText(CreatureKATAKAN);
      REROL_where_is_katakan(true);
      break;
      
      case 'RER_MonsterClueEkimmara':
      this.displayHudText(CreatureEKIMMARA);
      REROL_gotta_be_an_ekimmara(true);
      break;
      
      case 'RER_MonsterClueElemental':
      this.displayHudText(CreatureELEMENTAL);
      REROL_an_earth_elemental(true);
      break;
      
      case 'RER_MonsterClueGolem':
      this.displayHudText(CreatureGOLEM);
      REROL_an_earth_elemental(true);
      break;
      
      case 'RER_MonsterClueGiant':
      this.displayHudText(CreatureGIANT);
      REROL_giant_wind_up_here(true);
      break;
      
      case 'RER_MonsterClueCyclop':
      this.displayHudText(CreatureCYCLOP);
      REROL_giant_wind_up_here(true);
      break;
      
      case 'RER_MonsterClueGryphon':
      this.displayHudText(CreatureGRYPHON);
      REROL_griffin_this_close_village(true);
      break;
      
      case 'RER_MonsterClueWyvern':
      this.displayHudText(CreatureWYVERN);
      REROL_wyvern_wonderful(true);
      break;
      
      case 'RER_MonsterClueCockatrice':
      this.displayHudText(CreatureCOCKATRICE);
      REROL_a_cockatrice(true);
      break;
      
      case 'RER_MonsterClueBasilisk':
      this.displayHudText(CreatureBASILISK);
      REROL_a_cockatrice(true);
      break;
      
      case 'RER_MonsterClueForktail':
      this.displayHudText(CreatureFORKTAIL);
      REROL_a_flyer_forktail(true);
      break;
      
      case 'RER_MonsterClueWight':
      this.displayHudText(CreatureWIGHT);
      REROL_impossible_wight(true);
      break;
      
      case 'RER_MonsterClueSharley':
      this.displayHudText(CreatureSHARLEY);
      REROL_a_shaelmaar_is_close(true);
      break;
      
      case 'RER_MonsterClueHag':
      this.displayHudText(CreatureHAG);
      REROL_gotta_be_a_grave_hag(true);
      break;
      
      case 'RER_MonsterClueFoglet':
      this.displayHudText(CreatureFOGLET);
      REROL_dealing_with_foglet(true);
      break;
      
      case 'RER_MonsterClueTroll':
      this.displayHudText(CreatureTROLL);
      REROL_a_rock_troll(true);
      break;
      
      case 'RER_MonsterClueBruxa':
      this.displayHudText(CreatureBRUXA);
      REROL_bruxa_gotta_be(true);
      break;
      
      case 'RER_MonsterClueDetlaff':
      this.displayHudText(CreatureDETLAFF);
      REROL_bruxa_gotta_be(true);
      break;
      
      case 'RER_MonsterClueGarkain':
      this.displayHudText(CreatureGARKAIN);
      REROL_a_garkain(true);
      break;
      
      case 'RER_MonsterClueFleder':
      this.displayHudText(CreatureFLEDER);
      REROL_a_garkain(true);
      break;
      
      case 'RER_MonsterClueNightwraith':
      this.displayHudText(CreatureNIGHTWRAITH);
      REROL_a_nightwraith(true);
      break;
      
      case 'RER_MonsterClueGargoyle':
      this.displayHudText(CreatureGARGOYLE);
      REROL_an_earth_elemental(true);
      break;
      
      case 'RER_MonsterClueKikimore':
      this.displayHudText(CreatureKIKIMORE);
      REROL_kikimores_dammit(true);
      break;
      
      case 'RER_MonsterClueCentipede':
      this.displayHudText(CreatureCENTIPEDE);
      REROL_what_lured_centipedes(true);
      break;
      
      case 'RER_MonsterClueWolf':
      this.displayHudText(CreatureWOLF);
      REROL_where_did_wolf_prints_come_from(true);
      break;
      
      case 'RER_MonsterClueBerserker':
      this.displayHudText(CreatureBERSERKER);
      REROL_half_man_half_bear(true);
      break;
      
      case 'RER_MonsterClueBear':
      this.displayHudText(CreatureBEAR);
      REROL_animal_hair(true);
      break;
      
      case 'RER_MonsterClueBoar':
      this.displayHudText(CreatureBOAR);
      REROL_animal_hair(true);
      break;
      
      case 'RER_MonsterCluePanther':
      this.displayHudText(CreaturePANTHER);
      REROL_animal_hair(true);
      break;
      
      case 'RER_MonsterClueSpider':
      this.displayHudText(CreatureSPIDER);
      REROL_animal_hair(true);
      break;
      
      case 'RER_MonsterClueWildhunt':
      this.displayHudText(CreatureWILDHUNT);
      REROL_the_wild_hunt(true);
      break;
      
      case 'RER_MonsterClueArachas':
      this.displayHudText(CreatureARACHAS);
      REROL_an_arachas(true);
      break;
      
      case 'RER_MonsterClueHarpy':
      this.displayHudText(CreatureHARPY);
      REROL_harpy_feather(true);
      break;
      
      case 'RER_MonsterClueSiren':
      this.displayHudText(CreatureSIREN);
      REROL_siren_tracks(true);
      break;
      
      case 'RER_MonsterClueRotfiend':
      this.displayHudText(CreatureROTFIEND);
      REROL_necrophages_great(true);
      break;
      
      case 'RER_MonsterClueEndrega':
      this.displayHudText(CreatureENDREGA);
      REROL_insectoid_excretion(true);
      break;
      
      case 'RER_MonsterClueEchinops':
      this.displayHudText(CreatureECHINOPS);
      REROL_insectoid_excretion(true);
      break;
      
      case 'RER_MonsterClueDracolizard':
      this.displayHudText(CreatureDRACOLIZARD);
      REROL_so_its_a_slyzard(true);
      break;
      
      case 'RER_MonsterClueHuman':
      this.displayHudText(CreatureHUMAN);
      REROL_well_armed_bandits(true);
      break;
      
      default:
      NHUD(GetLocStringByKey("rer_tracks_examine_hud_message_unknown"));
      REROL_interesting(true);
      break;
    }
  }
  
  latent function playAnimation() {
    parent.interactionAnim = PEA_ExamineGround;
    parent.PlayInteractionAnimation();
  }
  
  function displayHudText(type: CreatureType) {
    var master: CRandomEncounters;
    if (!getRandomEncounters(master)) {
      return ;
    }
    
    NHUD(StrReplace(GetLocStringByKey("rer_tracks_examine_hud_message"), "{{species}}", upperCaseFirstLetter(getCreatureNameFromCreatureType(master.bestiary, type))));
  }
  
}

function displayRandomEncounterEnabledNotification() {
  theGame.GetGuiManager().ShowNotification(GetLocStringByKey("option_rer_enabled"));
}


function displayRandomEncounterDisabledNotification() {
  theGame.GetGuiManager().ShowNotification(GetLocStringByKey("option_rer_disabled"));
}


function NDEBUG(message: string, optional duration: float) {
  theGame.GetGuiManager().ShowNotification(message, duration);
}


function NHUD(message: string) {
  thePlayer.DisplayHudMessage(message);
}


function NLOG(message: string) {
  LogChannel('RER', message);
}


function NTUTO(title: string, body: string, optional do_not_pause: bool) {
  var tut: W3TutorialPopupData;
  tut = new W3TutorialPopupData in thePlayer;
  tut.managerRef = theGame.GetTutorialSystem();
  tut.messageTitle = title;
  tut.messageText = body;
  tut.enableGlossoryLink = false;
  tut.autosize = true;
  tut.blockInput = !do_not_pause;
  tut.pauseGame = !do_not_pause;
  tut.fullscreen = true;
  tut.canBeShownInMenus = true;
  tut.duration = -1;
  tut.posX = 0;
  tut.posY = 0;
  tut.enableAcceptButton = true;
  tut.fullscreen = true;
  if (do_not_pause) {
    tut.blockInput = false;
    tut.pauseGame = false;
    tut.enableAcceptButton = false;
    tut.duration = 10;
  }
  
  theGame.GetTutorialSystem().ShowTutorialHint(tut);
}


function RER_toggleHUD() {
  var hud: CR4ScriptedHud;
  hud = (CR4ScriptedHud)(theGame.GetHud());
  if (hud) {
    hud.ToggleHudByUser();
  }
  
}

class RER_Oneliner extends SU_Oneliner {
  function getVisible(player_position: Vector): bool {
    return theGame.IsFocusModeActive() && super.getVisible(player_position);
  }
  
}


function RER_oneliner(text: string, position: Vector): RER_Oneliner {
  var oneliner: RER_Oneliner;
  oneliner = new RER_Oneliner in thePlayer;
  oneliner.text = text;
  oneliner.position = position;
  oneliner.register();
  return oneliner;
}


class RER_OnelinerEntity extends SU_OnelinerEntity {
  function getVisible(player_position: Vector): bool {
    return theGame.IsFocusModeActive() && super.getVisible(player_position);
  }
  
}


function RER_onelinerEntity(text: string, entity: CEntity): RER_OnelinerEntity {
  var oneliner: RER_OnelinerEntity;
  oneliner = new RER_OnelinerEntity in thePlayer;
  oneliner.text = text;
  oneliner.entity = entity;
  oneliner.register();
  return oneliner;
}


latent function REROL_died_recently() {
  var scene: CStoryScene;
  scene = (CStoryScene)(LoadResourceAsync("quests\generic_quests\no_mans_land\quest_files\mh107_fiend\scenes\mh107_geralts_oneliners.w2scene", true));
  theGame.GetStorySceneSystem().PlayScene(scene, "ClueDeadBies");
  Sleep(2.7);
}


latent function REROL_no_dragon() {
  var scene: CStoryScene;
  scene = (CStoryScene)(LoadResourceAsync("quests\generic_quests\skellige\quest_files\mh208_forktail\scenes\mh208_geralt_oneliners.w2scene", true));
  theGame.GetStorySceneSystem().PlayScene(scene, "NoDragon");
  Sleep(5.270992);
}


latent function REROL_what_drew_the_ghouls() {
  var scene: CStoryScene;
  scene = (CStoryScene)(LoadResourceAsync("quests\minor_quests\no_mans_land\quest_files\mq1039_uninvited_guests\scenes\mq1039_geralt_oneliner.w2scene", true));
  theGame.GetStorySceneSystem().PlayScene(scene, "interaction");
  Sleep(2.933915);
}


latent function REROL_so_many_corpses() {
  var scene: CStoryScene;
  scene = (CStoryScene)(LoadResourceAsync("quests\prologue\quest_files\q001_beggining\scenes\q001_0_geralt_comments.w2scene", true));
  theGame.GetStorySceneSystem().PlayScene(scene, "battlefield_comment");
  Sleep(3.502878);
}


latent function REROL_wonder_clues_will_lead_me(optional do_not_wait: bool) {
  var scene: CStoryScene;
  scene = (CStoryScene)(LoadResourceAsync("quests\generic_quests\novigrad\quest_files\mh307_minion\scenes\mh307_02_investigation.w2scene", true));
  theGame.GetStorySceneSystem().PlayScene(scene, "All_clues_in");
  if (!do_not_wait) {
    Sleep(3.8);
  }
  
}


latent function REROL_shitty_way_to_die() {
  var scene: CStoryScene;
  scene = (CStoryScene)(LoadResourceAsync("quests/part_2/quest_files/q106_tower/scenes_pickup/q106_14f_ppl_in_cages.w2scene", true));
  theGame.GetStorySceneSystem().PlayScene(scene, "Input");
  Sleep(2.6);
}


latent function REROL_there_you_are(optional do_not_wait: bool) {
  var scene: CStoryScene;
  scene = (CStoryScene)(LoadResourceAsync("quests/part_1/quest_files/q103_daughter/scenes/q103_08f_gameplay_geralt.w2scene", true));
  theGame.GetStorySceneSystem().PlayScene(scene, "spot_goat_in");
  if (!do_not_wait) {
    Sleep(1.32);
  }
  
}


latent function REROL_that_was_tough() {
  thePlayer.PlayLine(321440, true);
  Sleep(1.155367);
}


latent function REROL_cant_smell_a_thing() {
  thePlayer.PlayLine(5399670, true);
  Sleep(1.155367);
}


latent function REROL_necrophages_great(optional do_not_wait: bool) {
  var scene: CStoryScene;
  scene = (CStoryScene)(LoadResourceAsync("dlc/dlc15/data/quests/quest_files/scenes/mq1058_geralt_oneliners.w2scene", true));
  theGame.GetStorySceneSystem().PlayScene(scene, "NecropphagesComment");
  if (!do_not_wait) {
    Sleep(2);
  }
  
}


latent function REROL_the_wild_hunt(optional do_not_wait: bool) {
  thePlayer.PlayLine(539883, true);
  if (!do_not_wait) {
    Sleep(1.72);
  }
  
}


latent function REROL_go_or_ill_kill_you() {
  thePlayer.PlayLine(476195, true);
  Sleep(2.684654);
}


latent function REROL_air_strange_and_the_mist(optional do_not_wait: bool) {
  thePlayer.PlayLine(1061986, true);
  if (!do_not_wait) {
    Sleep(6.6);
  }
  
}


latent function REROL_clawed_gnawed_not_necrophages() {
  thePlayer.PlayLine(470573, true);
  Sleep(7.430004);
}


latent function REROL_wild_hunt_killed_them() {
  thePlayer.PlayLine(1047779, true);
  Sleep(2.36);
}


latent function REROL_should_look_around(optional do_not_wait: bool) {
  thePlayer.PlayLine(397220, true);
  if (!do_not_wait) {
    Sleep(1.390483);
  }
  
}


class REROL_data_should_look_around extends RER_DialogData {
  default dialog_id = 397220;
  
}


latent function REROL_came_through_here(optional do_not_wait: bool) {
  thePlayer.PlayLine(382001, true);
  if (!do_not_wait) {
    Sleep(2.915713);
  }
  
}


latent function REROL_another_victim() {
  thePlayer.PlayLine(1002812, true);
  Sleep(1.390316);
}


latent function REROL_miles_and_miles_and_miles() {
  thePlayer.PlayLine(1077634, true);
  Sleep(2.68);
}


latent function REROL_hang_your_head_from_sadle() {
  REROL_hang_your_head_from_sadle_sync();
  Sleep(4);
}


function REROL_hang_your_head_from_sadle_sync() {
  thePlayer.PlayLine(1192331, true);
}


latent function REROL_someone_pay_for_trophy() {
  REROL_someone_pay_for_trophy_sync();
  Sleep(3);
}


function REROL_someone_pay_for_trophy_sync() {
  thePlayer.PlayLine(426514, true);
}


latent function REROL_good_size_wonder_if_someone_pay() {
  REROL_good_size_wonder_if_someone_pay_sync();
  Sleep(3.648103);
}


function REROL_good_size_wonder_if_someone_pay_sync() {
  thePlayer.PlayLine(376063, true);
}


latent function REROL_ground_splattered_with_blood() {
  thePlayer.PlayLine(433486, true);
  Sleep(4.238883);
}


class REROL_data_ground_splattered_with_blood extends RER_DialogData {
  default dialog_id = 433486;
  
}


latent function REROL_another_trail() {
  thePlayer.PlayLine(382013, true);
  Sleep(3);
}


latent function REROL_monsters_everywhere_feel_them_coming() {
  thePlayer.PlayLine(506666, true);
  Sleep(5.902488);
}


latent function REROL_should_scour_noticeboards(optional do_not_wait: bool) {
  thePlayer.PlayLine(1206920, true);
  if (!do_not_wait) {
    Sleep(10);
  }
  
}


latent function REROL_ill_take_the_contract() {
  thePlayer.PlayLine(1181938, true);
  Sleep(5);
}


latent function REROL_unusual_contract() {
  thePlayer.PlayLine(1154439, true);
  Sleep(3);
}


latent function REROL_where_will_i_find_this_monster() {
  thePlayer.PlayLine(551205, true);
  Sleep(3.900127);
}


latent function REROL_ill_tend_to_the_monster() {
  thePlayer.PlayLine(1014194, true);
  Sleep(1.773995);
}


latent function REROL_i_accept_the_challenge() {
  thePlayer.PlayLine(1005381, true);
  Sleep(1.93088);
}


latent function REROL_mhm(optional do_not_wait: bool) {
  thePlayer.PlayLine(1185176, true);
  if (!do_not_wait) {
    Sleep(1.5);
  }
  
}


class REROL_mhm_data extends RER_DialogData {
  default dialog_id = 1185176;
  
}


latent function REROL_its_over() {
  thePlayer.PlayLine(485943, true);
  Sleep(2);
}


latent function REROL_smell_of_a_rotting_corpse(optional do_not_wait: bool) {
  thePlayer.PlayLine(471806, true);
  if (!do_not_wait) {
    Sleep(4.861064);
  }
  
}


latent function REROL_tracks_a_nekker(optional do_not_wait: bool) {
  thePlayer.PlayLine(1042065, true);
  if (!do_not_wait) {
    Sleep(3.444402);
  }
  
}


latent function REROL_more_drowners(optional do_not_wait: bool) {
  thePlayer.PlayLine(1002915, true);
  if (!do_not_wait) {
    Sleep(2.397404);
  }
  
}


latent function REROL_ghouls_there_is_corpses(optional do_not_wait: bool) {
  thePlayer.PlayLine(552454, true);
  if (!do_not_wait) {
    Sleep(4.044985);
  }
  
}


latent function REROL_a_fiend(optional do_not_wait: bool) {
  thePlayer.PlayLine(1039017, true);
  if (!do_not_wait) {
    Sleep(1.181657);
  }
  
}


latent function REROL_a_werewolf(optional do_not_wait: bool) {
  thePlayer.PlayLine(577129, true);
  if (!do_not_wait) {
    Sleep(1.114805);
  }
  
}


latent function REROL_a_leshen_a_young_one(optional do_not_wait: bool) {
  thePlayer.PlayLine(566287, true);
  if (!do_not_wait) {
    Sleep(6.950611);
  }
  
}


latent function REROL_where_is_katakan(optional do_not_wait: bool) {
  thePlayer.PlayLine(569579, true);
  if (!do_not_wait) {
    Sleep(1.694507);
  }
  
}


latent function REROL_gotta_be_an_ekimmara(optional do_not_wait: bool) {
  thePlayer.PlayLine(1038390, true);
  if (!do_not_wait) {
    Sleep(1.589184);
  }
  
}


latent function REROL_an_earth_elemental(optional do_not_wait: bool) {
  thePlayer.PlayLine(573116, true);
  if (!do_not_wait) {
    Sleep(2.965688);
  }
  
}


latent function REROL_giant_wind_up_here(optional do_not_wait: bool) {
  thePlayer.PlayLine(1167973, true);
  if (!do_not_wait) {
    Sleep(10);
  }
  
}


latent function REROL_griffin_this_close_village(optional do_not_wait: bool) {
  thePlayer.PlayLine(1048275, true);
  if (!do_not_wait) {
    Sleep(4.37948);
  }
  
}


latent function REROL_wyvern_wonderful(optional do_not_wait: bool) {
  thePlayer.PlayLine(1065583, true);
  if (!do_not_wait) {
    Sleep(2.04);
  }
  
}


latent function REROL_a_cockatrice(optional do_not_wait: bool) {
  thePlayer.PlayLine(553797, true);
  if (!do_not_wait) {
    Sleep(2.04);
  }
  
}


latent function REROL_basilisk_a_little_different(optional do_not_wait: bool) {
  thePlayer.PlayLine(1170780, true);
  if (!do_not_wait) {
    Sleep(2.04);
  }
  
}


latent function REROL_a_flyer_forktail(optional do_not_wait: bool) {
  thePlayer.PlayLine(1034842, true);
  if (!do_not_wait) {
    Sleep(6.459111);
  }
  
}


latent function REROL_impossible_wight(optional do_not_wait: bool) {
  thePlayer.PlayLine(1179588, true);
  if (!do_not_wait) {
    Sleep(10);
  }
  
}


latent function REROL_a_shaelmaar_is_close(optional do_not_wait: bool) {
  thePlayer.PlayLine(1169885, true);
  if (!do_not_wait) {
    Sleep(10);
  }
  
}


latent function REROL_gotta_be_a_grave_hag(optional do_not_wait: bool) {
  thePlayer.PlayLine(1022247, true);
  if (!do_not_wait) {
    Sleep(1.757565);
  }
  
}


latent function REROL_dealing_with_foglet(optional do_not_wait: bool) {
  thePlayer.PlayLine(550020, true);
  if (!do_not_wait) {
    Sleep(3.873405);
  }
  
}


latent function REROL_a_rock_troll(optional do_not_wait: bool) {
  thePlayer.PlayLine(579959, true);
  if (!do_not_wait) {
    Sleep(1.767925);
  }
  
}


latent function REROL_bruxa_gotta_be(optional do_not_wait: bool) {
  thePlayer.PlayLine(1194000, true);
  if (!do_not_wait) {
    Sleep(3);
  }
  
}


latent function REROL_a_garkain(optional do_not_wait: bool) {
  thePlayer.PlayLine(1176030, true);
  if (!do_not_wait) {
    Sleep(10);
  }
  
}


latent function REROL_a_nightwraith(optional do_not_wait: bool) {
  thePlayer.PlayLine(1019137, true);
  if (!do_not_wait) {
    Sleep(1.030744);
  }
  
}


latent function REROL_kikimores_dammit(optional do_not_wait: bool) {
  thePlayer.PlayLine(1164863, true);
  if (!do_not_wait) {
    Sleep(5);
  }
  
}


latent function REROL_what_lured_centipedes(optional do_not_wait: bool) {
  thePlayer.PlayLine(1200276, true);
  if (!do_not_wait) {
    Sleep(5);
  }
  
}


latent function REROL_where_did_wolf_prints_come_from(optional do_not_wait: bool) {
  thePlayer.PlayLine(470770, true);
  if (!do_not_wait) {
    Sleep(1.614695);
  }
  
}


latent function REROL_half_man_half_bear(optional do_not_wait: bool) {
  thePlayer.PlayLine(587721, true);
  if (!do_not_wait) {
    Sleep(5.995551);
  }
  
}


latent function REROL_animal_hair(optional do_not_wait: bool) {
  thePlayer.PlayLine(1104764, true);
  if (!do_not_wait) {
    Sleep(3);
  }
  
}


latent function REROL_an_arachas(optional do_not_wait: bool) {
  thePlayer.PlayLine(521492, true);
  if (!do_not_wait) {
    Sleep(3);
  }
  
}


latent function REROL_harpy_feather(optional do_not_wait: bool) {
  thePlayer.PlayLine(1000722, true);
  if (!do_not_wait) {
    Sleep(2.868078);
  }
  
}


latent function REROL_siren_tracks(optional do_not_wait: bool) {
  thePlayer.PlayLine(1025599, true);
  if (!do_not_wait) {
    Sleep(3.97284);
  }
  
}


latent function REROL_interesting(optional do_not_wait: bool) {
  thePlayer.PlayLine(376165, true);
  if (!do_not_wait) {
    Sleep(3);
  }
  
}


class REROL_data_interesting extends RER_DialogData {
  default dialog_id = 376165;
  
}


latent function REROL_insectoid_excretion(optional do_not_wait: bool) {
  thePlayer.PlayLine(376165, true);
  if (!do_not_wait) {
    Sleep(1.685808);
  }
  
}


latent function REROL_so_its_a_slyzard(optional do_not_wait: bool) {
  thePlayer.PlayLine(1204696, true);
  if (!do_not_wait) {
    Sleep(5);
  }
  
}


latent function REROL_well_armed_bandits(optional do_not_wait: bool) {
  thePlayer.PlayLine(1178439, true);
  if (!do_not_wait) {
    Sleep(7);
  }
  
}


latent function REROL_trail_ends_here(optional do_not_wait: bool) {
  thePlayer.PlayLine(1091477, true);
  if (!do_not_wait) {
    Sleep(4);
  }
  
}


latent function REROL_trail_breaks_off(optional do_not_wait: bool) {
  thePlayer.PlayLine(525769, true);
  if (!do_not_wait) {
    Sleep(5.24);
  }
  
}


latent function REROL_trail_goes_on(optional do_not_wait: bool) {
  thePlayer.PlayLine(393988, true);
  if (!do_not_wait) {
    Sleep(4.365868);
  }
  
}


class REROL_data_trail_goes_on extends RER_DialogData {
  default dialog_id = 393988;
  
}


latent function REROL_wonder_they_split(optional do_not_wait: bool) {
  thePlayer.PlayLine(568165, true);
  if (!do_not_wait) {
    Sleep(3);
  }
  
}


latent function REROL_nothing(optional do_not_wait: bool) {
  thePlayer.PlayLine(1153912, true);
  if (!do_not_wait) {
    Sleep(1.5);
  }
  
}


latent function REROL_nothing_here(optional do_not_wait: bool) {
  thePlayer.PlayLine(1093719, true);
  if (!do_not_wait) {
    Sleep(1.5);
  }
  
}


latent function REROL_nothing_interesting(optional do_not_wait: bool) {
  thePlayer.PlayLine(1130083, true);
  if (!do_not_wait) {
    Sleep(1.5);
  }
  
}


latent function REROL_must_know_area_well(optional do_not_wait: bool) {
  thePlayer.PlayLine(487162, true);
  if (!do_not_wait) {
    Sleep(1.5);
  }
  
}


class REROL_must_know_area_well_data extends RER_DialogData {
  default dialog_id = 487162;
  
  default dialog_duration = 1.5;
  
}


latent function REROL_ill_check_area(optional do_not_wait: bool) {
  thePlayer.PlayLine(588352, true);
  if (!do_not_wait) {
    Sleep(1.5);
  }
  
}


class REROL_ill_check_area_data extends RER_DialogData {
  default dialog_id = 588352;
  
  default dialog_duration = 1.5;
  
}


latent function REROL_not_likely_learn_anything_from_here(optional do_not_wait: bool) {
  thePlayer.PlayLine(1202374, true);
  if (!do_not_wait) {
    Sleep(2);
  }
  
}


class REROL_not_likely_learn_anything_from_here_data extends RER_DialogData {
  default dialog_id = 1202374;
  
  default dialog_duration = 2;
  
}


latent function REROL_see_if_i_can_learn_what_out_there(optional do_not_wait: bool) {
  thePlayer.PlayLine(1041656, true);
  if (!do_not_wait) {
    Sleep(2);
  }
  
}


class REROL_see_if_i_can_learn_what_out_there_data extends RER_DialogData {
  default dialog_id = 1041656;
  
  default dialog_duration = 2;
  
}


latent function REROL_about_all_ive_learned(optional do_not_wait: bool) {
  thePlayer.PlayLine(389189, true);
  if (!do_not_wait) {
    Sleep(2);
  }
  
}


class REROL_about_all_ive_learned_data extends RER_DialogData {
  default dialog_id = 389189;
  
  default dialog_duration = 2;
  
}


latent function REROL_not_likely_learn_anymore(optional do_not_wait: bool) {
  thePlayer.PlayLine(1071533, true);
  if (!do_not_wait) {
    Sleep(1.5);
  }
  
}


class REROL_not_likely_learn_anymore_data extends RER_DialogData {
  default dialog_id = 1071533;
  
  default dialog_duration = 1.5;
  
}


latent function REROL_watch_and_learn(optional do_not_wait: bool) {
  thePlayer.PlayLine(380546, true);
  if (!do_not_wait) {
    Sleep(1.5);
  }
  
}


class REROL_watch_and_learn_data extends RER_DialogData {
  default dialog_id = 380546;
  
  default dialog_duration = 1.5;
  
}


class REROL_your_problem_is_my_problem extends RER_DialogData {
  default dialog_id = 1176632;
  
}


class REROL_no_point_fighting_bandits extends RER_DialogData {
  default dialog_id = 1176605;
  
}


class REROL_get_rid_of_bandits extends RER_DialogData {
  default dialog_id = 1176605;
  
}


class REROL_fine_show_me_where_monsters extends RER_DialogData {
  default dialog_id = 1097265;
  
}


class REROL_boys_could_handle_monsters extends RER_DialogData {
  default dialog_id = 474279;
  
}


class REROL_what_surprise_new_monster_to_kill extends RER_DialogData {
  default dialog_id = 1201113;
  
}


class REROL_got_a_different_plan extends RER_DialogData {
  default dialog_id = 1176628;
  
}


class REROL_fine_ill_see_what_i_can_do extends RER_DialogData {
  default dialog_id = 1205174;
  
}


class REROL_so_plan_to_go_out_and_meet_bandits extends RER_DialogData {
  default dialog_id = 1176438;
  
}


class REROL_how_did_he_die_where_find_body extends RER_DialogData {
  default dialog_id = 1168533;
  
}


class REROL_i_see_the_wounds extends RER_DialogData {
  default dialog_id = 570951;
  
}


class REROL_wont_give_me_any_trouble extends RER_DialogData {
  default dialog_id = 570958;
  
}


class REROL_any_witnesses extends RER_DialogData {
  default dialog_id = 570953;
  
}


class REROL_i_am_dont_seen_notice extends RER_DialogData {
  default dialog_id = 1153652;
  
}


class REROL_alright_whats_next extends RER_DialogData {
  default dialog_id = 1044520;
  
}


class REROL_thats_my_next_destination extends RER_DialogData {
  default dialog_id = 1206128;
  
}


class REROL_lemme_guess_monster_needs_killing extends RER_DialogData {
  default dialog_id = 1097914;
  
}


class REROL_im_a_monster_slayer extends RER_DialogData {
  default dialog_id = 1154437;
  
}


class REROL_alright_we_can_start extends RER_DialogData {
  default dialog_id = 1151460;
  
}


class REROL_see_the_wounds_what_kind_of_monster extends RER_DialogData {
  default dialog_id = 570951;
  
}


class REROL_give_me_a_minute extends RER_DialogData {
  default dialog_id = 1196680;
  
}


class REROL_not_the_first_time extends RER_DialogData {
  default dialog_id = 1196682;
  
}


class REROL_what_the_hell_happened extends RER_DialogData {
  default dialog_id = 1184103;
  
}


class REROL_dont_care extends RER_DialogData {
  default dialog_id = 1199256;
  
}


class REROL_need_a_bit_longer extends RER_DialogData {
  default dialog_id = 1199249;
  
}


class REROL_not_sure_monster_no_side_war extends RER_DialogData {
  default dialog_id = 1020985;
  
}


class REROL_this_is_work_for_witcher extends RER_DialogData {
  default dialog_id = 1170859;
  
}


class REROL_send_them_certain_death extends RER_DialogData {
  default dialog_id = 1170863;
  
}


class REROL_less_moaning extends RER_DialogData {
  default dialog_id = 1030584;
  
}


class REROL_greetings extends RER_DialogData {
  default dialog_id = 1189573;
  
}


class REROL_really_helpful_that extends RER_DialogData {
  default dialog_id = 566260;
  
}


class REROL_damien_greetings_witcher extends RER_DialogData {
  default dialog_id = 1150342;
  
}


class REROL_damien_i_was_certain_you_departed extends RER_DialogData {
  default dialog_id = 1187718;
  
}


class REROL_damien_you_killed_it_alone extends RER_DialogData {
  default dialog_id = 1180711;
  
}


class REROL_damien_he_died_claws extends RER_DialogData {
  default dialog_id = 1168537;
  
}


class REROL_damien_do_you_believe_me_an_amateur extends RER_DialogData {
  default dialog_id = 1168653;
  
}


class REROL_damien_i_thank_you_witcher extends RER_DialogData {
  default dialog_id = 1177101;
  
}


class REROL_damien_you_certain_of_this extends RER_DialogData {
  default dialog_id = 1171453;
  
}


class REROL_damien_how extends RER_DialogData {
  default dialog_id = 1176634;
  
}


class REROL_damien_and_what_would_that_be extends RER_DialogData {
  default dialog_id = 1176630;
  
}


class REROL_damien_sworn_loyalty_to_her_grace extends RER_DialogData {
  default dialog_id = 1180730;
  
}


class REROL_damien_wait extends RER_DialogData {
  default dialog_id = 1180770;
  
}


class REROL_damien_i_told_you_what_i_saw extends RER_DialogData {
  default dialog_id = 1151551;
  
}


class REROL_damien_thank_you_i_hope_youre_worth_the_coin extends RER_DialogData {
  default dialog_id = 1176622;
  
}


class REROL_damien_do_not_tarry_time_is_not_our_friend extends RER_DialogData {
  default dialog_id = 1196684;
  
}


class REROL_damien_i_sense_you_will_handle_it extends RER_DialogData {
  default dialog_id = 1200318;
  
}


class REROL_damien_crespi_was_the_first_to_die extends RER_DialogData {
  default dialog_id = 1168529;
  
}


class REROL_damien_i_should_double_patrols extends RER_DialogData {
  default dialog_id = 1201534;
  
}


class REROL_damien_good_luck extends RER_DialogData {
  default dialog_id = 1201510;
  
}


class REROL_damien_bandits_attack_us extends RER_DialogData {
  default dialog_id = 1199381;
  
}


class REROL_damien_will_start_at_the_beginning extends RER_DialogData {
  default dialog_id = 1199258;
  
}


class REROL_damien_must_you_always extends RER_DialogData {
  default dialog_id = 1199254;
  
}


class REROL_damien_if_thats_how_you_treat_it extends RER_DialogData {
  default dialog_id = 1185779;
  
}


class REROL_damien_i_see_the_effort_you_put extends RER_DialogData {
  default dialog_id = 1185793;
  
}


class REROL_damien_i_was_wrong_about_you extends RER_DialogData {
  default dialog_id = 1185755;
  
}


class REROL_damien_that_was_the_plan_but extends RER_DialogData {
  default dialog_id = 1185732;
  
}


class REROL_damien_you_insinuate_investigation_has_been_sloppy extends RER_DialogData {
  default dialog_id = 1168451;
  
}


class REROL_damien_who_sent_you extends RER_DialogData {
  default dialog_id = 1185804;
  
}


class REROL_damien_spit_it_out extends RER_DialogData {
  default dialog_id = 1163944;
  
}


class REROL_damien_i_agree_with_you extends RER_DialogData {
  default dialog_id = 1171963;
  
}


class REROL_damien_where_to_mission_to_complete extends RER_DialogData {
  default dialog_id = 1193705;
  
}


class REROL_damien_we_await_only_you extends RER_DialogData {
  default dialog_id = 1162270;
  
}


class REROL_damien_why_do_you_wait_save_them extends RER_DialogData {
  default dialog_id = 1207814;
  
}


class REROL_damien_onward_witcher extends RER_DialogData {
  default dialog_id = 1207812;
  
}


class REROL_damien_you_arrive_trouble_followed extends RER_DialogData {
  default dialog_id = 1170802;
  
}


class REROL_damien_do_you_have_a_plan extends RER_DialogData {
  default dialog_id = 1181615;
  
}


class REROL_damien_make_haste extends RER_DialogData {
  default dialog_id = 1170938;
  
}


class REROL_damien_all_brainless_beasts extends RER_DialogData {
  default dialog_id = 1179345;
  
}


class REROL_damien_to_a_lone_witcher extends RER_DialogData {
  default dialog_id = 1170865;
  
}


class REROL_damien_my_guardsmen_in_action extends RER_DialogData {
  default dialog_id = 1179336;
  
}


class REROL_damien_is_this_a_problem extends RER_DialogData {
  default dialog_id = 1179219;
  
}


class REROL_damien_so_it_seems extends RER_DialogData {
  default dialog_id = 1168543;
  
}


class REROL_damien_very_well_you_must_behave_less_like_thug extends RER_DialogData {
  default dialog_id = 1161577;
  
}


class REROL_damien_ive_heard_much_about_you extends RER_DialogData {
  default dialog_id = 1168024;
  
}


class REROL_damien_youd_best_maintain_silence extends RER_DialogData {
  default dialog_id = 1161579;
  
}


class REROL_graden_youre_a_witcher_will_you_help extends RER_DialogData {
  default dialog_id = 519794;
  
}


class REROL_graden_noble_of_you_thank_you extends RER_DialogData {
  default dialog_id = 402273;
  
}


class REROL_graden_certain_youve_heard_of_us extends RER_DialogData {
  default dialog_id = 401785;
  
}


class REROL_graden_matter_to_resolve extends RER_DialogData {
  default dialog_id = 1071650;
  
}


class REROL_graden_ive_lost_five_men extends RER_DialogData {
  default dialog_id = 519812;
  
}


class REROL_graden_didnt_sound_like_wolves extends RER_DialogData {
  default dialog_id = 462667;
  
}


class REROL_graden_looked_a_fiend extends RER_DialogData {
  default dialog_id = 448497;
  
}


class REROL_graden_eternal_fire_protect_you extends RER_DialogData {
  default dialog_id = 1015510;
  
}


class REROL_graden_witcher extends RER_DialogData {
  default dialog_id = 1037722;
  
}


class REROL_seems_like_you_could_use_a_witcher extends RER_DialogData {
  default dialog_id = 558185;
  
}


class REROL_geralt_im_a_witcher extends RER_DialogData {
  default dialog_id = 388551;
  
}


class REROL_glad_you_know_who_i_am extends RER_DialogData {
  default dialog_id = 401765;
  
}


class REROL_mhm_2 extends RER_DialogData {
  default dialog_id = 1173584;
  
}


class REROL_farewell extends RER_DialogData {
  default dialog_id = 452638;
  
}


class REROL_rings_a_bell extends RER_DialogData {
  default dialog_id = 402217;
  
}


class REROL_thanks_all_i_need_for_now extends RER_DialogData {
  default dialog_id = 1208816;
  
}


class REROL_harpies_got_their_nest_here extends RER_DialogData {
  default dialog_id = 1054261;
  
}


class REROL_feather_broken_there_was_fight extends RER_DialogData {
  default dialog_id = 1165318;
  
}


class REROL_corpse_decomposed_almost_completely extends RER_DialogData {
  default dialog_id = 550019;
  
}


class REROL_tracks_end_here_damn_birds_ground_clean extends RER_DialogData {
  default dialog_id = 564637;
  
}


class REROL_claw_marks_bite_marks_ripped_to_shreds extends RER_DialogData {
  default dialog_id = 564612;
  
}


class REROL_harpies_treated_him_painful_end extends RER_DialogData {
  default dialog_id = 1027713;
  
}


class REROL_smells_worse_than_it_looks extends RER_DialogData {
  default dialog_id = 507754;
  
}


class REROL_takes_strength_to_do_something_like_this extends RER_DialogData {
  default dialog_id = 507756;
  
}


class REROL_a_rock_troll_looks_like extends RER_DialogData {
  default dialog_id = 579959;
  
}


class REROL_a_man_eating_troll extends RER_DialogData {
  default dialog_id = 466660;
  
}


class REROL_large_deep_tracks extends RER_DialogData {
  default dialog_id = 1156669;
  
}


class REROL_view_from_there_spectacular extends RER_DialogData {
  default dialog_id = 533975;
  
}


class REROL_offsod_or_throw_in_soup extends RER_DialogData {
  default dialog_id = 1073877;
  
}


class REROL_jump_down_there extends RER_DialogData {
  default dialog_id = 1058437;
  
}


class REROL_wait_i_wanna_talk extends RER_DialogData {
  default dialog_id = 380699;
  
}


class REROL_talk_but_you_calm extends RER_DialogData {
  default dialog_id = 380701;
  
}


class REROL_exactly_why_you_wham_them extends RER_DialogData {
  default dialog_id = 380703;
  
}


class REROL_man_go_an_wham_go_troll extends RER_DialogData {
  default dialog_id = 380697;
  
}


class REROL_cant_let_you_get_away_with_this extends RER_DialogData {
  default dialog_id = 375420;
  
}


class REROL_ill_let_this_slide extends RER_DialogData {
  default dialog_id = 375418;
  
}


class REROL_they_where_asking_for_trouble extends RER_DialogData {
  default dialog_id = 380719;
  
}


class REROL_no_more_troll_wham extends RER_DialogData {
  default dialog_id = 442052;
  
}


class REROL_whoa_in_for_one_helluva_ride extends RER_DialogData {
  default dialog_id = 594716;
  
}


class REROL_ready_to_go_now extends RER_DialogData {
  default dialog_id = 1103826;
  
}


class REROL_vongratz_witcher extends RER_DialogData {
  default dialog_id = 1039956;
  
}


class REROL_vongratz_hey_help_help extends RER_DialogData {
  default dialog_id = 1039958;
  
}


class REROL_vongratz_geralt extends RER_DialogData {
  default dialog_id = 1039962;
  
}


class REROL_vongratz_mmmh_thank_you extends RER_DialogData {
  default dialog_id = 1003382;
  
}


class REROL_vongratz_thank_you_geralt extends RER_DialogData {
  default dialog_id = 1016518;
  
}


class REROL_sorry_gotta_go extends RER_DialogData {
  default dialog_id = 1164596;
  
}


class REROL_sorry_gotta_go_2 extends RER_DialogData {
  default dialog_id = 1164592;
  
}


class REROL_nothing_i_could_do extends RER_DialogData {
  default dialog_id = 1172465;
  
}


class REROL_damn extends RER_DialogData {
  default dialog_id = 526352;
  
}


class REROL_more_will_spawn extends RER_DialogData {
  default dialog_id = 557865;
  
}


class REROL_here_is_the_nest extends RER_DialogData {
  default dialog_id = 1070217;
  
}


class REROL_finally_the_main_nest extends RER_DialogData {
  default dialog_id = 1070227;
  
}


class REROL_good_place_for_their_nest extends RER_DialogData {
  default dialog_id = 1028862;
  
}


class REROL_monster_nest_best_destroyed extends RER_DialogData {
  default dialog_id = 1054273;
  
}


class REROL_and_one_more extends RER_DialogData {
  default dialog_id = 1132241;
  
}


class REROL_another_one extends RER_DialogData {
  default dialog_id = 1132243;
  
}


class REROL_enough_for_now extends RER_DialogData {
  default dialog_id = 1047889;
  
}


class REROL_thats_enough extends RER_DialogData {
  default dialog_id = 590997;
  
}


class REROL_not_a_single_monster extends RER_DialogData {
  default dialog_id = 1073849;
  
}


class REROL_well_well_still_learning extends RER_DialogData {
  default dialog_id = 468534;
  
}

class RE_Resources {
  public var blood_splats: array<string>;
  
  function load_resources() {
    this.load_blood_splats();
  }
  
  private function load_blood_splats() {
    blood_splats.PushBack("quests\prologue\quest_files\living_world\entities\clues\blood\lw_clue_blood_splat_big.w2ent");
    blood_splats.PushBack("quests\prologue\quest_files\living_world\entities\clues\blood\lw_clue_blood_splat_medium.w2ent");
    blood_splats.PushBack("quests\prologue\quest_files\living_world\entities\clues\blood\lw_clue_blood_splat_medium_2.w2ent");
    blood_splats.PushBack("living_world\treasure_hunting\th1003_lynx\entities\generic_clue_blood_splat.w2ent");
  }
  
  public latent function getBloodSplatsResources(): array<RER_TrailMakerTrack> {
    var i: int;
    var output: array<RER_TrailMakerTrack>;
    for (i = 0; i<this.blood_splats.Size(); i += 1) {
      output.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync(this.blood_splats[i], true))));
    }
    
    return output;
  }
  
  public latent function getCorpsesResources(): array<RER_TrailMakerTrack> {
    var corpse_resources: array<RER_TrailMakerTrack>;
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\bandit_corpses\bandit_corpses_01.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\bandit_corpses\bandit_corpses_03.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\bandit_corpses\bandit_corpses_05.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\bandit_corpses\bandit_corpses_06.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_villagers\corpse_02_nml_villager.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_villagers\corpse_03_nml_villager.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_villagers\corpse_04_nml_villager.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_villagers\corpse_05_nml_villager.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_villagers\corpse_06_nml_villager.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_villagers\corpse_07_nml_villager.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_villagers\corpse_08_nml_villager.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\novigrad_citizen\corpse_01_novigrad.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\novigrad_citizen\corpse_02_novigrad.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\novigrad_citizen\corpse_03_novigrad.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\novigrad_citizen\corpse_04_novigrad.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\novigrad_citizen\corpse_05_novigrad.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\novigrad_citizen\corpse_06_novigrad.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\novigrad_citizen\corpse_07_novigrad.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_woman\corpse_01_nml_woman.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_woman\corpse_02_nml_woman.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_woman\corpse_03_nml_woman.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_woman\corpse_04_nml_woman.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_woman\corpse_05_nml_woman.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\merchant\merchant_corpses_01.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\merchant\merchant_corpses_02.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\merchant\merchant_corpses_03.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_villagers\model\nml_villager_corpse_01.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_villagers\model\nml_villager_corpse_02.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_villagers\model\nml_villager_corpse_03.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_villagers\model\nml_villager_corpse_04.w2ent", true))));
    corpse_resources.PushBack(RER_TrailMakerTrack((CEntityTemplate)(LoadResourceAsync("environment\decorations\corpses\human_corpses\nml_villagers\model\nml_villager_corpse_05.w2ent", true))));
    return corpse_resources;
  }
  
  public latent function getPortalResource(): CEntityTemplate {
    var entity_template: CEntityTemplate;
    entity_template = (CEntityTemplate)(LoadResourceAsync("gameplay\interactive_objects\rift\rift.w2ent", true));
    return entity_template;
  }
  
}


function isHeartOfStoneActive(): bool {
  return theGame.GetDLCManager().IsEP1Available() && theGame.GetDLCManager().IsEP1Enabled();
}


function isBloodAndWineActive(): bool {
  return theGame.GetDLCManager().IsEP2Available() && theGame.GetDLCManager().IsEP2Enabled();
}

enum RER_CameraTargetType {
  RER_CameraTargetType_NODE = 0,
  RER_CameraTargetType_STATIC = 1,
  RER_CameraTargetType_BONE = 3,
}


enum RER_CameraPositionType {
  RER_CameraPositionType_ABSOLUTE = 0,
  RER_CameraPositionType_RELATIVE = 1,
}


enum RER_CameraVelocityType {
  RER_CameraVelocityType_RELATIVE = 0,
  RER_CameraVelocityType_ABSOLUTE = 1,
  RER_CameraVelocityType_FORWARD = 2,
}


struct RER_CameraScene {
  var position_type: RER_CameraPositionType;
  
  var position: Vector;
  
  var look_at_target_type: RER_CameraTargetType;
  
  var look_at_target_node: CNode;
  
  var look_at_target_static: Vector;
  
  var look_at_target_bone: CAnimatedComponent;
  
  var duration: float;
  
  var velocity_type: RER_CameraVelocityType;
  
  var velocity: Vector;
  
  var position_blending_ratio: float;
  
  var rotation_blending_ratio: float;
  
}


class RER_StaticCamera extends CStaticCamera {
  public function setFov(value: float) {
    var component: CCameraComponent;
    component = (CCameraComponent)(this.GetComponentByClassName('CCameraComponent'));
  }
  
  public function start() {
    this.Run();
  }
  
  public latent function playCameraScenes(scenes: array<RER_CameraScene>) {
    var i: int;
    var current_scene: RER_CameraScene;
    for (i = 0; i<scenes.Size(); i += 1) {
      current_scene = scenes[i];
      
      playCameraScene(current_scene);
    }
    
  }
  
  private function getRotation(scene: RER_CameraScene, current_position: Vector): EulerAngles {
    var current_rotation: EulerAngles;
    switch (scene.look_at_target_type) {
      case RER_CameraTargetType_STATIC:
      current_rotation = VecToRotation(scene.look_at_target_static-current_position);
      break;
      
      case RER_CameraTargetType_NODE:
      current_rotation = VecToRotation(scene.look_at_target_node.GetWorldPosition()-current_position);
      break;
    }
    current_rotation.Pitch *= -1;
    return current_rotation;
  }
  
  public latent function playCameraScene(scene: RER_CameraScene, optional destroy_after: bool) {
    var current_rotation: EulerAngles;
    var current_position: Vector;
    if (theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERcameraScenesDisabledOnHorse') && thePlayer.IsUsingHorse() || thePlayer.IsInCombat()) {
      return ;
    }
    
    if (!theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERcameraBlendingDisabled')) {
      this.deactivationDuration = 1.5;
      this.activationDuration = 1.5;
    }
    
    this.SetFov(theCamera.GetFov());
    if (scene.position_type==RER_CameraPositionType_RELATIVE) {
      this.TeleportWithRotation(thePlayer.GetWorldPosition()+scene.position, this.getRotation(scene, scene.position));
    }
    else  {
      this.TeleportWithRotation(scene.position, this.getRotation(scene, scene.position));
      
    }
    
    this.Run();
    Sleep(this.activationDuration);
    current_position = theCamera.GetCameraPosition();
    current_rotation = theCamera.GetCameraRotation();
    this.TeleportWithRotation(current_position, current_rotation);
    this.blendToScene(scene, current_position, current_rotation);
    this.Stop();
  }
  
  private latent function blendToScene(scene: RER_CameraScene, out current_position: Vector, out current_rotation: EulerAngles) {
    var goal_rotation: EulerAngles;
    var starting_time: float;
    var ending_time: float;
    var time_progress: float;
    starting_time = theGame.GetEngineTimeAsSeconds();
    ending_time = starting_time+scene.duration;
    while (theGame.GetEngineTimeAsSeconds()<ending_time) {
      time_progress = MinF((theGame.GetEngineTimeAsSeconds()-starting_time)/scene.duration, 0.5);
      if (scene.position_type==RER_CameraPositionType_RELATIVE) {
        current_position += (thePlayer.GetWorldPosition()+scene.position-current_position)*scene.position_blending_ratio*time_progress;
      }
      else  {
        current_position += (scene.position-current_position)*scene.position_blending_ratio*time_progress;
        
      }
      
      goal_rotation = this.getRotation(scene, current_position);
      current_rotation.Roll += AngleNormalize180(goal_rotation.Roll-current_rotation.Roll)*scene.rotation_blending_ratio*time_progress;
      current_rotation.Yaw += AngleNormalize180(goal_rotation.Yaw-current_rotation.Yaw)*scene.rotation_blending_ratio*time_progress;
      current_rotation.Pitch += AngleNormalize180(goal_rotation.Pitch-current_rotation.Pitch)*scene.rotation_blending_ratio*time_progress;
      if (scene.velocity_type==RER_CameraVelocityType_ABSOLUTE) {
        scene.position += scene.velocity;
      }
      else if (scene.velocity_type==RER_CameraVelocityType_FORWARD) {
        scene.position += VecNormalize(RotForward(current_rotation))*scene.velocity;
        
      }
      else if (scene.velocity_type==RER_CameraVelocityType_RELATIVE) {
        scene.position += VecFromHeading(theCamera.GetCameraHeading())*scene.velocity;
        
      }
      
      this.TeleportWithRotation(current_position, current_rotation);
      SleepOneFrame();
    }
    
  }
  
}


latent function RER_getStaticCamera(): RER_StaticCamera {
  var template: CEntityTemplate;
  var camera: RER_StaticCamera;
  template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\rer_static_camera.w2ent", true));
  camera = (RER_StaticCamera)(theGame.CreateEntity(template, thePlayer.GetWorldPosition(), thePlayer.GetWorldRotation()));
  return camera;
}

function RER_menu(group: name, item: name): string {
  return theGame.GetInGameConfigWrapper().GetVarValue(group, item);
}


class RE_Settings {
  public var is_enabled: bool;
  
  public var customDayMax, customDayMin, customNightMax, customNightMin: int;
  
  public var all_monster_hunt_chance_day: int;
  
  public var all_monster_contract_chance_day: int;
  
  public var all_monster_ambush_chance_day: int;
  
  public var all_monster_hunt_chance_night: int;
  
  public var all_monster_contract_chance_night: int;
  
  public var all_monster_ambush_chance_night: int;
  
  public var all_monster_hunting_ground_chance_day: int;
  
  public var all_monster_hunting_ground_chance_night: int;
  
  public var monster_contract_longevity: float;
  
  public var enableTrophies: bool;
  
  public var selectedDifficulty: RER_Difficulty;
  
  public var enemy_count_multiplier: int;
  
  public var allow_big_city_spawns: bool;
  
  public var geralt_comments_enabled: bool;
  
  public var hide_next_notifications: bool;
  
  public var enable_encounters_loot: bool;
  
  public var external_factors_coefficient: float;
  
  public var minimum_spawn_distance: float;
  
  public var spawn_diameter: float;
  
  public var kill_threshold_distance: float;
  
  public var trophies_enabled_by_encounter: array<bool>;
  
  public var crowns_amounts_by_encounter: array<int>;
  
  public var trophy_pickup_scene: bool;
  
  public var trophy_pickup_scene_chance: int;
  
  public var only_known_bestiary_creatures: bool;
  
  public var max_level_allowed: int;
  
  public var min_level_allowed: int;
  
  public var trophy_price: TrophyVariant;
  
  public var event_system_interval: float;
  
  public var foottracks_ratio: int;
  
  public var use_pathfinding_for_trails: bool;
  
  public var disable_camera_scenes: bool;
  
  public var enable_action_camera_scenes: bool;
  
  public var ecosystem_community_power_effect: float;
  
  public var ecosystem_community_power_spread: float;
  
  public var ecosystem_community_natural_death_speed: float;
  
  public var settlement_delay_multiplier: float;
  
  public var additional_delay_per_player_level: int;
  
  public var dynamic_creatures_size: bool;
  
  function loadXMLSettings() {
    var inGameConfigWrapper: CInGameConfigWrapper;
    inGameConfigWrapper = theGame.GetInGameConfigWrapper();
    this.loadMainMenuSettings(inGameConfigWrapper);
    this.loadModEnabledSettings(inGameConfigWrapper);
    this.loadMonsterHuntsChances(inGameConfigWrapper);
    this.loadMonsterContractsChances(inGameConfigWrapper);
    this.loadMonsterHuntingGroundChances(inGameConfigWrapper);
    this.loadMonsterAmbushChances(inGameConfigWrapper);
    this.loadMonsterContractsLongevity(inGameConfigWrapper);
    this.loadCustomFrequencies(inGameConfigWrapper);
    this.loadDifficultySettings(inGameConfigWrapper);
    this.loadCitySpawnSettings(inGameConfigWrapper);
    this.fillSettingsArrays();
    this.loadTrophiesSettings(inGameConfigWrapper);
    this.loadCrownsSettings(inGameConfigWrapper);
    this.loadGeraltCommentsSettings(inGameConfigWrapper);
    this.loadHideNextNotificationsSettings(inGameConfigWrapper);
    this.loadEnableEncountersLootSettings(inGameConfigWrapper);
    this.loadExternalFactorsCoefficientSettings(inGameConfigWrapper);
    this.loadAdvancedDistancesSettings(inGameConfigWrapper);
    this.loadAdvancedLevelsSettings(inGameConfigWrapper);
    this.loadOnlyKnownBestiaryCreaturesSettings(inGameConfigWrapper);
    this.loadAdvancedEventSystemSettings(inGameConfigWrapper);
    this.loadAdvancedPerformancesSettings(inGameConfigWrapper);
    this.loadEcosystemSettings(inGameConfigWrapper);
    this.dynamic_creatures_size = inGameConfigWrapper.GetVarValue('RERoptionalFeatures', 'RERdynamicCreaturesSize');
  }
  
  function loadXMLSettingsAndShowNotification() {
    this.loadXMLSettings();
    theGame.GetGuiManager().ShowNotification("Random Encounters Reworked settings loaded");
  }
  
  private function loadMainMenuSettings(inGameConfigWrapper: CInGameConfigWrapper) {
    this.enable_action_camera_scenes = inGameConfigWrapper.GetVarValue('RERoptionalFeatures', 'enableActionCameraScenes');
  }
  
  private function loadDifficultySettings(inGameConfigWrapper: CInGameConfigWrapper) {
    selectedDifficulty = StringToInt(inGameConfigWrapper.GetVarValue('RERmain', 'Difficulty'));
    this.enemy_count_multiplier = StringToInt(inGameConfigWrapper.GetVarValue('RERcreatureTypeMultiplier', 'RERenemyCountMultiplier'));
  }
  
  private function loadGeraltCommentsSettings(inGameConfigWrapper: CInGameConfigWrapper) {
    this.geralt_comments_enabled = inGameConfigWrapper.GetVarValue('RERoptionalFeatures', 'geraltComments');
  }
  
  private function loadHideNextNotificationsSettings(inGameConfigWrapper: CInGameConfigWrapper) {
    this.hide_next_notifications = inGameConfigWrapper.GetVarValue('RERoptionalFeatures', 'hideNextNotifications');
  }
  
  private function loadEnableEncountersLootSettings(inGameConfigWrapper: CInGameConfigWrapper) {
    this.enable_encounters_loot = inGameConfigWrapper.GetVarValue('RERoptionalFeatures', 'enableEncountersLoot');
  }
  
  private function loadExternalFactorsCoefficientSettings(inGameConfigWrapper: CInGameConfigWrapper) {
    this.external_factors_coefficient = StringToFloat(inGameConfigWrapper.GetVarValue('RERmain', 'externalFactorsImpact'));
  }
  
  private function loadOnlyKnownBestiaryCreaturesSettings(inGameConfigWrapper: CInGameConfigWrapper) {
    this.only_known_bestiary_creatures = inGameConfigWrapper.GetVarValue('RERoptionalFeatures', 'RERonlyKnownBestiaryCreatures');
  }
  
  private function loadTrophiesSettings(inGameConfigWrapper: CInGameConfigWrapper) {
    this.trophies_enabled_by_encounter[EncounterType_DEFAULT] = inGameConfigWrapper.GetVarValue('RERmonsterTrophies', 'RERtrophiesAmbush');
    this.trophies_enabled_by_encounter[EncounterType_HUNT] = inGameConfigWrapper.GetVarValue('RERmonsterTrophies', 'RERtrophiesHunt');
    this.trophies_enabled_by_encounter[EncounterType_CONTRACT] = inGameConfigWrapper.GetVarValue('RERmonsterTrophies', 'RERtrophiesContract');
    this.trophies_enabled_by_encounter[EncounterType_HUNTINGGROUND] = inGameConfigWrapper.GetVarValue('RERmonsterTrophies', 'RERtrophiesHuntingGround');
    this.trophy_pickup_scene_chance = StringToInt(inGameConfigWrapper.GetVarValue('RERoptionalFeatures', 'RERtrophyPickupAnimation'));
    this.trophy_pickup_scene = this.trophy_pickup_scene_chance>0;
    this.trophy_price = StringToInt(inGameConfigWrapper.GetVarValue('RERmonsterTrophies', 'RERtrophiesPrices'));
  }
  
  private function loadCrownsSettings(inGameConfigWrapper: CInGameConfigWrapper) {
    this.crowns_amounts_by_encounter[EncounterType_DEFAULT] = StringToInt(inGameConfigWrapper.GetVarValue('RERmonsterCrowns', 'RERcrownsAmbush'));
    this.crowns_amounts_by_encounter[EncounterType_HUNT] = StringToInt(inGameConfigWrapper.GetVarValue('RERmonsterCrowns', 'RERcrownsHunt'));
    this.crowns_amounts_by_encounter[EncounterType_CONTRACT] = StringToInt(inGameConfigWrapper.GetVarValue('RERmonsterCrowns', 'RERcrownsContract'));
    this.crowns_amounts_by_encounter[EncounterType_HUNTINGGROUND] = StringToInt(inGameConfigWrapper.GetVarValue('RERmonsterCrowns', 'RERcrownsHuntingGround'));
  }
  
  private function loadCustomFrequencies(inGameConfigWrapper: CInGameConfigWrapper) {
    customDayMax = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'customdFrequencyHigh'));
    customDayMin = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'customdFrequencyLow'));
    customNightMax = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'customnFrequencyHigh'));
    customNightMin = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'customnFrequencyLow'));
    settlement_delay_multiplier = StringToFloat(inGameConfigWrapper.GetVarValue('RERencountersSettlement', 'RERsettlementDelayMultiplier'));
    additional_delay_per_player_level = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'RERadditionalDelayPerPlayerLevel'));
  }
  
  private function loadMonsterHuntingGroundChances(inGameConfigWrapper: CInGameConfigWrapper) {
    this.all_monster_hunting_ground_chance_day = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersHuntingGroundDay', 'allMonsterHuntingGroundChanceDay'));
    this.all_monster_hunting_ground_chance_night = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersHuntingGroundNight', 'allMonsterHuntingGroundChanceNight'));
  }
  
  private function loadMonsterHuntsChances(inGameConfigWrapper: CInGameConfigWrapper) {
    this.all_monster_hunt_chance_day = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersHuntDay', 'allMonsterHuntChanceDay'));
    this.all_monster_hunt_chance_night = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersHuntNight', 'allMonsterHuntChanceNight'));
  }
  
  private function loadMonsterContractsChances(inGameConfigWrapper: CInGameConfigWrapper) {
    this.all_monster_contract_chance_day = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersContractDay', 'allMonsterContractChanceDay'));
    this.all_monster_contract_chance_night = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersContractNight', 'allMonsterContractChanceNight'));
  }
  
  private function loadMonsterAmbushChances(inGameConfigWrapper: CInGameConfigWrapper) {
    this.all_monster_ambush_chance_day = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersAmbushDay', 'allMonsterAmbushChanceDay'));
    this.all_monster_ambush_chance_night = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersAmbushNight', 'allMonsterAmbushChanceNight'));
  }
  
  private function loadMonsterContractsLongevity(inGameConfigWrapper: CInGameConfigWrapper) {
    this.monster_contract_longevity = StringToFloat(inGameConfigWrapper.GetVarValue('RERencountersContractDay', 'RERMonsterContractLongevity'));
  }
  
  public function shouldResetRERSettings(inGameConfigWrapper: CInGameConfigWrapper): bool {
    return StringToFloat(inGameConfigWrapper.GetVarValue('RERmain', 'RERmodVersion'))<=0;
  }
  
  private function loadModEnabledSettings(inGameConfigWrapper: CInGameConfigWrapper) {
    this.is_enabled = inGameConfigWrapper.GetVarValue('RERmain', 'RERmodEnabled');
  }
  
  public function resetRERSettings(inGameConfigWrapper: CInGameConfigWrapper) {
    var constants: RER_Constants;
    constants = RER_Constants();
    inGameConfigWrapper.ApplyGroupPreset('RERmain', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERencounters', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERencountersGeneral', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERencountersConstraints', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERencountersSettlement', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERencountersAmbushDay', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERencountersAmbushNight', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERencountersHuntDay', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERencountersHuntNight', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERencountersContractDay', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERencountersContractNight', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERencountersHuntingGroundDay', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERencountersHuntingGroundNight', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERevents', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERoptionalFeatures', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERmonsterCrowns', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERmonsterTrophies', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERkillingSpreeCustomLoot', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERecosystem', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERcreatureTypeMultiplier', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERcontracts', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERrewardsGeneral', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERcontainerRefill', 0);
    inGameConfigWrapper.ApplyGroupPreset('RERtutorials', 0);
    inGameConfigWrapper.SetVarValue('RERmain', 'RERmodVersion', constants.version);
    theGame.SaveUserSettings();
  }
  
  private function fillSettingsArrays() {
    var i: int;
    if (this.trophies_enabled_by_encounter.Size()==0) {
      for (i = 0; i<EncounterType_MAX; i += 1) {
        this.trophies_enabled_by_encounter.PushBack(false);
      }
      
    }
    
    if (this.crowns_amounts_by_encounter.Size()==0) {
      for (i = 0; i<EncounterType_MAX; i += 1) {
        this.crowns_amounts_by_encounter.PushBack(0);
      }
      
    }
    
  }
  
  private function loadAdvancedEventSystemSettings(out inGameConfigWrapper: CInGameConfigWrapper) {
    this.event_system_interval = StringToFloat(inGameConfigWrapper.GetVarValue('RERevents', 'eventSystemInterval'));
  }
  
  private function loadAdvancedDistancesSettings(out inGameConfigWrapper: CInGameConfigWrapper) {
    this.minimum_spawn_distance = StringToFloat(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'minSpawnDistance'));
    this.spawn_diameter = StringToFloat(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'spawnDiameter'));
    this.kill_threshold_distance = StringToFloat(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'killThresholdDistance'));
    if (this.minimum_spawn_distance<10 || this.spawn_diameter<10 || this.kill_threshold_distance<100) {
      inGameConfigWrapper.ApplyGroupPreset('RERadvancedDistances', 0);
      this.minimum_spawn_distance = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'minSpawnDistance'));
      this.spawn_diameter = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'spawnDiameter'));
      this.kill_threshold_distance = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'killThresholdDistance'));
      theGame.SaveUserSettings();
    }
    
  }
  
  private function loadAdvancedLevelsSettings(out inGameConfigWrapper: CInGameConfigWrapper) {
    this.min_level_allowed = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'RERminLevelRange'));
    this.max_level_allowed = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'RERmaxLevelRange'));
  }
  
  private function loadAdvancedPerformancesSettings(out inGameConfigWrapper: CInGameConfigWrapper) {
    this.foottracks_ratio = 100/Max(StringToInt(inGameConfigWrapper.GetVarValue('RERencountersGeneral', 'RERfoottracksRatio')), 1);
    this.disable_camera_scenes = inGameConfigWrapper.GetVarValue('RERoptionalFeatures', 'RERcameraScenesDisabled');
    this.use_pathfinding_for_trails = inGameConfigWrapper.GetVarValue('RERoptionalFeatures', 'RERtrailsUsePathFinding');
  }
  
  private function loadEcosystemSettings(out inGameConfigWrapper: CInGameConfigWrapper) {
    this.ecosystem_community_power_effect = StringToFloat(inGameConfigWrapper.GetVarValue('RERecosystem', 'ecosystemCommunityPowerEffect'));
    this.ecosystem_community_power_spread = StringToFloat(inGameConfigWrapper.GetVarValue('RERecosystem', 'ecosystemCommunityPowerSpread'))/100;
    this.ecosystem_community_natural_death_speed = StringToFloat(inGameConfigWrapper.GetVarValue('RERecosystem', 'ecosystemCommunityNaturalDeathSpeed'))/100;
  }
  
  private function loadCitySpawnSettings(inGameConfigWrapper: CInGameConfigWrapper) {
    this.allow_big_city_spawns = inGameConfigWrapper.GetVarValue('RERencountersSettlement', 'allowSpawnInBigCities');
  }
  
  public function toggleEnabledSettings() {
    var inGameConfigWrapper: CInGameConfigWrapper;
    inGameConfigWrapper = theGame.GetInGameConfigWrapper();
    inGameConfigWrapper.SetVarValue('RERmain', 'RERmodEnabled', !this.is_enabled);
    theGame.SaveUserSettings();
    this.loadModEnabledSettings(inGameConfigWrapper);
  }
  
}

class SpawnRoller {
  private var creatures_counters: array<int>;
  
  private var humans_variants_counters: array<int>;
  
  private var third_party_creatures_counters: array<int>;
  
  public function fill_arrays() {
    var i: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      this.creatures_counters.PushBack(0);
    }
    
    for (i = 0; i<HT_MAX; i += 1) {
      this.humans_variants_counters.PushBack(0);
    }
    
  }
  
  public function reset() {
    var i: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      this.creatures_counters[i] = 0;
    }
    
    for (i = 0; i<HT_MAX; i += 1) {
      this.humans_variants_counters[i] = 0;
    }
    
  }
  
  public function setCreatureCounter(type: CreatureType, count: int) {
    this.creatures_counters[type] = Max(count, 0);
  }
  
  public function setHumanVariantCounter(type: EHumanType, count: int) {
    this.humans_variants_counters[type] = count;
  }
  
  public function setThirdPartyCreatureCounter(type: int, count: int) {
    this.third_party_creatures_counters[type] = count;
  }
  
  public function applyFilter(filter: RER_SpawnRollerFilter) {
    var can_apply_filter: bool;
    var i: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      if (((int)(this.creatures_counters[i]*filter.multipliers[i]))>0) {
        can_apply_filter = true;
        break;
      }
      
    }
    
    if (!can_apply_filter) {
      return ;
    }
    
    for (i = 0; i<CreatureMAX; i += 1) {
      this.creatures_counters[i] = (int)((this.creatures_counters[i]*filter.multipliers[i]));
    }
    
  }
  
  public function rollCreatures(ecosystem_manager: RER_EcosystemManager, optional third_party_creatures_count: int): SpawnRoller_Roll {
    var current_position: int;
    var total: int;
    var roll: int;
    var i: int;
    var spawn_roll: SpawnRoller_Roll;
    total = 0;
    for (i = 0; i<CreatureMAX; i += 1) {
      total += this.creatures_counters[i];
    }
    
    for (i = 0; i<third_party_creatures_count; i += 1) {
      total += this.third_party_creatures_counters[i];
    }
    
    if (true) {
      ecosystem_manager.udpateCountersWithCreatureModifiers(this.creatures_counters, ecosystem_manager.getCreatureModifiersForEcosystemAreas(ecosystem_manager.getCurrentEcosystemAreas()));
    }
    
    if (total<=0) {
      spawn_roll.type = SpawnRoller_RollTypeCREATURE;
      spawn_roll.roll = CreatureNONE;
      return spawn_roll;
    }
    
    roll = RandRange(total);
    current_position = 0;
    for (i = 0; i<CreatureMAX; i += 1) {
      if (this.creatures_counters[i]>0 && roll<=current_position+this.creatures_counters[i]) {
        spawn_roll.type = SpawnRoller_RollTypeCREATURE;
        spawn_roll.roll = i;
        return spawn_roll;
      }
      
      
      current_position += this.creatures_counters[i];
    }
    
    for (i = 0; i<third_party_creatures_count; i += 1) {
      if (this.third_party_creatures_counters[i]>0 && roll<=current_position+this.third_party_creatures_counters[i]) {
        spawn_roll.type = SpawnRoller_RollTypeTHIRDPARTY;
        spawn_roll.roll = i;
        return spawn_roll;
      }
      
    }
    
    spawn_roll.type = SpawnRoller_RollTypeCREATURE;
    spawn_roll.roll = CreatureNONE;
    return spawn_roll;
  }
  
  public function rollHumansVariants(): EHumanType {
    var current_position: int;
    var total: int;
    var roll: int;
    var i: int;
    for (i = 0; i<HT_MAX; i += 1) {
      total += this.humans_variants_counters[i];
    }
    
    if (total<=0) {
      return HT_NONE;
    }
    
    roll = RandRange(total);
    current_position = 0;
    for (i = 0; i<HT_MAX; i += 1) {
      if (this.humans_variants_counters[i]>0 && roll<=current_position+this.humans_variants_counters[i]) {
        return i;
      }
      
      
      current_position += this.humans_variants_counters[i];
    }
    
    return HT_NONE;
  }
  
}


enum SpawnRoller_RollType {
  SpawnRoller_RollTypeCREATURE = 0,
  SpawnRoller_RollTypeTHIRDPARTY = 1,
}


struct SpawnRoller_Roll {
  var type: SpawnRoller_RollType;
  
  var roll: CreatureType;
  
}


class RER_SpawnRollerFilter {
  public var multipliers: array<float>;
  
  public function init(): RER_SpawnRollerFilter {
    var i: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      this.multipliers.PushBack(1);
    }
    
    return this;
  }
  
  public function allowCreature(type: CreatureType): RER_SpawnRollerFilter {
    this.multipliers[(int)(type)] = 1;
    return this;
  }
  
  public function removeCreature(type: CreatureType): RER_SpawnRollerFilter {
    this.multipliers[(int)(type)] = 0;
    return this;
  }
  
  public function removeEveryone(): RER_SpawnRollerFilter {
    return this.multiplyEveryone(0);
  }
  
  public function multiplyEveryone(multiplier: float): RER_SpawnRollerFilter {
    var i: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      this.multipliers[i] *= multiplier;
    }
    
    return this;
  }
  
  public function setOffsets(optional left_offset: CreatureType, optional right_offset: CreatureType, optional multiplier: float): RER_SpawnRollerFilter {
    var can_apply_offset: bool;
    var i: int;
    if (((int)(right_offset))==0) {
      right_offset = CreatureMAX-1;
    }
    
    for (i = 0; i<left_offset; i += 1) {
      this.multipliers[i] = multiplier;
    }
    
    for (i = right_offset+1; i<CreatureMAX; i += 1) {
      this.multipliers[i] = multiplier;
    }
    
    return this;
  }
  
}

struct SEnemyTemplate {
  var template: string;
  
  var max: int;
  
  var count: int;
  
  var bestiary_entry: string;
  
}


function makeEnemyTemplate(template: string, optional max: int, optional count: int, optional bestiary_entry: string): SEnemyTemplate {
  var enemy_template: SEnemyTemplate;
  enemy_template.template = template;
  enemy_template.max = max;
  enemy_template.count = count;
  enemy_template.bestiary_entry = bestiary_entry;
  return enemy_template;
}


struct DifficultyFactor {
  var minimum_count_easy: int;
  
  var maximum_count_easy: int;
  
  var minimum_count_medium: int;
  
  var maximum_count_medium: int;
  
  var minimum_count_hard: int;
  
  var maximum_count_hard: int;
  
}


struct EnemyTemplateList {
  var templates: array<SEnemyTemplate>;
  
  var difficulty_factor: DifficultyFactor;
  
}


function mergeEnemyTemplateLists(a, b: EnemyTemplateList): EnemyTemplateList {
  var output: EnemyTemplateList;
  var i: int;
  output.difficulty_factor.minimum_count_easy = a.difficulty_factor.minimum_count_easy+b.difficulty_factor.minimum_count_easy;
  output.difficulty_factor.maximum_count_easy = a.difficulty_factor.maximum_count_easy+b.difficulty_factor.maximum_count_easy;
  output.difficulty_factor.minimum_count_medium = a.difficulty_factor.minimum_count_medium+b.difficulty_factor.minimum_count_medium;
  output.difficulty_factor.maximum_count_medium = a.difficulty_factor.maximum_count_medium+b.difficulty_factor.maximum_count_medium;
  output.difficulty_factor.minimum_count_hard = a.difficulty_factor.minimum_count_hard+b.difficulty_factor.minimum_count_hard;
  output.difficulty_factor.maximum_count_hard = a.difficulty_factor.maximum_count_hard+b.difficulty_factor.maximum_count_hard;
  for (i = 0; i<a.templates.Size(); i += 1) {
    output.templates.PushBack(a.templates[i]);
  }
  
  for (i = 0; i<b.templates.Size(); i += 1) {
    output.templates.PushBack(b.templates[i]);
  }
  
  return output;
}


function getMaximumCountBasedOnDifficulty(out factor: DifficultyFactor, difficulty: RER_Difficulty, optional added_factor: float): int {
  if (added_factor==0) {
    added_factor = 1;
  }
  
  if (difficulty>=2) {
    return FloorF(factor.maximum_count_hard*added_factor);
  }
  
  if (difficulty>=1) {
    return FloorF(factor.maximum_count_medium*added_factor);
  }
  
  return FloorF(factor.maximum_count_easy*added_factor);
}


function getMinimumCountBasedOnDifficulty(out factor: DifficultyFactor, difficulty: RER_Difficulty, optional added_factor: float): int {
  if (added_factor==0) {
    added_factor = 1;
  }
  
  if (difficulty>=2) {
    return FloorF(factor.minimum_count_hard*added_factor);
  }
  
  if (difficulty>=1) {
    return FloorF(factor.minimum_count_medium*added_factor);
  }
  
  return FloorF(factor.minimum_count_easy*added_factor);
}


function rollDifficultyFactor(out factor: DifficultyFactor, difficulty: RER_Difficulty, optional added_factor: float): int {
  if (added_factor==0) {
    added_factor = 1;
  }
  
  if (difficulty==RER_Difficulty_RANDOM) {
    difficulty = RandRange(RER_Difficulty_RANDOM-1);
  }
  
  return RandRange(getMinimumCountBasedOnDifficulty(factor, difficulty, added_factor), getMaximumCountBasedOnDifficulty(factor, difficulty, added_factor)+1);
}


function rollDifficultyFactorWithRng(out factor: DifficultyFactor, difficulty: RER_Difficulty, optional added_factor: float, rng: RandomNumberGenerator): int {
  if (added_factor==0) {
    added_factor = 1;
  }
  
  if (difficulty==RER_Difficulty_RANDOM) {
    difficulty = RandRange(RER_Difficulty_RANDOM-1);
  }
  
  return (int)((rng.nextRange(getMinimumCountBasedOnDifficulty(factor, difficulty, added_factor), getMaximumCountBasedOnDifficulty(factor, difficulty, added_factor)+1)));
}


latent function bestiaryCanSpawnEnemyTemplateList(template_list: EnemyTemplateList, manager: CWitcherJournalManager): bool {
  var already_checked_journals: array<string>;
  var can_spawn: bool;
  var i: int;
  var j: int;
  var resource: CJournalResource;
  var entryBase: CJournalBase;
  for (i = 0; i<template_list.templates.Size(); i += 1) {
    for (j = 0; j<already_checked_journals.Size(); j += 1) {
      if (already_checked_journals[j]==template_list.templates[i].bestiary_entry) {
        continue;
      }
      
    }
    
    
    can_spawn = bestiaryCanSpawnEnemyTemplate(template_list.templates[i], manager);
    
    if (can_spawn) {
      return true;
    }
    
    
    already_checked_journals.PushBack(template_list.templates[i].bestiary_entry);
  }
  
  return false;
}


latent function bestiaryCanSpawnEnemyTemplate(enemy_template: SEnemyTemplate, manager: CWitcherJournalManager): bool {
  var resource: CJournalResource;
  var entryBase: CJournalBase;
  if (enemy_template.bestiary_entry=="") {
    NLOG("bestiary entry has no value, returning true");
    return true;
  }
  
  resource = (CJournalResource)(LoadResourceAsync(enemy_template.bestiary_entry, true));
  if (resource) {
    entryBase = resource.GetEntry();
    if (entryBase) {
      if (manager.GetEntryHasAdvancedInfo(entryBase)) {
        return true;
      }
      
    }
    else  {
    }
    
  }
  else  {
  }
  
  return false;
}

struct RER_TrailMakerTrack {
  var template: CEntityTemplate;
  
  var monster_clue_type: name;
  
  var trail_ratio_multiplier: float;
  
  default trail_ratio_multiplier = 1;
  
}


class RER_TrailMaker {
  private var trail_ratio: int;
  
  default trail_ratio = 1;
  
  private var trail_ratio_index: int;
  
  default trail_ratio_index = 1;
  
  public function setTrailRatio(ratio: int) {
    this.trail_ratio = RoundF(ratio*this.getHighestTrailRatioMultiplier());
    this.trail_ratio_index = 1;
  }
  
  private function getHighestTrailRatioMultiplier(): float {
    var i: int;
    var highest_multiplier: float;
    var tracks_entities: array<RER_MonsterClue>;
    var tracks_index: int;
    var tracks_looped: bool;
    var tracks_maximum: int;
    highest_multiplier = 0;
    for (i = 0; i<this.track_resources.Size(); i += 1) {
      if (this.track_resources[i].trail_ratio_multiplier>highest_multiplier) {
        highest_multiplier = this.track_resources[i].trail_ratio_multiplier;
      }
      
    }
    
    return highest_multiplier;
  }
  
  private var tracks_entities: array<RER_MonsterClue>;
  
  private var tracks_index: int;
  
  private var tracks_looped: bool;
  
  default tracks_looped = false;
  
  private var tracks_maximum: int;
  
  default tracks_maximum = 200;
  
  public function setTracksMaximum(maximum: int) {
    var track_resources: array<RER_TrailMakerTrack>;
    var track_resources_size: int;
    this.tracks_maximum = maximum;
  }
  
  private var track_resources: array<RER_TrailMakerTrack>;
  
  private var track_resources_size: int;
  
  public function setTrackResources(resources: array<RER_TrailMakerTrack>) {
    this.track_resources.Clear();
    this.track_resources = resources;
    this.track_resources_size = this.track_resources.Size();
  }
  
  private function getRandomTrackResource(): RER_TrailMakerTrack {
    if (track_resources_size==1) {
      return this.track_resources[0];
    }
    
    return this.track_resources[RandRange(this.track_resources_size)];
  }
  
  public function init(ratio: int, maximum: int, resources: array<RER_TrailMakerTrack>) {
    var last_track_position: Vector;
    this.setTrackResources(resources);
    this.setTracksMaximum(maximum);
    this.setTrailRatio(ratio);
  }
  
  private var last_track_position: Vector;
  
  public function addTrackHere(position: Vector, optional heading: EulerAngles): bool {
    var new_entity: RER_MonsterClue;
    var track_resource: RER_TrailMakerTrack;
    if (VecDistanceSquared2D(position, this.last_track_position)<PowF(0.5*this.trail_ratio, 2)) {
      return false;
    }
    
    this.last_track_position = position;
    if (trail_ratio_index<trail_ratio) {
      trail_ratio_index += 1;
      return false;
    }
    
    trail_ratio_index = 1;
    if (!this.tracks_looped) {
      track_resource = this.getRandomTrackResource();
      new_entity = (RER_MonsterClue)(theGame.CreateEntity(track_resource.template, position, heading));
      new_entity.voiceline_type = track_resource.monster_clue_type;
      this.tracks_entities.PushBack(new_entity);
      if (this.tracks_entities.Size()==this.tracks_maximum) {
        this.tracks_looped = true;
        this.tracks_index = -1;
      }
      
      return true;
    }
    
    this.tracks_index = (this.tracks_index+1)%this.tracks_maximum;
    this.tracks_entities[this.tracks_index].TeleportWithRotation(position, heading);
    return true;
  }
  
  public function getLastPlacedTrack(): RER_MonsterClue {
    if (this.tracks_looped && this.tracks_index>=0) {
      return this.tracks_entities[this.tracks_index];
    }
    
    return this.tracks_entities[this.tracks_entities.Size()-1];
  }
  
  public latent function drawTrail(from: Vector, to: Vector, destination_radius: float, optional trail_details_maker: RER_TrailDetailsMaker, optional trail_details_chances: float, optional use_failsafe: bool, optional use_pathfinding: bool) {
    var total_distance_to_final_point: float;
    var current_track_position: Vector;
    var current_track_translation: Vector;
    var distance_to_final_point: float;
    var final_point_radius: float;
    var number_of_tracks_created: int;
    var distance_left: float;
    var volume_path_manager: CVolumePathManager;
    var i: int;
    number_of_tracks_created = 0;
    final_point_radius = destination_radius*destination_radius;
    current_track_position = from;
    total_distance_to_final_point = VecDistanceSquared2D(from, to);
    distance_to_final_point = total_distance_to_final_point;
    if (use_pathfinding) {
      volume_path_manager = theGame.GetVolumePathManager();
    }
    
    NLOG("TrailMaker, drawing trail, with ratio = "+this.trail_ratio);
    do {
      distance_left = 1-(total_distance_to_final_point-distance_to_final_point)/total_distance_to_final_point;
      current_track_translation = VecConeRand(VecHeading(to-current_track_position), 40+50*distance_left, 0.5+distance_left*0.5, 1+1*distance_left);
      if (use_pathfinding && volume_path_manager.IsPathfindingNeeded(current_track_position, to)) {
        current_track_position = volume_path_manager.GetPointAlongPath(current_track_position, current_track_position+current_track_translation, 2);
      }
      else  {
        current_track_position += current_track_translation;
        
      }
      
      FixZAxis(current_track_position);
      if (this.addTrackHere(current_track_position, VecToRotation(to-current_track_position))) {
        number_of_tracks_created += 1;
        if (use_failsafe && number_of_tracks_created>=this.tracks_maximum) {
          break;
        }
        
      }
      
      distance_to_final_point = VecDistanceSquared2D(current_track_position, to);
      if (trail_details_chances>0 && RandRange(100)<trail_details_chances) {
        trail_details_maker.placeDetailsHere(current_track_position);
      }
      
      SleepOneFrame();
    } while (distance_to_final_point>final_point_radius);
    
  }
  
  public function hidePreviousTracks() {
    var i: int;
    var max: int;
    var where: Vector;
    max = this.tracks_entities.Size();
    where = thePlayer.GetWorldPosition()+VecRingRand(1000, 2000);
    for (i = 0; i<max; i += 1) {
      this.tracks_entities[i].Teleport(where);
    }
    
  }
  
  public function clean() {
    var i: int;
    var dont_clean_on_destroy: bool;
    for (i = 0; i<this.tracks_entities.Size(); i += 1) {
      this.tracks_entities[i].Destroy();
    }
    
    this.tracks_entities.Clear();
  }
  
  var dont_clean_on_destroy: bool;
  
  event OnDestroyed() {
    if (!this.dont_clean_on_destroy) {
      this.clean();
    }
    
  }
  
}


abstract class RER_TrailDetailsMaker {
  public latent function placeDetailsHere(position: Vector) {
  }
  
}


class RER_CorpseAndBloodTrailDetailsMaker extends RER_TrailDetailsMaker {
  public var corpse_maker: RER_TrailMaker;
  
  public var blood_maker: RER_TrailMaker;
  
  public latent function placeDetailsHere(position: Vector) {
    var number_of_blood_spills: int;
    var current_clue_position: Vector;
    var i: int;
    current_clue_position = position;
    FixZAxis(current_clue_position);
    this.corpse_maker.addTrackHere(current_clue_position, VecToRotation(VecRingRand(1, 2)));
    number_of_blood_spills = RandRange(10, 5);
    for (i = 0; i<number_of_blood_spills; i += 1) {
      current_clue_position = position+VecRingRand(0, 1.5);
      
      FixZAxis(current_clue_position);
      
      this.blood_maker.addTrackHere(current_clue_position, VecToRotation(VecRingRand(1, 2)));
    }
    
  }
  
}

enum EREZone {
  REZ_UNDEF = 0,
  REZ_NOSPAWN = 1,
  REZ_SWAMP = 2,
  REZ_CITY = 3,
}


class CModRExtra {
  public function getCustomZone(pos: Vector): EREZone {
    var zone: EREZone;
    var currentArea: string;
    var distance: float;
    zone = REZ_UNDEF;
    currentArea = AreaTypeToName(theGame.GetCommonMapManager().GetCurrentArea());
    if (currentArea=="novigrad") {
      if ((pos.X<730 && pos.X>290) && (pos.Y<2330 && pos.Y>1630)) {
        zone = REZ_CITY;
      }
      else if ((pos.X<730 && pos.X>450) && (pos.Y<1640 && pos.Y>1530)) {
        zone = REZ_CITY;
        
      }
      else if ((pos.X<930 && pos.X>700) && (pos.Y<2080 && pos.Y>1635)) {
        zone = REZ_CITY;
        
      }
      else if ((pos.X<1900 && pos.X>1600) && (pos.Y<1200 && pos.Y>700)) {
        zone = REZ_CITY;
        
      }
      else if ((pos.X<315 && pos.X>95) && (pos.Y<240 && pos.Y>20)) {
        zone = REZ_CITY;
        
      }
      else if ((pos.X<2350 && pos.X>2200) && (pos.Y<2600 && pos.Y>2450)) {
        zone = REZ_NOSPAWN;
        
      }
      else if ((pos.X<2255 && pos.X>2135) && (pos.Y<2180 && pos.Y>2010)) {
        zone = REZ_NOSPAWN;
        
      }
      else if ((pos.X<1550 && pos.X>930) && (pos.Y<1320 && pos.Y>950)) {
        zone = REZ_SWAMP;
        
      }
      else if ((pos.X<1400 && pos.X>940) && (pos.Y<-460 && pos.Y>-720)) {
        zone = REZ_SWAMP;
        
      }
      else if ((pos.X<1790 && pos.X>1320) && (pos.Y<-400 && pos.Y>-540)) {
        zone = REZ_SWAMP;
        
      }
      else if ((pos.X<2150 && pos.X>1750) && (pos.Y<-490 && pos.Y>-1090)) {
        zone = REZ_SWAMP;
        
      }
      
      distance = VecDistanceSquared2D(pos, Vector(3075, 3281.1, 23.08));
      if (distance<200*200) {
        return REZ_NOSPAWN;
      }
      
      distance = VecDistanceSquared2D(pos, Vector(2828.8, 3346.5, 23.5));
      if (distance<200*200) {
        return REZ_NOSPAWN;
      }
      
      distance = VecDistanceSquared2D(pos, Vector(2828.8, 3346.5, 23.5));
      if (distance<200*200) {
        return REZ_NOSPAWN;
      }
      
      distance = VecDistanceSquared2D(pos, Vector(3624, -326, 16.25));
      if (distance<200*200) {
        return REZ_NOSPAWN;
      }
      
    }
    else if (currentArea=="skellige") {
      if ((pos.X<30 && pos.X>-290) && (pos.Y<790 && pos.Y>470)) {
        zone = REZ_CITY;
      }
      
      
    }
    else if (currentArea=="bob") {
      if ((pos.X<-292 && pos.X>-417) && (pos.Y<-755 && pos.Y>-872)) {
        zone = REZ_NOSPAWN;
      }
      else if ((pos.X<-414 && pos.X>-636) && (pos.Y<-863 && pos.Y>-1088)) {
        zone = REZ_NOSPAWN;
        
      }
      else if ((pos.X<-142 && pos.X>-871) && (pos.Y<-1082 && pos.Y>-1637)) {
        zone = REZ_CITY;
        
      }
      
      
    }
    else if (currentArea=="wyzima_castle" || currentArea=="island_of_mist" || currentArea=="spiral") {
      zone = REZ_NOSPAWN;
      
    }
    
    return zone;
  }
  
  private function isNearNoticeboard(radius_check: float): bool {
    var entities: array<CGameplayEntity>;
    FindGameplayEntitiesInRange(entities, thePlayer, radius_check, 1, , FLAG_ExcludePlayer, , 'W3NoticeBoard');
    return entities.Size()>0;
  }
  
  private function isNearGuards(radius_check: float): bool {
    var entities: array<CGameplayEntity>;
    var i: int;
    FindGameplayEntitiesInRange(entities, thePlayer, radius_check, 100, , FLAG_ExcludePlayer, , 'CNewNPC');
    for (i = 0; i<entities.Size(); i += 1) {
      if (((CNewNPC)(entities[i])).GetNPCType()==ENGT_Guard) {
        return true;
      }
      
    }
    
    return false;
  }
  
  public function isPlayerInSettlement(optional radius_check: float): bool {
    var current_area: EAreaName;
    if (radius_check<=0) {
      radius_check = 50;
    }
    
    current_area = theGame.GetCommonMapManager().GetCurrentArea();
    if (this.isNearNoticeboard(radius_check)) {
      return true;
    }
    
    if (current_area==AN_Skellige_ArdSkellig) {
      return this.isNearGuards(radius_check);
    }
    
    return thePlayer.IsInSettlement() || this.isNearGuards(radius_check);
  }
  
  public function getRandomHumanTypeByCurrentArea(): EHumanType {
    var current_area: string;
    var spawn_roller: SpawnRoller;
    spawn_roller = new SpawnRoller in this;
    spawn_roller.fill_arrays();
    spawn_roller.reset();
    current_area = AreaTypeToName(theGame.GetCommonMapManager().GetCurrentArea());
    if (current_area=="prolog_village") {
      spawn_roller.setHumanVariantCounter(HT_BANDIT, 3);
      spawn_roller.setHumanVariantCounter(HT_CANNIBAL, 2);
      spawn_roller.setHumanVariantCounter(HT_RENEGADE, 2);
    }
    else if (current_area=="skellige") {
      spawn_roller.setHumanVariantCounter(HT_SKELBANDIT, 3);
      
      spawn_roller.setHumanVariantCounter(HT_SKELBANDIT2, 3);
      
      spawn_roller.setHumanVariantCounter(HT_SKELPIRATE, 2);
      
    }
    else if (current_area=="kaer_morhen") {
      spawn_roller.setHumanVariantCounter(HT_BANDIT, 3);
      
      spawn_roller.setHumanVariantCounter(HT_CANNIBAL, 2);
      
      spawn_roller.setHumanVariantCounter(HT_RENEGADE, 2);
      
    }
    else if (current_area=="novigrad" || current_area=="no_mans_land") {
      spawn_roller.setHumanVariantCounter(HT_NOVBANDIT, 2);
      
      spawn_roller.setHumanVariantCounter(HT_PIRATE, 2);
      
      spawn_roller.setHumanVariantCounter(HT_NILFGAARDIAN, 1);
      
      spawn_roller.setHumanVariantCounter(HT_CANNIBAL, 2);
      
      spawn_roller.setHumanVariantCounter(HT_RENEGADE, 2);
      
      spawn_roller.setHumanVariantCounter(HT_WITCHHUNTER, 1);
      
    }
    else if (current_area=="bob") {
      spawn_roller.setHumanVariantCounter(HT_NOVBANDIT, 1);
      
      spawn_roller.setHumanVariantCounter(HT_BANDIT, 4);
      
      spawn_roller.setHumanVariantCounter(HT_NILFGAARDIAN, 1);
      
      spawn_roller.setHumanVariantCounter(HT_CANNIBAL, 1);
      
      spawn_roller.setHumanVariantCounter(HT_RENEGADE, 2);
      
    }
    else  {
      spawn_roller.setHumanVariantCounter(HT_NOVBANDIT, 1);
      
      spawn_roller.setHumanVariantCounter(HT_BANDIT, 4);
      
      spawn_roller.setHumanVariantCounter(HT_NILFGAARDIAN, 1);
      
      spawn_roller.setHumanVariantCounter(HT_CANNIBAL, 1);
      
      spawn_roller.setHumanVariantCounter(HT_RENEGADE, 2);
      
    }
    
    return spawn_roller.rollHumansVariants();
  }
  
  public function IsPlayerNearWater(): bool {
    var i: int;
    var j: int;
    var pos: Vector;
    var newPos: Vector;
    var vectors: array<Vector>;
    var world: CWorld;
    var waterDepth: float;
    pos = thePlayer.GetWorldPosition();
    world = theGame.GetWorld();
    for (i = 2; i<=50; i += 2) {
      vectors = VecSphere(10, i);
      
      for (j = 0; j<vectors.Size(); j += 1) {
        newPos = pos+vectors[j];
        
        FixZAxis(newPos);
        
        waterDepth = world.GetWaterDepth(newPos, true);
        
        if (waterDepth>1.0 && waterDepth!=10000.0) {
          return true;
        }
        
      }
      
    }
    
    return false;
  }
  
  public function IsPlayerInSwamp(): bool {
    var i: int;
    var j: int;
    var pos: Vector;
    var newPos: Vector;
    var vectors: array<Vector>;
    var world: CWorld;
    var waterDepth: float;
    var wetTerrainQuantity: int;
    pos = thePlayer.GetWorldPosition();
    world = theGame.GetWorld();
    wetTerrainQuantity = 0;
    for (i = 2; i<=50; i += 2) {
      vectors = VecSphere(10, i);
      
      for (j = 0; j<vectors.Size(); j += 1) {
        newPos = pos+vectors[j];
        
        FixZAxis(newPos);
        
        waterDepth = world.GetWaterDepth(newPos, true);
        
        if (waterDepth>0 && waterDepth<1.5) {
          wetTerrainQuantity += 1;
        }
        else  {
          wetTerrainQuantity -= 1;
          
        }
        
      }
      
    }
    
    return wetTerrainQuantity>-300;
  }
  
  public function IsPlayerInForest(): bool {
    var cg: array<name>;
    var i: int;
    var j: int;
    var k: int;
    var compassPos: array<Vector>;
    var angles: array<int>;
    var angle: int;
    var vectors: array<Vector>;
    var tracePosStart: Vector;
    var tracePosEnd: Vector;
    var material: name;
    var component: CComponent;
    var outPos: Vector;
    var normal: Vector;
    var angularQuantity: int;
    var totalQuantity: int;
    var lastPos: Vector;
    var skip: bool;
    var skipIdx: int;
    cg.PushBack('Foliage');
    compassPos = VecSphere(90, 20);
    compassPos.Insert(0, thePlayer.GetWorldPosition());
    for (i = 1; i<compassPos.Size(); i += 1) {
      compassPos[i] = compassPos[0]+compassPos[i];
      
      FixZAxis(compassPos[i]);
      
      compassPos[i].Z += 10;
    }
    
    compassPos[0].Z += 10;
    angles.PushBack(0);
    angles.PushBack(90);
    angles.PushBack(180);
    angles.PushBack(270);
    totalQuantity = 0;
    skip = false;
    skipIdx = -1;
    for (i = 0; i<compassPos.Size(); i += 1) {
      for (j = 0; j<angles.Size(); j += 1) {
        angularQuantity = 0;
        
        angle = angles[j];
        
        vectors = VecArc(angle, angle+90, 5, 25);
        
        for (k = 0; k<vectors.Size(); k += 1) {
          tracePosStart = compassPos[i];
          
          tracePosEnd = tracePosStart;
          
          tracePosEnd.Z -= 10;
          
          tracePosEnd = tracePosEnd+vectors[k];
          
          FixZAxis(tracePosEnd);
          
          tracePosEnd.Z += 10;
          
          if (theGame.GetWorld().StaticTraceWithAdditionalInfo(tracePosStart, tracePosEnd, outPos, normal, material, component, cg)) {
            if (material=='default' && !component) {
              if (VecDistanceSquared(lastPos, outPos)>10) {
                lastPos = outPos;
                angularQuantity += 1;
                totalQuantity += 1;
              }
              
            }
            
          }
          
        }
        
        
        if (angularQuantity<1) {
          if (i>0 && (!skip || skipIdx==i)) {
            skip = true;
            skipIdx = i;
          }
          else  {
            continue;
            
          }
          
        }
        
      }
      
    }
    
    NLOG("number of hit foliage = "+totalQuantity);
    return totalQuantity>10;
  }
  
}


function FixZAxis(out pos: Vector) {
  var world: CWorld;
  var z: float;
  world = theGame.GetWorld();
  if (world.NavigationComputeZ(pos, pos.Z-128, pos.Z+128, z)) {
    pos.Z = z;
  }
  else if (world.PhysicsCorrectZ(pos, z)) {
    pos.Z = z;
    
  }
  
}


function VecArc(angleStart: int, angleEnd: int, angleStep: int, radius: float): array<Vector> {
  var i: int;
  var angle: float;
  var v: Vector;
  var vectors: array<Vector>;
  for (i = angleStart; i<angleEnd; i += angleStep) {
    angle = Deg2Rad(i);
    
    v = Vector(radius*CosF(angle), radius*SinF(angle), 0.0, 1.0);
    
    vectors.PushBack(v);
  }
  
  return vectors;
}


function VecSphere(angleStep: int, radius: float): array<Vector> {
  var i: int;
  var angle: float;
  var v: Vector;
  var vectors: array<Vector>;
  for (i = 0; i<360; i += angleStep) {
    angle = Deg2Rad(i);
    
    v = Vector(radius*CosF(angle), radius*SinF(angle), 0.0, 1.0);
    
    vectors.PushBack(v);
  }
  
  return vectors;
}

class RER_AddonsData {
  var addons: array<RER_BaseAddon>;
  
  var exception_areas: array<Vector>;
  
}

statemachine class RER_AddonManager {
  var master: CRandomEncounters;
  
  var states_to_process: array<name>;
  
  var processed_states: array<name>;
  
  var addons_data: RER_AddonsData;
  
  public function init(master: CRandomEncounters) {
    this.master = master;
    this.addons_data = new RER_AddonsData in this;
    this.GotoState('Loading');
  }
  
  public function registerAddon(addon: RER_BaseAddon) {
    this.addons_data.addons.PushBack(addon);
  }
  
  public function getRegisteredAddons(): array<RER_BaseAddon> {
    return this.addons_data.addons;
  }
  
}

abstract class RER_BaseAddon {
  public function canAddLoot(category: RER_LootCategory, rarity: RER_LootRarity, item_name: name, optional origin: name): bool {
    return true;
  }
  
}

function RER_playerUsesEnhancedEditionRedux(): bool {
  return StrLen(GetLocStringByKey("Redux_ToxMult"))>0;
}


function RER_playerUsesVladimirUI(): bool {
  return StrLen(GetLocStringById(2112698555))>0;
}

state Addon in RER_AddonManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_AddonManager - state "+parent.GetCurrentStateName());
  }
  
  public function getMaster(): CRandomEncounters {
    return parent.master;
  }
  
  public function finish() {
    parent.GotoState('Waiting');
  }
  
}

state Loading in RER_AddonManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_AddonManager - state Loading");
    this.Loading_main();
  }
  
  entry function Loading_main() {
    parent.states_to_process = theGame.GetDefinitionsManager().GetItemsWithTag('RER_Addon');
    parent.GotoState('Waiting');
  }
  
}

state Waiting in RER_AddonManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_AddonManager - state WAITING");
    this.Waiting_main(previous_state_name);
  }
  
  entry function Waiting_main(previous_state_name: name) {
    if (previous_state_name!='Loading') {
      parent.processed_states.PushBack(previous_state_name);
    }
    
    this.startProcessingLastState();
  }
  
  function startProcessingLastState() {
    var last_state: name;
    if (parent.states_to_process.Size()<=0) {
      return ;
    }
    
    last_state = parent.states_to_process.PopBack();
    parent.GotoState(last_state);
  }
  
}

function RER_getBestiary(): RER_Bestiary {
  var master: CRandomEncounters;
  if (getRandomEncounters(master)) {
    return master.bestiary;
  }
  
  return NULL;
}


class RER_Bestiary {
  var entries: array<RER_BestiaryEntry>;
  
  var human_entries: array<RER_BestiaryEntry>;
  
  var constants: RER_ConstantCreatureTypes;
  
  private var cache_entries_region_constraints: array<RER_BestiaryEntry>;
  
  private var cache_entries_region_constraints_timestamp: float;
  
  public function loadSettings() {
    var inGameConfigWrapper: CInGameConfigWrapper;
    var i: int;
    inGameConfigWrapper = theGame.GetInGameConfigWrapper();
    for (i = 0; i<this.entries.Size(); i += 1) {
      this.entries[i].loadSettings(inGameConfigWrapper);
    }
    
    for (i = 0; i<this.human_entries.Size(); i += 1) {
      this.human_entries[i].loadSettings(inGameConfigWrapper);
    }
    
    this.constants = RER_ConstantCreatureTypes();
  }
  
  public function getEntry(master: CRandomEncounters, type: CreatureType): RER_BestiaryEntry {
    if (type==CreatureNONE) {
      return new RER_BestiaryEntryNull in master;
    }
    
    if (type==CreatureHUMAN) {
      return this.human_entries[master.rExtra.getRandomHumanTypeByCurrentArea()];
    }
    
    return this.entries[type];
  }
  
  public latent function getRandomEntryFromBestiary(master: CRandomEncounters, encounter_type: EncounterType, optional flags: RER_BestiaryRandomBestiaryEntryFlag, optional filter: RER_SpawnRollerFilter): RER_BestiaryEntry {
    var creatures_preferences: RER_CreaturePreferences;
    var spawn_roll: SpawnRoller_Roll;
    var manager: CWitcherJournalManager;
    var can_spawn_creature: bool;
    var i: int;
    master.spawn_roller.reset();
    creatures_preferences = new RER_CreaturePreferences in this;
    creatures_preferences.setCurrentRegion(AreaTypeToName(theGame.GetCommonMapManager().GetCurrentArea()));
    NLOG((int)("getRandomEntryFromBestiary - flags = "+flags));
    if (!RER_flagEnabled(flags, RER_BREF_IGNORE_BIOMES)) {
      creatures_preferences.setIsNight(theGame.envMgr.IsNight()).setExternalFactorsCoefficient(master.settings.external_factors_coefficient).setIsNearWater(master.rExtra.IsPlayerNearWater()).setIsInForest(master.rExtra.IsPlayerInForest()).setIsInSwamp(master.rExtra.IsPlayerInSwamp());
    }
    else  {
      NLOG("getRandomEntryFromBestiary - ignore biomes");
      
    }
    
    if (RER_flagEnabled(flags, RER_BREF_IGNORE_SETTLEMENT)) {
      NLOG("getRandomEntryFromBestiary - ignore settlement");
      creatures_preferences.setIsInCity(false);
    }
    else  {
      creatures_preferences.setIsInCity(master.rExtra.isPlayerInSettlement() || master.rExtra.getCustomZone(thePlayer.GetWorldPosition())==REZ_CITY);
      
    }
    
    for (i = 0; i<CreatureMAX; i += 1) {
      this.entries[i].setCreaturePreferences(creatures_preferences, encounter_type).fillSpawnRoller(master.spawn_roller);
    }
    
    for (i = 0; i<this.third_party_entries.Size(); i += 1) {
      this.third_party_entries[i].setCreaturePreferences(creatures_preferences, encounter_type).fillSpawnRollerThirdParty(master.spawn_roller);
    }
    
    if (master.settings.only_known_bestiary_creatures && !RER_flagEnabled(flags, RER_BREF_IGNORE_BESTIARY)) {
      manager = theGame.GetJournalManager();
      for (i = 0; i<CreatureMAX; i += 1) {
        can_spawn_creature = bestiaryCanSpawnEnemyTemplateList(this.entries[i].template_list, manager);
        
        if (!can_spawn_creature) {
          master.spawn_roller.setCreatureCounter(i, 0);
        }
        
      }
      
    }
    
    if (filter) {
      master.spawn_roller.applyFilter(filter);
    }
    
    spawn_roll = master.spawn_roller.rollCreatures(master.ecosystem_manager, this.third_party_creature_counter);
    if (spawn_roll.roll==CreatureNONE) {
      return new RER_BestiaryEntryNull in this;
    }
    
    if (spawn_roll.type==SpawnRoller_RollTypeCREATURE && spawn_roll.roll==CreatureHUMAN) {
      return this.human_entries[master.rExtra.getRandomHumanTypeByCurrentArea()];
    }
    
    if (spawn_roll.type==SpawnRoller_RollTypeCREATURE) {
      return this.entries[spawn_roll.roll];
    }
    
    return this.third_party_entries[spawn_roll.roll];
  }
  
  public function doesAllowCitySpawns(): bool {
    var i: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      if (this.entries[i].city_spawn) {
        return true;
      }
      
    }
    
    return false;
  }
  
  public function init() {
    var empty_entry: RER_BestiaryEntry;
    var i: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      this.entries.PushBack(empty_entry);
    }
    
    for (i = 0; i<HT_MAX; i += 1) {
      this.human_entries.PushBack(empty_entry);
    }
    
    this.entries[CreatureALGHOUL] = new RER_BestiaryAlghoul in this;
    this.entries[CreatureARACHAS] = new RER_BestiaryArachas in this;
    this.entries[CreatureBARGHEST] = new RER_BestiaryBarghest in this;
    this.entries[CreatureBASILISK] = new RER_BestiaryBasilisk in this;
    this.entries[CreatureBEAR] = new RER_BestiaryBear in this;
    this.entries[CreatureBERSERKER] = new RER_BestiaryBerserker in this;
    this.entries[CreatureBOAR] = new RER_BestiaryBoar in this;
    this.entries[CreatureBRUXA] = new RER_BestiaryBruxa in this;
    this.entries[CreatureCENTIPEDE] = new RER_BestiaryCentipede in this;
    this.entries[CreatureCHORT] = new RER_BestiaryChort in this;
    this.entries[CreatureCOCKATRICE] = new RER_BestiaryCockatrice in this;
    this.entries[CreatureCYCLOP] = new RER_BestiaryCyclop in this;
    this.entries[CreatureDETLAFF] = new RER_BestiaryDetlaff in this;
    this.entries[CreatureDRACOLIZARD] = new RER_BestiaryDracolizard in this;
    this.entries[CreatureDROWNER] = new RER_BestiaryDrowner in this;
    this.entries[CreatureECHINOPS] = new RER_BestiaryEchinops in this;
    this.entries[CreatureEKIMMARA] = new RER_BestiaryEkimmara in this;
    this.entries[CreatureELEMENTAL] = new RER_BestiaryElemental in this;
    this.entries[CreatureENDREGA] = new RER_BestiaryEndrega in this;
    this.entries[CreatureFIEND] = new RER_BestiaryFiend in this;
    this.entries[CreatureFLEDER] = new RER_BestiaryFleder in this;
    this.entries[CreatureFOGLET] = new RER_BestiaryFogling in this;
    this.entries[CreatureFORKTAIL] = new RER_BestiaryForktail in this;
    this.entries[CreatureGARGOYLE] = new RER_BestiaryGargoyle in this;
    this.entries[CreatureGARKAIN] = new RER_BestiaryGarkain in this;
    this.entries[CreatureGHOUL] = new RER_BestiaryGhoul in this;
    this.entries[CreatureGIANT] = new RER_BestiaryGiant in this;
    this.entries[CreatureGOLEM] = new RER_BestiaryGolem in this;
    this.entries[CreatureDROWNERDLC] = new RER_BestiaryGravier in this;
    this.entries[CreatureGRYPHON] = new RER_BestiaryGryphon in this;
    this.entries[CreatureHAG] = new RER_BestiaryHag in this;
    this.entries[CreatureHARPY] = new RER_BestiaryHarpy in this;
    this.entries[CreatureHUMAN] = new RER_BestiaryHuman in this;
    this.entries[CreatureKATAKAN] = new RER_BestiaryKatakan in this;
    this.entries[CreatureKIKIMORE] = new RER_BestiaryKikimore in this;
    this.entries[CreatureLESHEN] = new RER_BestiaryLeshen in this;
    this.entries[CreatureNEKKER] = new RER_BestiaryNekker in this;
    this.entries[CreatureNIGHTWRAITH] = new RER_BestiaryNightwraith in this;
    this.entries[CreatureNOONWRAITH] = new RER_BestiaryNoonwraith in this;
    this.entries[CreaturePANTHER] = new RER_BestiaryPanther in this;
    this.entries[CreatureROTFIEND] = new RER_BestiaryRotfiend in this;
    this.entries[CreatureSHARLEY] = new RER_BestiarySharley in this;
    this.entries[CreatureSIREN] = new RER_BestiarySiren in this;
    this.entries[CreatureSKELBEAR] = new RER_BestiarySkelbear in this;
    this.entries[CreatureSKELETON] = new RER_BestiarySkeleton in this;
    this.entries[CreatureSKELTROLL] = new RER_BestiarySkeltroll in this;
    this.entries[CreatureSKELWOLF] = new RER_BestiarySkelwolf in this;
    this.entries[CreatureSPIDER] = new RER_BestiarySpider in this;
    this.entries[CreatureTROLL] = new RER_BestiaryTroll in this;
    this.entries[CreatureWEREWOLF] = new RER_BestiaryWerewolf in this;
    this.entries[CreatureWIGHT] = new RER_BestiaryWight in this;
    this.entries[CreatureWILDHUNT] = new RER_BestiaryWildhunt in this;
    this.entries[CreatureWOLF] = new RER_BestiaryWolf in this;
    this.entries[CreatureWRAITH] = new RER_BestiaryWraith in this;
    this.entries[CreatureWYVERN] = new RER_BestiaryWyvern in this;
    this.human_entries[HT_BANDIT] = new RER_BestiaryHumanBandit in this;
    this.human_entries[HT_CANNIBAL] = new RER_BestiaryHumanCannibal in this;
    this.human_entries[HT_NILFGAARDIAN] = new RER_BestiaryHumanNilf in this;
    this.human_entries[HT_NOVBANDIT] = new RER_BestiaryHumanNovbandit in this;
    this.human_entries[HT_PIRATE] = new RER_BestiaryHumanPirate in this;
    this.human_entries[HT_RENEGADE] = new RER_BestiaryHumanRenegade in this;
    this.human_entries[HT_SKELBANDIT2] = new RER_BestiaryHumanSkel2bandit in this;
    this.human_entries[HT_SKELBANDIT] = new RER_BestiaryHumanSkelbandit in this;
    this.human_entries[HT_SKELPIRATE] = new RER_BestiaryHumanSkelpirate in this;
    this.human_entries[HT_WITCHHUNTER] = new RER_BestiaryHumanWhunter in this;
    for (i = 0; i<CreatureMAX; i += 1) {
      this.entries[i].init();
    }
    
    for (i = 0; i<HT_MAX; i += 1) {
      this.human_entries[i].init();
    }
    
  }
  
  public function getCreatureTypeFromEntity(entity: CEntity): CreatureType {
    var hashed_name: string;
    hashed_name = entity.GetReadableName();
    return this.getCreatureTypeFromReadableName(hashed_name);
  }
  
  public function getCreatureTypeFromReadableName(readable_name: String): CreatureType {
    var i: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      if (this.entries[i].isCreatureHashedNameFromEntry(readable_name)) {
        return i;
      }
      
    }
    
    return CreatureNONE;
  }
  
  public function getEntriesFromSpeciesType(species: RER_SpeciesTypes): array<RER_BestiaryEntry> {
    var output: array<RER_BestiaryEntry>;
    var i: int;
    for (i = 0; i<this.entries.Size(); i += 1) {
      if (this.entries[i].species==species) {
        output.PushBack(this.entries[i]);
      }
      
    }
    
    return output;
  }
  
  public function getRandomEntryFromSpeciesType(species: RER_SpeciesTypes, rng: RandomNumberGenerator): RER_BestiaryEntry {
    var entries: array<RER_BestiaryEntry>;
    var index: int;
    entries = this.getEntriesFromSpeciesType(species);
    index = (int)(rng.nextRange(entries.Size(), 0));
    return entries[index];
  }
  
  public function getRandomSeededEntry(seed: int): RER_BestiaryEntry {
    var max: int;
    var index: int;
    this.maybeRefreshEntriesRegionConstraints();
    max = this.cache_entries_region_constraints.Size();
    index = (int)(RandNoiseF(seed, (int)(max)));
    return this.cache_entries_region_constraints[index];
  }
  
  public function isCreatureLarge(creature_type: CreatureType): bool {
    return creature_type>=this.constants.large_creature_begin;
  }
  
  public function isCreatureSmall(creature_type: CreatureType): bool {
    return !this.isCreatureLarge(creature_type);
  }
  
  private function maybeRefreshEntriesRegionConstraints() {
    var should_refresh: bool;
    var current_region: string;
    var i: int;
    var third_party_creature_counter: int;
    should_refresh = SUH_hasElapsed(this.cache_entries_region_constraints_timestamp, 60);
    if (should_refresh || this.cache_entries_region_constraints.Size()<=0) {
      current_region = SUH_getCurrentRegion();
      this.cache_entries_region_constraints_timestamp = SUH_now();
      this.cache_entries_region_constraints.Clear();
      for (i = 0; i<this.entries.Size(); i += 1) {
        if (!RER_isRegionConstraintValid(this.entries[i].region_constraint, current_region)) {
          continue;
        }
        
        
        this.cache_entries_region_constraints.PushBack(this.entries[i]);
      }
      
    }
    
  }
  
  private var third_party_creature_counter: int;
  
  default third_party_creature_counter = 0;
  
  public function getThirdPartyCreatureId(): int {
    var chosen_id: int;
    var third_party_entries: array<RER_BestiaryEntry>;
    this.third_party_creature_counter = chosen_id;
    this.third_party_creature_counter += 1;
    return chosen_id;
  }
  
  var third_party_entries: array<RER_BestiaryEntry>;
  
  public function addThirdPartyCreature(bestiary_entry: RER_BestiaryEntry) {
    if (this.hasThirdPartyCreature(bestiary_entry.type)) {
      NLOG("3rd party creature with id ["+bestiary_entry.type+"], name ["+bestiary_entry.menu_name+"] denied because id already exists");
      return ;
    }
    
    this.third_party_entries.PushBack(bestiary_entry);
  }
  
  public function hasThirdPartyCreature(third_party_id: int): bool {
    var i: int;
    for (i = 0; i<this.third_party_entries.Size(); i += 1) {
      if (this.third_party_entries[i].type==third_party_id) {
        return true;
      }
      
    }
    
    return false;
  }
  
}


enum RER_BestiaryRandomBestiaryEntryFlag {
  RER_BREF_NONE = 0,
  RER_BREF_IGNORE_SETTLEMENT = 1,
  RER_BREF_IGNORE_BIOMES = 2,
  RER_BREF_IGNORE_BESTIARY = 4,
}

abstract class RER_BestiaryEntry {
  var type: CreatureType;
  
  var species: RER_SpeciesTypes;
  
  var template_list: EnemyTemplateList;
  
  var template_hashes: array<string>;
  
  var trophy_names: array<name>;
  
  var menu_name: name;
  
  var localized_name: name;
  
  var ecosystem_impact: EcosystemCreatureImpact;
  
  var ecosystem_delay_multiplier: float;
  
  var chances_day: array<int>;
  
  var chances_night: array<int>;
  
  var creature_type_multiplier: float;
  
  default creature_type_multiplier = 1;
  
  var trophy_chance: float;
  
  var crowns_percentage: float;
  
  var region_constraint: RER_RegionConstraint;
  
  var city_spawn: bool;
  
  var possible_compositions: array<CreatureType>;
  
  public function init() {
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return preferences.setCreatureType(this.type).setChances(this.chances_day[encounter_type], this.chances_night[encounter_type]).setCitySpawnAllowed(this.city_spawn).setRegionConstraint(this.region_constraint);
  }
  
  public function loadSettings(inGameConfigWrapper: CInGameConfigWrapper) {
    var i: int;
    this.city_spawn = inGameConfigWrapper.GetVarValue('RERencountersSettlement', this.menu_name);
    this.trophy_chance = StringToInt(inGameConfigWrapper.GetVarValue('RERmonsterTrophies', this.menu_name));
    this.region_constraint = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersConstraints', this.menu_name));
    this.chances_day.Clear();
    this.chances_night.Clear();
    for (i = 0; i<EncounterType_MAX; i += 1) {
      this.chances_day.PushBack(0);
      
      this.chances_night.PushBack(0);
    }
    
    this.chances_day[EncounterType_DEFAULT] = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersAmbushDay', this.menu_name));
    this.chances_night[EncounterType_DEFAULT] = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersAmbushNight', this.menu_name));
    this.chances_day[EncounterType_HUNT] = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersHuntDay', this.menu_name));
    this.chances_night[EncounterType_HUNT] = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersHuntNight', this.menu_name));
    this.chances_day[EncounterType_CONTRACT] = 1;
    this.chances_night[EncounterType_CONTRACT] = 1;
    this.chances_day[EncounterType_HUNTINGGROUND] = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersHuntingGroundDay', this.menu_name));
    this.chances_night[EncounterType_HUNTINGGROUND] = StringToInt(inGameConfigWrapper.GetVarValue('RERencountersHuntingGroundNight', this.menu_name));
    this.creature_type_multiplier = StringToFloat(inGameConfigWrapper.GetVarValue('RERcreatureTypeMultiplier', this.menu_name));
    this.crowns_percentage = StringToFloat(inGameConfigWrapper.GetVarValue('RERmonsterCrowns', this.menu_name))/100.0;
    for (i = 0; i<this.template_list.templates.Size(); i += 1) {
      this.template_hashes.PushBack(this.template_list.templates[i].template);
    }
    
  }
  
  public function isNull(): bool {
    return this.type==CreatureNONE;
  }
  
  public function getSpawnCount(master: CRandomEncounters): int {
    return rollDifficultyFactor(this.template_list.difficulty_factor, master.settings.selectedDifficulty, master.settings.enemy_count_multiplier*this.creature_type_multiplier);
  }
  
  public latent function spawn(master: CRandomEncounters, position: Vector, optional count: int, optional density: float, optional encounter_type: EncounterType, optional flags: RER_BestiaryEntrySpawnFlag, optional custom_tag: name, optional composition_count: int, optional damage_modifier: SU_BaseDamageModifier): array<CEntity> {
    var creatures_templates: EnemyTemplateList;
    var group_positions: array<Vector>;
    var current_template: CEntityTemplate;
    var current_entity_template: SEnemyTemplate;
    var current_rotation: EulerAngles;
    var created_entity: CEntity;
    var created_entities: array<CEntity>;
    var group_positions_index: int;
    var tags_array: array<name>;
    var persistance: EPersistanceMode;
    var composition_type: CreatureType;
    var composition_entities: array<CEntity>;
    var npc: CNewNPC;
    var i: int;
    var j: int;
    var scale: float;
    var params: SCustomEffectParams;
    NLOG("BestiaryEntry, spawn() count = "+count+" "+this.type);
    if (RER_flagEnabled(flags, RER_BESF_NO_PERSIST)) {
      persistance = PM_DontPersist;
    }
    else  {
      persistance = PM_Persist;
      
    }
    
    if (count==0) {
      count = this.getSpawnCount(master);
    }
    
    if (density<=0) {
      density = 0.01;
    }
    
    flags = RER_setFlag(flags, RER_BESF_NO_TROPHY, master.settings.trophies_enabled_by_encounter[encounter_type]==false);
    creatures_templates = fillEnemyTemplateList(this.template_list, count, master.settings.only_known_bestiary_creatures && !RER_flagEnabled(flags, RER_BESF_NO_BESTIARY_FEATURE));
    group_positions = getGroupPositions(position, count, density);
    group_positions_index = 0;
    tags_array.PushBack('RandomEncountersReworked_Entity');
    if (IsNameValid(custom_tag)) {
      tags_array.PushBack(custom_tag);
    }
    
    if (encounter_type==EncounterType_CONTRACT) {
      tags_array.PushBack('ContractTarget');
      tags_array.PushBack('MonsterHuntTarget');
    }
    
    for (i = 0; i<creatures_templates.templates.Size(); i += 1) {
      current_entity_template = creatures_templates.templates[i];
      
      if (current_entity_template.count>0) {
        current_template = (CEntityTemplate)(LoadResourceAsync(current_entity_template.template, true));
        FixZAxis(group_positions[group_positions_index]);
        for (j = 0; j<current_entity_template.count; j += 1) {
          current_rotation = VecToRotation(VecRingRand(1, 2));
          
          created_entity = theGame.CreateEntity(current_template, group_positions[group_positions_index], current_rotation, , , , persistance, tags_array);
          
          if (master.settings.dynamic_creatures_size) {
            scale = (getRandomLevelBasedOnSettings(master.settings)+50.0)/(RER_getPlayerLevel()+50.0);
            NLOG("scale = "+scale);
            created_entity.GetRootAnimatedComponent().SetScale(Vector(scale, scale, scale, scale));
          }
          
          
          ((CNewNPC)(created_entity)).SetLevel(getRandomLevelBasedOnSettings(master.settings));
          
          if (!RER_flagEnabled(flags, RER_BESF_NO_TROPHY) && RandRange(100)<this.trophy_chance) {
            NLOG("adding 1 trophy "+this.type);
            ((CActor)(created_entity)).GetInventory().AddAnItem(this.trophy_names[master.settings.trophy_price], 1);
          }
          
          
          if (RandRange(100)<3) {
            ((CActor)(created_entity)).GetInventory().AddAnItem('modrer_bounty_notice', 1);
          }
          
          
          ((CActor)(created_entity)).GetInventory().AddMoney((int)((master.settings.crowns_amounts_by_encounter[encounter_type]*this.crowns_percentage*RandRangeF(1.2, 0.8))));
          
          if (!master.settings.enable_encounters_loot) {
            ((CActor)(created_entity)).GetInventory().EnableLoot(false);
          }
          
          
          created_entities.PushBack(created_entity);
          
          group_positions_index += 1;
        }
        
      }
      
    }
    
    if (damage_modifier) {
      for (i = 0; i<created_entities.Size(); i += 1) {
        npc = (CNewNPC)(created_entities[i]);
        
        if (damage_modifier.damage_received_modifier!=1.0) {
          npc.abilityManager.SetStatPointMax(BCS_Essence, npc.GetMaxHealth()*(1/damage_modifier.damage_received_modifier));
          npc.abilityManager.SetStatPointMax(BCS_Vitality, npc.GetMaxHealth()*(1/damage_modifier.damage_received_modifier));
          npc.SetHealth(npc.GetMaxHealth());
          if (damage_modifier.damage_received_modifier>0 && damage_modifier.damage_received_modifier<1) {
            params.effectType = EET_AutoEssenceRegen;
            params.creator = NULL;
            params.effectValue.valueMultiplicative = (1-damage_modifier.damage_received_modifier)/(60*2);
            NLOG("%HP regen per second = "+params.effectValue.valueMultiplicative);
            params.sourceName = "random-encounters-reworked";
            params.duration = -1;
            npc.AddEffectCustom(params);
          }
          
          if (damage_modifier.damage_received_modifier<0.5) {
            ((CActor)(npc)).AddBuffImmunity(EET_Knockdown, 'RandomEncountersReworked', false);
            ((CActor)(npc)).AddBuffImmunity(EET_HeavyKnockdown, 'RandomEncountersReworked', false);
            ((CActor)(npc)).AddBuffImmunity(EET_KnockdownTypeApplicator, 'RandomEncountersReworked', false);
          }
          
          damage_modifier.damage_received_modifier = 1;
        }
        
        
        npc.sharedutils_damage_modifiers.PushBack(damage_modifier);
      }
      
    }
    
    if (!RER_flagEnabled(flags, RER_BESF_NO_ECOSYSTEM_EFFECT)) {
      master.ecosystem_manager.updatePowerForCreatureInCurrentEcosystemAreas(this.type, created_entities.Size()*0.20, position);
    }
    
    RER_addKillingSpreeCustomLootToEntities(master.loot_manager, created_entities, master.ecosystem_frequency_multiplier);
    composition_type = this.getRandomCompositionCreature(master, encounter_type);
    composition_entities = this.spawnGroupCompositionCreatures(composition_type, master, position, count, density, encounter_type, flags, custom_tag, composition_count);
    created_entities = this.combineEntitiesArrays(created_entities, composition_entities);
    NLOG("BestiaryEntry, spawned "+created_entities.Size()+" "+this.type);
    RER_emitCreatureSpawned(master, this.type, created_entities.Size());
    SUH_makeEntitiesAlliedWithEachother(created_entities);
    return created_entities;
  }
  
  public function isCreatureHashedNameFromEntry(hashed_name: string): bool {
    var i: int;
    for (i = 0; i<this.template_hashes.Size(); i += 1) {
      if (this.template_hashes[i]==hashed_name) {
        return true;
      }
      
    }
    
    return false;
  }
  
  public latent function getStrongestCompositionCreature(master: CRandomEncounters, maximum_strength: float): CreatureType {
    var output: CreatureType;
    var creatures_preferences: RER_CreaturePreferences;
    var spawn_roll: SpawnRoller_Roll;
    var manager: CWitcherJournalManager;
    var can_spawn_creature: bool;
    var influences: RER_ConstantInfluences;
    var i: int;
    output = CreatureNONE;
    if (maximum_strength<=0) {
      return CreatureNONE;
    }
    
    if (master.settings.only_known_bestiary_creatures) {
      manager = theGame.GetJournalManager();
    }
    
    for (i = 0; i<this.possible_compositions.Size(); i += 1) {
      if (maximum_strength>0 && master.bestiary.entries[this.possible_compositions[i]].ecosystem_delay_multiplier>=maximum_strength) {
        continue;
      }
      
      
      if (master.settings.only_known_bestiary_creatures) {
        can_spawn_creature = bestiaryCanSpawnEnemyTemplateList(master.bestiary.entries[i].template_list, manager);
        if (!can_spawn_creature) {
          continue;
        }
        
      }
      
      
      if (output==CreatureNONE) {
        output = this.possible_compositions[i];
        continue;
      }
      
      
      if (master.bestiary.entries[output].ecosystem_delay_multiplier<master.bestiary.entries[this.possible_compositions[i]].ecosystem_delay_multiplier) {
        output = this.possible_compositions[i];
      }
      
    }
    
    return output;
  }
  
  public latent function getRandomCompositionCreature(master: CRandomEncounters, encounter_type: EncounterType, optional filter: RER_SpawnRollerFilter, optional flags: RER_BestiaryRandomBestiaryEntryFlag): CreatureType {
    var creatures_preferences: RER_CreaturePreferences;
    var spawn_roll: SpawnRoller_Roll;
    var manager: CWitcherJournalManager;
    var can_spawn_creature: bool;
    var influences: RER_ConstantInfluences;
    var i: int;
    if (this.possible_compositions.Size()<=0) {
      return CreatureNONE;
    }
    
    master.spawn_roller.reset();
    creatures_preferences = new RER_CreaturePreferences in this;
    creatures_preferences.setCurrentRegion(AreaTypeToName(theGame.GetCommonMapManager().GetCurrentArea()));
    for (i = 0; i<this.possible_compositions.Size(); i += 1) {
      master.bestiary.entries[this.possible_compositions[i]].setCreaturePreferences(creatures_preferences, encounter_type).fillSpawnRoller(master.spawn_roller);
    }
    
    if (master.settings.only_known_bestiary_creatures && !RER_flagEnabled(flags, RER_BREF_IGNORE_BESTIARY)) {
      manager = theGame.GetJournalManager();
      for (i = 0; i<CreatureMAX; i += 1) {
        can_spawn_creature = bestiaryCanSpawnEnemyTemplateList(master.bestiary.entries[i].template_list, manager);
        
        if (!can_spawn_creature) {
          master.spawn_roller.setCreatureCounter(i, 0);
        }
        
      }
      
    }
    
    if (filter) {
      master.spawn_roller.applyFilter(filter);
    }
    
    spawn_roll = master.spawn_roller.rollCreatures(master.ecosystem_manager);
    return spawn_roll.roll;
  }
  
  public function combineEntitiesArrays(a: array<CEntity>, b: array<CEntity>): array<CEntity> {
    var output: array<CEntity>;
    var a_size: int;
    var i: int;
    a_size = a.Size();
    for (i = 0; i<a.Size(); i += 1) {
      output.PushBack(a[i]);
    }
    
    for (i = 0; i<b.Size(); i += 1) {
      output.PushBack(b[i]);
    }
    
    return output;
  }
  
  public latent function spawnGroupCompositionCreatures(creature: CreatureType, master: CRandomEncounters, position: Vector, optional count: int, optional density: float, optional encounter_type: EncounterType, optional flags: RER_BestiaryEntrySpawnFlag, optional custom_tag: name, optional composition_count: int): array<CEntity> {
    var bestiary_entry: RER_BestiaryEntry;
    var entities: array<CEntity>;
    var max: int;
    var i: int;
    if (creature==CreatureNONE || composition_count>0) {
      return entities;
    }
    
    bestiary_entry = master.bestiary.entries[creature];
    if (RandRange(100)<75) {
      return entities;
    }
    
    max = (int)((this.ecosystem_delay_multiplier*count/bestiary_entry.ecosystem_delay_multiplier));
    count = Clamp(RandRange(max, (int)((max*0.8))), count*5, 0);
    if (count<=0) {
      return entities;
    }
    
    entities = bestiary_entry.spawn(master, position, count, density, encounter_type, flags, custom_tag, composition_count+1);
    for (i = 0; i<entities.Size(); i += 1) {
      entities[i].GetRootAnimatedComponent().SetScale(Vector(0.95, 0.95, 0.95, 0.95));
      
      ((CActor)(entities[i])).SetHealthPerc(60);
    }
    
    return entities;
  }
  
  public function toLocalizedName(): string {
    return GetLocStringByKey(this.localized_name);
  }
  
}


class RER_BestiaryEntryNull extends RER_BestiaryEntry {
  default type = CreatureNONE;
  
  public function isNull(): bool {
    return true;
  }
  
}


enum RER_BestiaryEntrySpawnFlag {
  RER_BESF_NONE = 0,
  RER_BESF_NO_TROPHY = 1,
  RER_BESF_NO_PERSIST = 2,
  RER_BESF_NO_ECOSYSTEM_EFFECT = 4,
  RER_BESF_NO_BESTIARY_FEATURE = 8,
}

class RER_BestiaryAlghoul extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureALGHOUL;
    this.species = SpeciesTypes_NECROPHAGES;
    this.menu_name = 'Alghouls';
    this.localized_name = 'option_rer_alghoul';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\alghoul_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiaryalghoul.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\alghoul_lvl2.w2ent", 3, , "gameplay\journal\bestiary\bestiaryalghoul.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\alghoul_lvl3.w2ent", 2, , "gameplay\journal\bestiary\bestiaryalghoul.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\alghoul_lvl4.w2ent", 1, , "gameplay\journal\bestiary\bestiaryalghoul.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\_quest__miscreant_greater.w2ent", , , "gameplay\journal\bestiary\bestiarymiscreant.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 2;
    this.template_list.difficulty_factor.maximum_count_easy = 2;
    this.template_list.difficulty_factor.minimum_count_medium = 2;
    this.template_list.difficulty_factor.maximum_count_medium = 3;
    this.template_list.difficulty_factor.minimum_count_hard = 3;
    this.template_list.difficulty_factor.maximum_count_hard = 4;
    this.trophy_names.PushBack('modrer_necrophage_trophy_low');
    this.trophy_names.PushBack('modrer_necrophage_trophy_medium');
    this.trophy_names.PushBack('modrer_necrophage_trophy_high');
    this.ecosystem_delay_multiplier = 3;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.self_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureALGHOUL);
    this.possible_compositions.PushBack(CreatureHAG);
    this.possible_compositions.PushBack(CreatureROTFIEND);
    this.possible_compositions.PushBack(CreatureDROWNER);
    this.possible_compositions.PushBack(CreatureDROWNERDLC);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryArachas extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureARACHAS;
    this.species = SpeciesTypes_INSECTOIDS;
    this.menu_name = 'Arachas';
    this.localized_name = 'option_rer_arachas';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\arachas_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiarycrabspider.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\arachas_lvl2__armored.w2ent", 1, , "gameplay\journal\bestiary\armoredarachas.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\arachas_lvl3__poison.w2ent", 1, , "gameplay\journal\bestiary\poisonousarachas.journal"));
    if (RER_playerUsesEnhancedEditionRedux()) {
      this.template_list.difficulty_factor.minimum_count_easy = 1;
      this.template_list.difficulty_factor.maximum_count_easy = 1;
      this.template_list.difficulty_factor.minimum_count_medium = 1;
      this.template_list.difficulty_factor.maximum_count_medium = 2;
      this.template_list.difficulty_factor.minimum_count_hard = 2;
      this.template_list.difficulty_factor.maximum_count_hard = 2;
      this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\endriaga_lvl1__worker.w2ent", , , "gameplay\journal\bestiary\bestiaryendriag.journal"));
      this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\endriaga_lvl2__tailed.w2ent", 2, , "gameplay\journal\bestiary\endriagatruten.journal"));
      this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\endriaga_lvl3__spikey.w2ent", 1, , "gameplay\journal\bestiary\endriagaworker.journal"));
    }
    else  {
      this.template_list.difficulty_factor.minimum_count_easy = 1;
      
      this.template_list.difficulty_factor.maximum_count_easy = 2;
      
      this.template_list.difficulty_factor.minimum_count_medium = 2;
      
      this.template_list.difficulty_factor.maximum_count_medium = 3;
      
      this.template_list.difficulty_factor.minimum_count_hard = 3;
      
      this.template_list.difficulty_factor.maximum_count_hard = 3;
      
    }
    
    this.trophy_names.PushBack('modrer_insectoid_trophy_low');
    this.trophy_names.PushBack('modrer_insectoid_trophy_medium');
    this.trophy_names.PushBack('modrer_insectoid_trophy_high');
    if (RER_playerUsesEnhancedEditionRedux()) {
      this.ecosystem_delay_multiplier = 15;
    }
    else  {
      this.ecosystem_delay_multiplier = 10;
      
    }
    
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.self_influence).influence(influences.friend_with).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.high_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.high_bad_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureENDREGA);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addDislikedBiome(BiomeSwamp).addDislikedBiome(BiomeWater).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryBarghest extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureBARGHEST;
    this.species = SpeciesTypes_SPECTERS;
    this.menu_name = 'Barghests';
    this.localized_name = 'option_rer_barghest';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\barghest.w2ent", , , "dlc\bob\journal\bestiary\barghests.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 2;
    this.template_list.difficulty_factor.minimum_count_hard = 2;
    this.template_list.difficulty_factor.maximum_count_hard = 2;
    this.trophy_names.PushBack('modrer_spirit_trophy_low');
    this.trophy_names.PushBack('modrer_spirit_trophy_medium');
    this.trophy_names.PushBack('modrer_spirit_trophy_high');
    this.ecosystem_delay_multiplier = 5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.self_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.kills_them).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.low_indirect_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.friend_with).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.friend_with).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_bad_influence).build();
    this.possible_compositions.PushBack(CreatureWRAITH);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeSwamp);
  }
  
}

class RER_BestiaryBasilisk extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureBASILISK;
    this.species = SpeciesTypes_DRACONIDS;
    this.menu_name = 'Basilisks';
    this.localized_name = 'option_rer_basilisk';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\basilisk_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiarybasilisk.journal"));
    if (theGame.GetDLCManager().IsEP2Available() && theGame.GetDLCManager().IsEP2Enabled()) {
      this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\basilisk_white.w2ent", , , "dlc\bob\journal\bestiary\mq7018basilisk.journal"));
    }
    
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_basilisk_trophy_low');
    this.trophy_names.PushBack('modrer_basilisk_trophy_medium');
    this.trophy_names.PushBack('modrer_basilisk_trophy_high');
    this.ecosystem_delay_multiplier = 14;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.self_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.friend_with).build();
    this.possible_compositions.PushBack(CreatureWYVERN);
    this.possible_compositions.PushBack(CreatureFORKTAIL);
    this.possible_compositions.PushBack(CreatureHARPY);
    this.possible_compositions.PushBack(CreatureSIREN);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryBear extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureBEAR;
    this.species = SpeciesTypes_BEASTS;
    this.menu_name = 'Bears';
    this.localized_name = 'option_rer_bear';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\bear_lvl1__black.w2ent", , , "gameplay\journal\bestiary\bear.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\bear_lvl2__grizzly.w2ent", , , "gameplay\journal\bestiary\bear.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\bear_lvl3__grizzly.w2ent", , , "gameplay\journal\bestiary\bear.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 2;
    this.trophy_names.PushBack('modrer_beast_trophy_low');
    this.trophy_names.PushBack('modrer_beast_trophy_medium');
    this.trophy_names.PushBack('modrer_beast_trophy_high');
    this.ecosystem_delay_multiplier = 3.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.high_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.high_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.self_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).build();
    this.possible_compositions.PushBack(CreatureWOLF);
    this.possible_compositions.PushBack(CreatureSKELWOLF);
    this.possible_compositions.PushBack(CreatureSKELBEAR);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addDislikedBiome(BiomeSwamp).addDislikedBiome(BiomeWater).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryBerserker extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureBERSERKER;
    this.species = SpeciesTypes_CURSED;
    this.menu_name = 'Berserkers';
    this.localized_name = 'option_rer_berserker';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\bear_berserker_lvl1.w2ent", , , "gameplay\journal\bestiary\bear.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 2;
    this.trophy_names.PushBack('modrer_beast_trophy_low');
    this.trophy_names.PushBack('modrer_beast_trophy_medium');
    this.trophy_names.PushBack('modrer_beast_trophy_high');
    this.ecosystem_delay_multiplier = 4;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.high_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).build();
    this.possible_compositions.PushBack(CreatureWOLF);
    this.possible_compositions.PushBack(CreatureSKELWOLF);
    this.possible_compositions.PushBack(CreatureSKELBEAR);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addDislikedBiome(BiomeSwamp).addDislikedBiome(BiomeWater).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryBoar extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureBOAR;
    this.species = SpeciesTypes_BEASTS;
    this.menu_name = 'Boars';
    this.localized_name = 'option_rer_boar';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\ep1\data\characters\npc_entities\monsters\wild_boar_ep1.w2ent", , , "dlc\bob\journal\bestiary\ep2boar.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 2;
    this.trophy_names.PushBack('modrer_beast_trophy_low');
    this.trophy_names.PushBack('modrer_beast_trophy_medium');
    this.trophy_names.PushBack('modrer_beast_trophy_high');
    this.ecosystem_delay_multiplier = 2;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.high_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.self_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryBruxa extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureBRUXA;
    this.species = SpeciesTypes_VAMPIRES;
    this.menu_name = 'Bruxae';
    this.localized_name = 'option_rer_bruxa';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\bruxa.w2ent", , , "dlc\bob\journal\bestiary\bruxa.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\bruxa_alp.w2ent", , , "dlc\bob\journal\bestiary\alp.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_vampire_trophy_low');
    this.trophy_names.PushBack('modrer_vampire_trophy_medium');
    this.trophy_names.PushBack('modrer_vampire_trophy_high');
    this.ecosystem_delay_multiplier = 11;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureBRUXA);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryBruxacity extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureBRUXA;
    this.species = SpeciesTypes_VAMPIRES;
    this.menu_name = 'Bruxaecity';
    this.localized_name = 'option_rer_bruxa';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\bruxa_alp_cloak_always_spawn.w2ent", , , "dlc\bob\journal\bestiary\alp.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\bruxa_cloak_always_spawn.w2ent", , , "dlc\bob\journal\bestiary\bruxa.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_vampire_trophy_low');
    this.trophy_names.PushBack('modrer_vampire_trophy_medium');
    this.trophy_names.PushBack('modrer_vampire_trophy_high');
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryCentipede extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureCENTIPEDE;
    this.species = SpeciesTypes_INSECTOIDS;
    this.menu_name = 'Centipedes';
    this.localized_name = 'option_rer_centipede';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\scolopendromorph.w2ent", , , "dlc\bob\journal\bestiary\scolopedromorph.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\mq7023_albino_centipede.w2ent", , , "dlc\bob\journal\bestiary\scolopedromorph.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 2;
    this.template_list.difficulty_factor.minimum_count_hard = 2;
    this.template_list.difficulty_factor.maximum_count_hard = 3;
    this.trophy_names.PushBack('modrer_insectoid_trophy_low');
    this.trophy_names.PushBack('modrer_insectoid_trophy_medium');
    this.trophy_names.PushBack('modrer_insectoid_trophy_high');
    this.ecosystem_delay_multiplier = 4.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.low_indirect_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.self_influence).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.kills_them).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.kills_them).influence(influences.low_indirect_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).build();
    this.possible_compositions.PushBack(CreatureNEKKER);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addDislikedBiome(BiomeWater).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryChort extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureCHORT;
    this.species = SpeciesTypes_RELICTS;
    this.menu_name = 'Chorts';
    this.localized_name = 'option_rer_chort';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\czart_lvl1.w2ent", , , "gameplay\journal\bestiary\czart.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_fiend_trophy_low');
    this.trophy_names.PushBack('modrer_fiend_trophy_medium');
    this.trophy_names.PushBack('modrer_fiend_trophy_high');
    this.ecosystem_delay_multiplier = 10;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureFIEND);
    this.possible_compositions.PushBack(CreatureNEKKER);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeSwamp);
  }
  
}

class RER_BestiaryCockatrice extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureCOCKATRICE;
    this.species = SpeciesTypes_DRACONIDS;
    this.menu_name = 'Cockatrices';
    this.localized_name = 'option_rer_cockatrice';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\cockatrice_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiarycockatrice.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\cockatrice_mh.w2ent", , , "gameplay\journal\bestiary\bestiarycockatrice.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_cockatrice_trophy_low');
    this.trophy_names.PushBack('modrer_cockatrice_trophy_medium');
    this.trophy_names.PushBack('modrer_cockatrice_trophy_high');
    this.ecosystem_delay_multiplier = 13.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_bad_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.self_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureWYVERN);
    this.possible_compositions.PushBack(CreatureFORKTAIL);
    this.possible_compositions.PushBack(CreatureHARPY);
    this.possible_compositions.PushBack(CreatureSIREN);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryCyclop extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureCYCLOP;
    this.species = SpeciesTypes_OGROIDS;
    this.menu_name = 'Cyclops';
    this.localized_name = 'option_rer_cyclop';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\cyclop_lvl1.w2ent", , , "gameplay\journal\bestiary\cyclops.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\cyclop_lvl2.w2ent", , , "gameplay\journal\bestiary\cyclops.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_cyclop_trophy_low');
    this.trophy_names.PushBack('modrer_cyclop_trophy_medium');
    this.trophy_names.PushBack('modrer_cyclop_trophy_high');
    this.ecosystem_delay_multiplier = 7.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.kills_them).influence(influences.friend_with).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.kills_them).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureBEAR);
    this.possible_compositions.PushBack(CreatureSKELBEAR);
    this.possible_compositions.PushBack(CreatureSIREN);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryDetlaff extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureDETLAFF;
    this.species = SpeciesTypes_VAMPIRES;
    this.menu_name = 'Higher_Vampires';
    this.localized_name = 'option_rer_higher_vampire';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\dettlaff_vampire.w2ent", 1, , "dlc\bob\journal\bestiary\dettlaffmonster.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_higher_vampire_trophy_low');
    this.trophy_names.PushBack('modrer_higher_vampire_trophy_medium');
    this.trophy_names.PushBack('modrer_higher_vampire_trophy_high');
    this.ecosystem_delay_multiplier = 25;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureBRUXA);
    this.possible_compositions.PushBack(CreatureKATAKAN);
    this.possible_compositions.PushBack(CreatureGARKAIN);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addDislikedBiome(BiomeSwamp).addDislikedBiome(BiomeWater).addDislikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryDracolizard extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureDRACOLIZARD;
    this.species = SpeciesTypes_DRACONIDS;
    this.menu_name = 'Dracolizards';
    this.localized_name = 'option_rer_dracolizard';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\oszluzg_young.w2ent", , , "dlc\bob\journal\bestiary\dracolizard.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\oszluzg.w2ent", , , "dlc\bob\journal\bestiary\dracolizard.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_dracolizard_trophy_low');
    this.trophy_names.PushBack('modrer_dracolizard_trophy_medium');
    this.trophy_names.PushBack('modrer_dracolizard_trophy_high');
    this.ecosystem_delay_multiplier = 18;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureWYVERN);
    this.possible_compositions.PushBack(CreatureFORKTAIL);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryDrowner extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureDROWNER;
    this.species = SpeciesTypes_NECROPHAGES;
    this.menu_name = 'Drowners';
    this.localized_name = 'option_rer_drowner';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\drowner_lvl1.w2ent", , , "gameplay\journal\bestiary\drowner.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\drowner_lvl2.w2ent", , , "gameplay\journal\bestiary\drowner.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\drowner_lvl3.w2ent", , , "gameplay\journal\bestiary\drowner.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\drowner_lvl4__dead.w2ent", 2, , "gameplay\journal\bestiary\drowner.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 2;
    this.template_list.difficulty_factor.maximum_count_easy = 3;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 4;
    this.template_list.difficulty_factor.minimum_count_hard = 4;
    this.template_list.difficulty_factor.maximum_count_hard = 5;
    this.trophy_names.PushBack('modrer_necrophage_trophy_low');
    this.trophy_names.PushBack('modrer_necrophage_trophy_medium');
    this.trophy_names.PushBack('modrer_necrophage_trophy_high');
    this.ecosystem_delay_multiplier = 2.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.self_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureSIREN);
    this.possible_compositions.PushBack(CreatureHAG);
    this.possible_compositions.PushBack(CreatureROTFIEND);
    this.possible_compositions.PushBack(CreatureDROWNERDLC);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addOnlyBiome(BiomeSwamp).addOnlyBiome(BiomeWater);
  }
  
}

class RER_BestiaryEchinops extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureECHINOPS;
    this.species = SpeciesTypes_CURSED;
    this.menu_name = 'Echinops';
    this.localized_name = 'option_rer_echinops';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\echinops_hard.w2ent", 1, , "dlc\bob\journal\bestiary\archespore.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\echinops_normal.w2ent", , , "dlc\bob\journal\bestiary\archespore.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\echinops_normal_lw.w2ent", , , "dlc\bob\journal\bestiary\archespore.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\echinops_turret.w2ent", 1, , "dlc\bob\journal\bestiary\archespore.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 2;
    this.template_list.difficulty_factor.maximum_count_easy = 2;
    this.template_list.difficulty_factor.minimum_count_medium = 2;
    this.template_list.difficulty_factor.maximum_count_medium = 3;
    this.template_list.difficulty_factor.minimum_count_hard = 3;
    this.template_list.difficulty_factor.maximum_count_hard = 4;
    this.trophy_names.PushBack('modrer_insectoid_trophy_low');
    this.trophy_names.PushBack('modrer_insectoid_trophy_medium');
    this.trophy_names.PushBack('modrer_insectoid_trophy_high');
    this.ecosystem_delay_multiplier = 8;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.self_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).build();
    this.possible_compositions.PushBack(CreatureARACHAS);
    this.possible_compositions.PushBack(CreatureCENTIPEDE);
    this.possible_compositions.PushBack(CreatureENDREGA);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeWater).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryEkimmara extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureEKIMMARA;
    this.species = SpeciesTypes_VAMPIRES;
    this.menu_name = 'Ekimmaras';
    this.localized_name = 'option_rer_ekimmara';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\vampire_ekima_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiaryekkima.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_ekimmara_trophy_low');
    this.trophy_names.PushBack('modrer_ekimmara_trophy_medium');
    this.trophy_names.PushBack('modrer_ekimmara_trophy_high');
    this.ecosystem_delay_multiplier = 10;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureGHOUL);
    this.possible_compositions.PushBack(CreatureALGHOUL);
    this.possible_compositions.PushBack(CreatureROTFIEND);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryElemental extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureELEMENTAL;
    this.species = SpeciesTypes_ELEMENTA;
    this.menu_name = 'Elementals';
    this.localized_name = 'option_rer_elemental';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\elemental_dao_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiaryelemental.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\elemental_dao_lvl2.w2ent", , , "gameplay\journal\bestiary\bestiaryelemental.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\elemental_dao_lvl3__ice.w2ent", , , "gameplay\journal\bestiary\bestiaryelemental.journal"));
    if (theGame.GetDLCManager().IsEP2Available() && theGame.GetDLCManager().IsEP2Enabled()) {
      this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\mq7007_item__golem_grafitti.w2ent", , , "gameplay\journal\bestiary\bestiaryelemental.journal"));
    }
    
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_elemental_trophy_low');
    this.trophy_names.PushBack('modrer_elemental_trophy_medium');
    this.trophy_names.PushBack('modrer_elemental_trophy_high');
    this.ecosystem_delay_multiplier = 12.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.friend_with).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureGOLEM);
    this.possible_compositions.PushBack(CreatureGARGOYLE);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryEndrega extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureENDREGA;
    this.species = SpeciesTypes_INSECTOIDS;
    this.menu_name = 'Endregas';
    this.localized_name = 'option_rer_endrega';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\endriaga_lvl1__worker.w2ent", , , "gameplay\journal\bestiary\bestiaryendriag.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\endriaga_lvl2__tailed.w2ent", 2, , "gameplay\journal\bestiary\endriagatruten.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\endriaga_lvl3__spikey.w2ent", 1, , "gameplay\journal\bestiary\endriagaworker.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 2;
    this.template_list.difficulty_factor.maximum_count_easy = 3;
    this.template_list.difficulty_factor.minimum_count_medium = 2;
    this.template_list.difficulty_factor.maximum_count_medium = 4;
    this.template_list.difficulty_factor.minimum_count_hard = 3;
    this.template_list.difficulty_factor.maximum_count_hard = 5;
    this.trophy_names.PushBack('modrer_endrega_trophy_low');
    this.trophy_names.PushBack('modrer_endrega_trophy_medium');
    this.trophy_names.PushBack('modrer_endrega_trophy_high');
    this.ecosystem_delay_multiplier = 3.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.friend_with).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryFiend extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureFIEND;
    this.species = SpeciesTypes_RELICTS;
    this.menu_name = 'Fiends';
    this.localized_name = 'option_rer_fiend';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\bies_lvl1.w2ent", , , "gameplay\journal\bestiary\fiend2.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\monsters\bies_lvl2a.w2ent", , , "gameplay\journal\bestiary\fiend2.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_fiend_trophy_low');
    this.trophy_names.PushBack('modrer_fiend_trophy_medium');
    this.trophy_names.PushBack('modrer_fiend_trophy_high');
    this.ecosystem_delay_multiplier = 12;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureCHORT);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeSwamp);
  }
  
}

class RER_BestiaryFleder extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureFLEDER;
    this.species = SpeciesTypes_VAMPIRES;
    this.menu_name = 'Fleders';
    this.localized_name = 'option_rer_fleder';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\fleder.w2ent", 1, , "dlc\bob\journal\bestiary\fleder.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\quests\main_quests\quest_files\q704_truth\characters\q704_protofleder.w2ent", 1, , "dlc\bob\journal\bestiary\protofleder.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_garkain_trophy_low');
    this.trophy_names.PushBack('modrer_garkain_trophy_medium');
    this.trophy_names.PushBack('modrer_garkain_trophy_high');
    this.ecosystem_delay_multiplier = 7;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.self_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureGHOUL);
    this.possible_compositions.PushBack(CreatureALGHOUL);
    this.possible_compositions.PushBack(CreatureROTFIEND);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryFogling extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureFOGLET;
    this.species = SpeciesTypes_NECROPHAGES;
    this.menu_name = 'Foglets';
    this.localized_name = 'option_rer_fogling';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\fogling_lvl1.w2ent", , , "gameplay\journal\bestiary\fogling.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\fogling_lvl2.w2ent", , , "gameplay\journal\bestiary\fogling.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\fogling_lvl3__willowisp.w2ent", , , "gameplay\journal\bestiary\bestiarymonsterhuntmh108.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\fogling_mh.w2ent", , , "gameplay\journal\bestiary\bestiarymonsterhuntmh108.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_fogling_trophy_low');
    this.trophy_names.PushBack('modrer_fogling_trophy_medium');
    this.trophy_names.PushBack('modrer_fogling_trophy_high');
    this.ecosystem_delay_multiplier = 3.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureROTFIEND);
    this.possible_compositions.PushBack(CreatureDROWNER);
    this.possible_compositions.PushBack(CreatureDROWNERDLC);
    this.possible_compositions.PushBack(CreatureFOGLET);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeSwamp).addLikedBiome(BiomeWater);
  }
  
}

class RER_BestiaryForktail extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureFORKTAIL;
    this.species = SpeciesTypes_DRACONIDS;
    this.menu_name = 'Forktails';
    this.localized_name = 'option_rer_forktail';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\forktail_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiaryforktail.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\forktail_lvl2.w2ent", , , "gameplay\journal\bestiary\bestiaryforktail.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\forktail_mh.w2ent", , , "gameplay\journal\bestiary\bestiarymonsterhuntmh208.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_forktail_trophy_low');
    this.trophy_names.PushBack('modrer_forktail_trophy_medium');
    this.trophy_names.PushBack('modrer_forktail_trophy_high');
    this.ecosystem_delay_multiplier = 7.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.self_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureWYVERN);
    this.possible_compositions.PushBack(CreatureFORKTAIL);
    this.possible_compositions.PushBack(CreatureHARPY);
    this.possible_compositions.PushBack(CreatureSIREN);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryGargoyle extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureGARGOYLE;
    this.species = SpeciesTypes_ELEMENTA;
    this.menu_name = 'Gargoyles';
    this.localized_name = 'option_rer_gargoyle';
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\monsters\gargoyle_lvl1_lvl25.w2ent", , , "gameplay\journal\bestiary\gargoyle.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_elemental_trophy_low');
    this.trophy_names.PushBack('modrer_elemental_trophy_medium');
    this.trophy_names.PushBack('modrer_elemental_trophy_high');
    this.ecosystem_delay_multiplier = 9;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryGarkain extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureGARKAIN;
    this.species = SpeciesTypes_VAMPIRES;
    this.menu_name = 'Garkains';
    this.localized_name = 'option_rer_garkain';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\garkain.w2ent", , , "dlc\bob\journal\bestiary\garkain.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\garkain_mh.w2ent", , , "dlc\bob\journal\bestiary\q704alphagarkain.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_garkain_trophy_low');
    this.trophy_names.PushBack('modrer_garkain_trophy_medium');
    this.trophy_names.PushBack('modrer_garkain_trophy_high');
    this.ecosystem_delay_multiplier = 9;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.self_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureFLEDER);
    this.possible_compositions.PushBack(CreatureGHOUL);
    this.possible_compositions.PushBack(CreatureALGHOUL);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryGhoul extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureGHOUL;
    this.species = SpeciesTypes_NECROPHAGES;
    this.menu_name = 'Ghouls';
    this.localized_name = 'option_rer_ghoul';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\ghoul_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiaryghoul.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\ghoul_lvl2.w2ent", , , "gameplay\journal\bestiary\bestiaryghoul.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\ghoul_lvl3.w2ent", , , "gameplay\journal\bestiary\bestiaryghoul.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 2;
    this.template_list.difficulty_factor.maximum_count_easy = 3;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 4;
    this.template_list.difficulty_factor.minimum_count_hard = 3;
    this.template_list.difficulty_factor.maximum_count_hard = 5;
    this.trophy_names.PushBack('modrer_necrophage_trophy_low');
    this.trophy_names.PushBack('modrer_necrophage_trophy_medium');
    this.trophy_names.PushBack('modrer_necrophage_trophy_high');
    NLOG("constant influence, "+influences.kills_them);
    this.ecosystem_delay_multiplier = 2.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.friend_with).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureALGHOUL);
    this.possible_compositions.PushBack(CreatureDROWNER);
    this.possible_compositions.PushBack(CreatureDROWNERDLC);
    this.possible_compositions.PushBack(CreatureROTFIEND);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryGiant extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureGIANT;
    this.species = SpeciesTypes_OGROIDS;
    this.menu_name = 'Giants';
    this.localized_name = 'option_rer_giant';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\q701_dagonet_giant.w2ent", , , "dlc\bob\journal\bestiary\dagonet.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\q704_cloud_giant.w2ent", , , "dlc\bob\journal\bestiary\q704cloudgiant.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\ice_giant.w2ent", , , "gameplay\journal\bestiary\icegiant.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_giant_trophy_low');
    this.trophy_names.PushBack('modrer_giant_trophy_medium');
    this.trophy_names.PushBack('modrer_giant_trophy_high');
    this.ecosystem_delay_multiplier = 10;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.kills_them).influence(influences.friend_with).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureSIREN);
    this.possible_compositions.PushBack(CreatureBEAR);
    this.possible_compositions.PushBack(CreatureSKELBEAR);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryGolem extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureGOLEM;
    this.species = SpeciesTypes_ELEMENTA;
    this.menu_name = 'Golems';
    this.localized_name = 'option_rer_golem';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\golem_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiarygolem.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\golem_lvl2__ifryt.w2ent", , , "gameplay\journal\bestiary\bestiarygolem.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\golem_lvl3.w2ent", , , "gameplay\journal\bestiary\bestiarygolem.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_elemental_trophy_low');
    this.trophy_names.PushBack('modrer_elemental_trophy_medium');
    this.trophy_names.PushBack('modrer_elemental_trophy_high');
    this.ecosystem_delay_multiplier = 10;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureGARGOYLE);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryGravier extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureDROWNERDLC;
    this.species = SpeciesTypes_NECROPHAGES;
    this.menu_name = 'Graviers';
    this.localized_name = 'option_rer_scurver';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\gravier.w2ent", , , "dlc\bob\journal\bestiary\parszywiec.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 3;
    this.template_list.difficulty_factor.minimum_count_medium = 2;
    this.template_list.difficulty_factor.maximum_count_medium = 4;
    this.template_list.difficulty_factor.minimum_count_hard = 3;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.trophy_names.PushBack('modrer_necrophage_trophy_low');
    this.trophy_names.PushBack('modrer_necrophage_trophy_medium');
    this.trophy_names.PushBack('modrer_necrophage_trophy_high');
    this.ecosystem_delay_multiplier = 2.75;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureDROWNER);
    this.possible_compositions.PushBack(CreatureROTFIEND);
    this.possible_compositions.PushBack(CreatureGHOUL);
    this.possible_compositions.PushBack(CreatureHAG);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addOnlyBiome(BiomeSwamp).addOnlyBiome(BiomeWater);
  }
  
}

class RER_BestiaryGryphon extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureGRYPHON;
    this.species = SpeciesTypes_HYBRIDS;
    this.menu_name = 'Gryphons';
    this.localized_name = 'option_rer_gryphon';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\gryphon_lvl1.w2ent", , , "gameplay\journal\bestiary\griffin.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\gryphon_lvl2.w2ent", , , "gameplay\journal\bestiary\griffin.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\gryphon_lvl3__volcanic.w2ent", , , "gameplay\journal\bestiary\bestiarymonsterhuntmh301.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\gryphon_mh__volcanic.w2ent", , , "gameplay\journal\bestiary\bestiarymonsterhuntmh301.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_griffin_trophy_low');
    this.trophy_names.PushBack('modrer_griffin_trophy_medium');
    this.trophy_names.PushBack('modrer_griffin_trophy_high');
    this.ecosystem_delay_multiplier = 13.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.self_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.friend_with).build();
    this.possible_compositions.PushBack(CreatureFORKTAIL);
    this.possible_compositions.PushBack(CreatureHARPY);
    this.possible_compositions.PushBack(CreatureSIREN);
    this.possible_compositions.PushBack(CreatureWYVERN);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryHag extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureHAG;
    this.species = SpeciesTypes_NECROPHAGES;
    this.menu_name = 'Hags';
    this.localized_name = 'option_rer_hag';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\hag_grave_lvl1.w2ent", , , "gameplay\journal\bestiary\gravehag.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\hag_water_lvl1.w2ent", , , "gameplay\journal\bestiary\waterhag.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\hag_water_lvl2.w2ent", , , "gameplay\journal\bestiary\waterhag.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\hag_water_mh.w2ent", , , "gameplay\journal\bestiary\bestiarymonsterhuntmh203.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_grave_hag_trophy_low');
    this.trophy_names.PushBack('modrer_grave_hag_trophy_medium');
    this.trophy_names.PushBack('modrer_grave_hag_trophy_high');
    this.ecosystem_delay_multiplier = 4;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureGHOUL);
    this.possible_compositions.PushBack(CreatureROTFIEND);
    this.possible_compositions.PushBack(CreatureDROWNER);
    this.possible_compositions.PushBack(CreatureDROWNERDLC);
    this.possible_compositions.PushBack(CreatureALGHOUL);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addOnlyBiome(BiomeSwamp).addOnlyBiome(BiomeWater);
  }
  
}

class RER_BestiaryHarpy extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureHARPY;
    this.species = SpeciesTypes_HYBRIDS;
    this.menu_name = 'Harpies';
    this.localized_name = 'option_rer_harpy';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\harpy_lvl1.w2ent", , , "gameplay\journal\bestiary\harpy.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\harpy_lvl2.w2ent", , , "gameplay\journal\bestiary\harpy.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\harpy_lvl2_customize.w2ent", , , "gameplay\journal\bestiary\harpy.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\harpy_lvl3__erynia.w2ent", 1, , "gameplay\journal\bestiary\erynia.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 4;
    this.template_list.difficulty_factor.maximum_count_medium = 5;
    this.template_list.difficulty_factor.minimum_count_hard = 5;
    this.template_list.difficulty_factor.maximum_count_hard = 7;
    this.trophy_names.PushBack('modrer_harpy_trophy_low');
    this.trophy_names.PushBack('modrer_harpy_trophy_medium');
    this.trophy_names.PushBack('modrer_harpy_trophy_high');
    this.ecosystem_delay_multiplier = 2.25;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.high_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addDislikedBiome(BiomeSwamp).addDislikedBiome(BiomeWater).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryHuman extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureHUMAN;
    this.species = SpeciesTypes_BEASTS;
    this.menu_name = 'Humans';
    this.localized_name = 'option_rer_human';
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nml_deserters_axe_normal.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nml_deserters_bow.w2ent", 3));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nml_deserters_sword_easy.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\novigrad_bandit_shield_1haxe.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\novigrad_bandit_shield_1hclub.w2ent"));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 5;
    this.template_list.difficulty_factor.minimum_count_hard = 4;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.trophy_names.PushBack('modrer_human_trophy_low');
    this.trophy_names.PushBack('modrer_human_trophy_medium');
    this.trophy_names.PushBack('modrer_human_trophy_high');
    this.ecosystem_delay_multiplier = 2.25;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.kills_them).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.high_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.high_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.kills_them).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.high_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.high_indirect_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryKatakan extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureKATAKAN;
    this.species = SpeciesTypes_VAMPIRES;
    this.menu_name = 'Katakans';
    this.localized_name = 'option_rer_katakan';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\vampire_katakan_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiarykatakan.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\vampire_katakan_lvl3.w2ent", , , "gameplay\journal\bestiary\bestiarykatakan.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\vampire_katakan_mh.w2ent", , , "gameplay\journal\bestiary\bestiarymonsterhuntmh304.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_katakan_trophy_low');
    this.trophy_names.PushBack('modrer_katakan_trophy_medium');
    this.trophy_names.PushBack('modrer_katakan_trophy_high');
    this.ecosystem_delay_multiplier = 11;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureGHOUL);
    this.possible_compositions.PushBack(CreatureALGHOUL);
    this.possible_compositions.PushBack(CreatureROTFIEND);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryKikimore extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureKIKIMORE;
    this.species = SpeciesTypes_INSECTOIDS;
    this.menu_name = 'Kikimores';
    this.localized_name = 'option_rer_kikimore';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\kikimore.w2ent", 1, , "dlc\bob\journal\bestiary\kikimoraworker.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\kikimore_small.w2ent", , , "dlc\bob\journal\bestiary\kikimora.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 2;
    this.template_list.difficulty_factor.minimum_count_medium = 2;
    this.template_list.difficulty_factor.maximum_count_medium = 3;
    this.template_list.difficulty_factor.minimum_count_hard = 3;
    this.template_list.difficulty_factor.maximum_count_hard = 4;
    this.trophy_names.PushBack('modrer_insectoid_trophy_low');
    this.trophy_names.PushBack('modrer_insectoid_trophy_medium');
    this.trophy_names.PushBack('modrer_insectoid_trophy_high');
    this.ecosystem_delay_multiplier = 6;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.low_indirect_influence).influence(influences.friend_with).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.high_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.self_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.high_bad_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.no_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.high_bad_influence).influence(influences.no_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryLeshen extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureLESHEN;
    this.species = SpeciesTypes_RELICTS;
    this.menu_name = 'Leshens';
    this.localized_name = 'option_rer_leshen';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\lessog_lvl1.w2ent", , , "gameplay\journal\bestiary\leshy1.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\lessog_lvl2__ancient.w2ent", , , "gameplay\journal\bestiary\sq204ancientleszen.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\lessog_mh.w2ent", , , "gameplay\journal\bestiary\bestiarymonsterhuntmh302.journal"));
    if (theGame.GetDLCManager().IsEP2Available() && theGame.GetDLCManager().IsEP2Enabled()) {
      this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\spriggan.w2ent", , , "dlc\bob\journal\bestiary\mq7002spriggan.journal"));
    }
    
    this.ecosystem_delay_multiplier = 15;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.friend_with).influence(influences.kills_them).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.friend_with).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.self_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).build();
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_leshen_trophy_low');
    this.trophy_names.PushBack('modrer_leshen_trophy_medium');
    this.trophy_names.PushBack('modrer_leshen_trophy_high');
    this.possible_compositions.PushBack(CreatureWOLF);
    this.possible_compositions.PushBack(CreatureSKELWOLF);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addOnlyBiome(BiomeForest);
  }
  
}

class RER_BestiaryNekker extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureNEKKER;
    this.species = SpeciesTypes_OGROIDS;
    this.menu_name = 'Nekkers';
    this.localized_name = 'option_rer_nekker';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nekker_lvl1.w2ent", , , "gameplay\journal\bestiary\nekker.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nekker_lvl2.w2ent", , , "gameplay\journal\bestiary\nekker.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nekker_lvl2_customize.w2ent", , , "gameplay\journal\bestiary\nekker.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nekker_lvl3_customize.w2ent", , , "gameplay\journal\bestiary\nekker.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nekker_lvl3__warrior.w2ent", 2, , "gameplay\journal\bestiary\nekker.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nekker_mh__warrior.w2ent", 1, , "gameplay\journal\bestiary\bestiarymonsterhuntmh202.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 4;
    this.template_list.difficulty_factor.maximum_count_easy = 5;
    this.template_list.difficulty_factor.minimum_count_medium = 4;
    this.template_list.difficulty_factor.maximum_count_medium = 6;
    this.template_list.difficulty_factor.minimum_count_hard = 5;
    this.template_list.difficulty_factor.maximum_count_hard = 7;
    this.trophy_names.PushBack('modrer_nekker_trophy_low');
    this.trophy_names.PushBack('modrer_nekker_trophy_medium');
    this.trophy_names.PushBack('modrer_nekker_trophy_high');
    this.ecosystem_delay_multiplier = 2.25;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.self_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryNightwraith extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureNIGHTWRAITH;
    this.species = SpeciesTypes_SPECTERS;
    this.menu_name = 'NightWraiths';
    this.localized_name = 'option_rer_nightwraith';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nightwraith_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiarymoonwright.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nightwraith_lvl2.w2ent", , , "gameplay\journal\bestiary\bestiarymoonwright.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nightwraith_lvl3.w2ent", , , "gameplay\journal\bestiary\bestiarymoonwright.journal"));
    if (theGame.GetDLCManager().IsEP2Available() && theGame.GetDLCManager().IsEP2Enabled()) {
      this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\nightwraith_banshee.w2ent", , , "dlc\bob\journal\bestiary\beanshie.journal"));
    }
    
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_nightwraith_trophy_low');
    this.trophy_names.PushBack('modrer_nightwraith_trophy_medium');
    this.trophy_names.PushBack('modrer_nightwraith_trophy_high');
    this.ecosystem_delay_multiplier = 9;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureWRAITH);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryNoonwraith extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureNOONWRAITH;
    this.species = SpeciesTypes_SPECTERS;
    this.menu_name = 'NoonWraiths';
    this.localized_name = 'option_rer_noonwraith';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\noonwraith_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiarynoonwright.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\noonwraith_lvl2.w2ent", , , "gameplay\journal\bestiary\bestiarynoonwright.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\noonwraith_lvl3.w2ent", , , "gameplay\journal\bestiary\bestiarynoonwright.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\_quest__noonwright_pesta.w2ent", , , "gameplay\journal\bestiary\bestiarynoonwright.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_noonwraith_trophy_low');
    this.trophy_names.PushBack('modrer_noonwraith_trophy_medium');
    this.trophy_names.PushBack('modrer_noonwraith_trophy_high');
    this.ecosystem_delay_multiplier = 6;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureSKELWOLF);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryPanther extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreaturePANTHER;
    this.species = SpeciesTypes_BEASTS;
    this.menu_name = 'Panthers';
    this.localized_name = 'option_rer_panther';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\panther_black.w2ent", , , "dlc\bob\journal\bestiary\panther.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\panther_leopard.w2ent", , , "dlc\bob\journal\bestiary\panther.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\panther_mountain.w2ent", , , "dlc\bob\journal\bestiary\panther.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 2;
    this.trophy_names.PushBack('modrer_beast_trophy_low');
    this.trophy_names.PushBack('modrer_beast_trophy_medium');
    this.trophy_names.PushBack('modrer_beast_trophy_high');
    this.ecosystem_delay_multiplier = 2.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.high_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.self_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addDislikedBiome(BiomeSwamp).addDislikedBiome(BiomeWater).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryRotfiend extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureROTFIEND;
    this.species = SpeciesTypes_NECROPHAGES;
    this.menu_name = 'Rotfiends';
    this.localized_name = 'option_rer_rotfiend';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\rotfiend_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiarygreaterrotfiend.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\rotfiend_lvl2.w2ent", 1, , "gameplay\journal\bestiary\bestiarygreaterrotfiend.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 3;
    this.template_list.difficulty_factor.minimum_count_medium = 2;
    this.template_list.difficulty_factor.maximum_count_medium = 4;
    this.template_list.difficulty_factor.minimum_count_hard = 3;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.trophy_names.PushBack('modrer_necrophage_trophy_low');
    this.trophy_names.PushBack('modrer_necrophage_trophy_medium');
    this.trophy_names.PushBack('modrer_necrophage_trophy_high');
    this.ecosystem_delay_multiplier = 2.75;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.friend_with).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureGHOUL);
    this.possible_compositions.PushBack(CreatureDROWNER);
    this.possible_compositions.PushBack(CreatureDROWNERDLC);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeSwamp).addLikedBiome(BiomeWater);
  }
  
}

class RER_BestiarySharley extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureSHARLEY;
    this.species = SpeciesTypes_RELICTS;
    this.menu_name = 'Shaelmaars';
    this.localized_name = 'option_rer_shaelmaar';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\sharley.w2ent", , , "dlc\bob\journal\bestiary\ep2sharley.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\sharley_mh.w2ent", , , "dlc\bob\journal\bestiary\ep2sharley.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\sharley_q701.w2ent", , , "dlc\bob\journal\bestiary\ep2sharley.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\sharley_q701_normal_scale.w2ent", , , "dlc\bob\journal\bestiary\ep2sharley.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_sharley_trophy_low');
    this.trophy_names.PushBack('modrer_sharley_trophy_medium');
    this.trophy_names.PushBack('modrer_sharley_trophy_high');
    this.ecosystem_delay_multiplier = 25;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).build();
    this.possible_compositions.PushBack(CreatureKIKIMORE);
    this.possible_compositions.PushBack(CreatureCENTIPEDE);
    this.possible_compositions.PushBack(CreatureSPIDER);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addDislikedBiome(BiomeSwamp).addDislikedBiome(BiomeWater);
  }
  
}

class RER_BestiarySiren extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureSIREN;
    this.species = SpeciesTypes_HYBRIDS;
    this.menu_name = 'Sirens';
    this.localized_name = 'option_rer_siren';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\siren_lvl1.w2ent", , , "gameplay\journal\bestiary\siren.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\siren_lvl2__lamia.w2ent", , , "gameplay\journal\bestiary\siren.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\siren_lvl3.w2ent", , , "gameplay\journal\bestiary\siren.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 4;
    this.template_list.difficulty_factor.maximum_count_medium = 5;
    this.template_list.difficulty_factor.minimum_count_hard = 5;
    this.template_list.difficulty_factor.maximum_count_hard = 7;
    this.trophy_names.PushBack('modrer_harpy_trophy_low');
    this.trophy_names.PushBack('modrer_harpy_trophy_medium');
    this.trophy_names.PushBack('modrer_harpy_trophy_high');
    this.ecosystem_delay_multiplier = 2.75;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addOnlyBiome(BiomeSwamp).addOnlyBiome(BiomeWater);
  }
  
}

class RER_BestiarySkelbear extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureSKELBEAR;
    this.species = SpeciesTypes_BEASTS;
    this.menu_name = 'Skellige_Bears';
    this.localized_name = 'option_rer_bear';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\bear_lvl3__white.w2ent", , , "gameplay\journal\bestiary\bear.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 2;
    this.trophy_names.PushBack('modrer_beast_trophy_low');
    this.trophy_names.PushBack('modrer_beast_trophy_medium');
    this.trophy_names.PushBack('modrer_beast_trophy_high');
    this.ecosystem_delay_multiplier = 3.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.high_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.high_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.self_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiarySkeleton extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureSKELETON;
    this.species = SpeciesTypes_CURSED;
    this.menu_name = 'Skeletons';
    this.localized_name = 'option_rer_skeleton';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\nightwraith_banshee_summon.w2ent", , , "dlc\bob\journal\bestiary\beanshie.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\nightwraith_banshee_summon_skeleton.w2ent", , , "dlc\bob\journal\bestiary\beanshie.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 2;
    this.template_list.difficulty_factor.maximum_count_easy = 3;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 4;
    this.template_list.difficulty_factor.minimum_count_hard = 4;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.trophy_names.PushBack('modrer_spirit_trophy_low');
    this.trophy_names.PushBack('modrer_spirit_trophy_medium');
    this.trophy_names.PushBack('modrer_spirit_trophy_high');
    this.ecosystem_delay_multiplier = 2;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiarySkeltroll extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureSKELTROLL;
    this.species = SpeciesTypes_OGROIDS;
    this.menu_name = 'Skellige_Trolls';
    this.localized_name = 'option_rer_troll';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\troll_cave_lvl3__ice.w2ent", , , "gameplay\journal\bestiary\icetroll.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\troll_cave_lvl4__ice.w2ent", , , "gameplay\journal\bestiary\icetroll.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\troll_ice_lvl13.w2ent", , , "gameplay\journal\bestiary\icetroll.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 3;
    this.trophy_names.PushBack('modrer_troll_trophy_low');
    this.trophy_names.PushBack('modrer_troll_trophy_medium');
    this.trophy_names.PushBack('modrer_troll_trophy_high');
    this.ecosystem_delay_multiplier = 5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiarySkelwolf extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureSKELWOLF;
    this.species = SpeciesTypes_BEASTS;
    this.menu_name = 'Skellige_Wolves';
    this.localized_name = 'option_rer_wolf';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\wolf_white_lvl2.w2ent", , , "gameplay\journal\bestiary\wolf.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\wolf_white_lvl3__alpha.w2ent", 1, , "gameplay\journal\bestiary\wolf.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 2;
    this.template_list.difficulty_factor.maximum_count_easy = 3;
    this.template_list.difficulty_factor.minimum_count_medium = 2;
    this.template_list.difficulty_factor.maximum_count_medium = 4;
    this.template_list.difficulty_factor.minimum_count_hard = 3;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.trophy_names.PushBack('modrer_beast_trophy_low');
    this.trophy_names.PushBack('modrer_beast_trophy_medium');
    this.trophy_names.PushBack('modrer_beast_trophy_high');
    this.ecosystem_delay_multiplier = 2.25;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.high_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.high_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.self_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiarySpider extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    var is_arachnophobia_mode_enabled: bool;
    influences = RER_ConstantInfluences();
    this.type = CreatureSPIDER;
    this.species = SpeciesTypes_INSECTOIDS;
    this.menu_name = 'Spiders';
    this.localized_name = 'option_rer_spider';
    is_arachnophobia_mode_enabled = theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERarachnophobiaMode');
    if (is_arachnophobia_mode_enabled) {
      this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nekker_lvl1.w2ent", , , "gameplay\journal\bestiary\nekker.journal"));
      this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nekker_lvl2.w2ent", , , "gameplay\journal\bestiary\nekker.journal"));
      this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nekker_lvl2_customize.w2ent", , , "gameplay\journal\bestiary\nekker.journal"));
      this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nekker_lvl3_customize.w2ent", , , "gameplay\journal\bestiary\nekker.journal"));
      this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nekker_lvl3__warrior.w2ent", 2, , "gameplay\journal\bestiary\nekker.journal"));
      this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\nekker_mh__warrior.w2ent", 1, , "gameplay\journal\bestiary\bestiarymonsterhuntmh202.journal"));
    }
    else  {
      this.template_list.templates.PushBack(makeEnemyTemplate("dlc\ep1\data\characters\npc_entities\monsters\black_spider.w2ent", , , "gameplay\journal\bestiary\bestiarycrabspider.journal"));
      
      this.template_list.templates.PushBack(makeEnemyTemplate("dlc\ep1\data\characters\npc_entities\monsters\black_spider_large.w2ent", 2, , "gameplay\journal\bestiary\bestiarycrabspider.journal"));
      
    }
    
    this.template_list.difficulty_factor.minimum_count_easy = 2;
    this.template_list.difficulty_factor.maximum_count_easy = 3;
    this.template_list.difficulty_factor.minimum_count_medium = 2;
    this.template_list.difficulty_factor.maximum_count_medium = 3;
    this.template_list.difficulty_factor.minimum_count_hard = 3;
    this.template_list.difficulty_factor.maximum_count_hard = 4;
    this.trophy_names.PushBack('modrer_insectoid_trophy_low');
    this.trophy_names.PushBack('modrer_insectoid_trophy_medium');
    this.trophy_names.PushBack('modrer_insectoid_trophy_high');
    this.ecosystem_delay_multiplier = 4;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.low_indirect_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.friend_with).influence(influences.kills_them).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.kills_them).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.kills_them).influence(influences.low_indirect_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addDislikedBiome(BiomeSwamp).addDislikedBiome(BiomeWater).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryTroll extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureTROLL;
    this.species = SpeciesTypes_OGROIDS;
    this.menu_name = 'Trolls';
    this.localized_name = 'option_rer_troll';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\troll_cave_lvl1.w2ent", , , "gameplay\journal\bestiary\trollcave.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 3;
    this.trophy_names.PushBack('modrer_troll_trophy_low');
    this.trophy_names.PushBack('modrer_troll_trophy_medium');
    this.trophy_names.PushBack('modrer_troll_trophy_high');
    this.ecosystem_delay_multiplier = 5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).build();
    this.possible_compositions.PushBack(CreatureNEKKER);
    this.possible_compositions.PushBack(CreatureTROLL);
    this.possible_compositions.PushBack(CreatureSKELTROLL);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryWerewolf extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureWEREWOLF;
    this.species = SpeciesTypes_CURSED;
    this.menu_name = 'Werewolves';
    this.localized_name = 'option_rer_werewolf';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\werewolf_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiarywerewolf.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\werewolf_lvl2.w2ent", , , "gameplay\journal\bestiary\bestiarywerewolf.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\werewolf_lvl3__lycan.w2ent", , , "gameplay\journal\bestiary\lycanthrope.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\werewolf_lvl4__lycan.w2ent", , , "gameplay\journal\bestiary\lycanthrope.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\werewolf_lvl5__lycan.w2ent", , , "gameplay\journal\bestiary\lycanthrope.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\_quest__werewolf.w2ent", , , "gameplay\journal\bestiary\bestiarywerewolf.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\_quest__werewolf_01.w2ent", , , "gameplay\journal\bestiary\bestiarywerewolf.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\_quest__werewolf_02.w2ent", , , "gameplay\journal\bestiary\bestiarywerewolf.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_werewolf_trophy_low');
    this.trophy_names.PushBack('modrer_werewolf_trophy_medium');
    this.trophy_names.PushBack('modrer_werewolf_trophy_high');
    this.ecosystem_delay_multiplier = 10;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureWOLF);
    this.possible_compositions.PushBack(CreatureSKELWOLF);
    this.possible_compositions.PushBack(CreatureBERSERKER);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryWight extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureWIGHT;
    this.species = SpeciesTypes_CURSED;
    this.menu_name = 'Wights';
    this.localized_name = 'option_rer_wight';
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\spooncollector.w2ent", 1, , "dlc\bob\journal\bestiary\wicht.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("dlc\bob\data\characters\npc_entities\monsters\wicht.w2ent", 2, , "dlc\bob\journal\bestiary\wicht.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_wight_trophy_low');
    this.trophy_names.PushBack('modrer_wight_trophy_medium');
    this.trophy_names.PushBack('modrer_wight_trophy_high');
    this.ecosystem_delay_multiplier = 5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.low_bad_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureBARGHEST);
    this.possible_compositions.PushBack(CreatureWRAITH);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeSwamp).addLikedBiome(BiomeWater).addDislikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryWildhunt extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureWILDHUNT;
    this.species = SpeciesTypes_ELEMENTA;
    this.menu_name = 'Wild_Hunt';
    this.localized_name = 'option_rer_wildhunt';
    this.template_list.templates.PushBack(makeEnemyTemplate("quests\part_2\quest_files\q403_battle\characters\q403_wild_hunt_2h_axe.w2ent", , , "gameplay\journal\bestiary\whminion.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("quests\part_2\quest_files\q403_battle\characters\q403_wild_hunt_2h_halberd.w2ent", 2, , "gameplay\journal\bestiary\whminion.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("quests\part_2\quest_files\q403_battle\characters\q403_wild_hunt_2h_hammer.w2ent", 1, , "gameplay\journal\bestiary\whminion.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("quests\part_2\quest_files\q403_battle\characters\q403_wild_hunt_2h_spear.w2ent", 2, , "gameplay\journal\bestiary\whminion.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("quests\part_2\quest_files\q403_battle\characters\q403_wild_hunt_2h_sword.w2ent", 1, , "gameplay\journal\bestiary\whminion.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\wildhunt_minion_lvl1.w2ent", , , "gameplay\journal\bestiary\whminion.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\wildhunt_minion_lvl2.w2ent", 1, , "gameplay\journal\bestiary\whminion.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 4;
    this.template_list.difficulty_factor.maximum_count_medium = 6;
    this.template_list.difficulty_factor.minimum_count_hard = 5;
    this.template_list.difficulty_factor.maximum_count_hard = 7;
    this.trophy_names.PushBack('modrer_wildhunt_trophy_low');
    this.trophy_names.PushBack('modrer_wildhunt_trophy_medium');
    this.trophy_names.PushBack('modrer_wildhunt_trophy_high');
    this.ecosystem_delay_multiplier = 6;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
    this.possible_compositions.PushBack(CreatureHUMAN);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryWolf extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureWOLF;
    this.species = SpeciesTypes_BEASTS;
    this.menu_name = 'Wolves';
    this.localized_name = 'option_rer_wolf';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\wolf_lvl1.w2ent", , , "gameplay\journal\bestiary\wolf.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\wolf_lvl1__alpha.w2ent", 1, , "gameplay\journal\bestiary\wolf.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 2;
    this.template_list.difficulty_factor.maximum_count_easy = 3;
    this.template_list.difficulty_factor.minimum_count_medium = 2;
    this.template_list.difficulty_factor.maximum_count_medium = 4;
    this.template_list.difficulty_factor.minimum_count_hard = 3;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.trophy_names.PushBack('modrer_beast_trophy_low');
    this.trophy_names.PushBack('modrer_beast_trophy_medium');
    this.trophy_names.PushBack('modrer_beast_trophy_high');
    this.ecosystem_delay_multiplier = 2.25;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.high_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.high_indirect_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.self_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.low_bad_influence).influence(influences.friend_with).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_bad_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.friend_with).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type).addLikedBiome(BiomeForest);
  }
  
}

class RER_BestiaryWraith extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureWRAITH;
    this.species = SpeciesTypes_SPECTERS;
    this.menu_name = 'Wraiths';
    this.localized_name = 'option_rer_wraith';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\wraith_lvl1.w2ent", , , "gameplay\journal\bestiary\wraith.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\wraith_lvl2.w2ent", , , "gameplay\journal\bestiary\wraith.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\wraith_lvl2_customize.w2ent", , , "gameplay\journal\bestiary\wraith.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\wraith_lvl3.w2ent", , , "gameplay\journal\bestiary\wraith.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\wraith_lvl4.w2ent", 2, , "gameplay\journal\bestiary\wraith.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 2;
    this.template_list.difficulty_factor.minimum_count_medium = 2;
    this.template_list.difficulty_factor.maximum_count_medium = 3;
    this.template_list.difficulty_factor.minimum_count_hard = 3;
    this.template_list.difficulty_factor.maximum_count_hard = 4;
    this.trophy_names.PushBack('modrer_wraith_trophy_low');
    this.trophy_names.PushBack('modrer_wraith_trophy_medium');
    this.trophy_names.PushBack('modrer_wraith_trophy_high');
    this.ecosystem_delay_multiplier = 2.75;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.self_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).build();
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryWyvern extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureWYVERN;
    this.species = SpeciesTypes_DRACONIDS;
    this.menu_name = 'Wyverns';
    this.localized_name = 'option_rer_wyvern';
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\wyvern_lvl1.w2ent", , , "gameplay\journal\bestiary\bestiarywyvern.journal"));
    this.template_list.templates.PushBack(makeEnemyTemplate("characters\npc_entities\monsters\wyvern_lvl2.w2ent", , , "gameplay\journal\bestiary\bestiarywyvern.journal"));
    this.template_list.difficulty_factor.minimum_count_easy = 1;
    this.template_list.difficulty_factor.maximum_count_easy = 1;
    this.template_list.difficulty_factor.minimum_count_medium = 1;
    this.template_list.difficulty_factor.maximum_count_medium = 1;
    this.template_list.difficulty_factor.minimum_count_hard = 1;
    this.template_list.difficulty_factor.maximum_count_hard = 1;
    this.trophy_names.PushBack('modrer_wyvern_trophy_low');
    this.trophy_names.PushBack('modrer_wyvern_trophy_medium');
    this.trophy_names.PushBack('modrer_wyvern_trophy_high');
    this.ecosystem_delay_multiplier = 7.5;
    this.ecosystem_impact = (new EcosystemCreatureImpactBuilder in thePlayer).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.low_indirect_influence).influence(influences.low_indirect_influence).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.kills_them).influence(influences.low_indirect_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.kills_them).influence(influences.kills_them).influence(influences.no_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.high_indirect_influence).influence(influences.friend_with).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.no_influence).influence(influences.friend_with).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.no_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.high_indirect_influence).influence(influences.self_influence).influence(influences.friend_with).influence(influences.friend_with).build();
    this.possible_compositions.PushBack(CreatureFORKTAIL);
    this.possible_compositions.PushBack(CreatureWYVERN);
    this.possible_compositions.PushBack(CreatureHARPY);
    this.possible_compositions.PushBack(CreatureSIREN);
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryHumanBandit extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureHUMAN;
    this.menu_name = 'Humans';
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nml_deserters_axe_normal.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nml_deserters_bow.w2ent", 3));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nml_deserters_sword_easy.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\novigrad_bandit_shield_1haxe.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\novigrad_bandit_shield_1hclub.w2ent"));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 5;
    this.template_list.difficulty_factor.minimum_count_hard = 4;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.ecosystem_delay_multiplier = 2.5;
    this.trophy_names.PushBack('modrer_human_trophy_low');
    this.trophy_names.PushBack('modrer_human_trophy_medium');
    this.trophy_names.PushBack('modrer_human_trophy_high');
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryHumanCannibal extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureHUMAN;
    this.menu_name = 'Humans';
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\lw_giggler_boss.w2ent", 1));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\lw_giggler_melee.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\lw_giggler_melee_spear.w2ent", 3));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\lw_giggler_ranged.w2ent", 3));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 5;
    this.template_list.difficulty_factor.minimum_count_hard = 4;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.ecosystem_delay_multiplier = 2.5;
    this.trophy_names.PushBack('modrer_human_trophy_low');
    this.trophy_names.PushBack('modrer_human_trophy_medium');
    this.trophy_names.PushBack('modrer_human_trophy_high');
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryHumanNilf extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureHUMAN;
    this.menu_name = 'Humans';
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nilfgaardian_deserter_bow.w2ent", 3));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nilfgaardian_deserter_shield.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nilfgaardian_deserter_sword_hard.w2ent"));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 5;
    this.template_list.difficulty_factor.minimum_count_hard = 4;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.ecosystem_delay_multiplier = 2.5;
    this.trophy_names.PushBack('modrer_human_trophy_low');
    this.trophy_names.PushBack('modrer_human_trophy_medium');
    this.trophy_names.PushBack('modrer_human_trophy_high');
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryHumanNovbandit extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureHUMAN;
    this.menu_name = 'Humans';
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\novigrad\nov_1h_club.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\novigrad\nov_1h_mace_t1.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\novigrad\nov_2h_hammer.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\novigrad\nov_1h_sword_t1.w2ent"));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 5;
    this.template_list.difficulty_factor.minimum_count_hard = 4;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.ecosystem_delay_multiplier = 2.5;
    this.trophy_names.PushBack('modrer_human_trophy_low');
    this.trophy_names.PushBack('modrer_human_trophy_medium');
    this.trophy_names.PushBack('modrer_human_trophy_high');
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryHumanPirate extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureHUMAN;
    this.menu_name = 'Humans';
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nml_pirates_axe_normal.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nml_pirates_blunt.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nml_pirates_bow.w2ent", 2));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nml_pirates_crossbow.w2ent", 1));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nml_pirates_sword_easy.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nml_pirates_sword_hard.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\nml_pirates_sword_normal.w2ent"));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 5;
    this.template_list.difficulty_factor.minimum_count_hard = 4;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.ecosystem_delay_multiplier = 2.5;
    this.trophy_names.PushBack('modrer_human_trophy_low');
    this.trophy_names.PushBack('modrer_human_trophy_medium');
    this.trophy_names.PushBack('modrer_human_trophy_high');
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryHumanRenegade extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureHUMAN;
    this.menu_name = 'Humans';
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\baron_renegade_2h_axe.w2ent", 2));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\baron_renegade_axe.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\baron_renegade_blunt.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\baron_renegade_boss.w2ent", 1));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\baron_renegade_bow.w2ent", 2));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\baron_renegade_crossbow.w2ent", 1));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\baron_renegade_shield.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\baron_renegade_sword_hard.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\baron_renegade_sword_normal.w2ent"));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 5;
    this.template_list.difficulty_factor.minimum_count_hard = 4;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.ecosystem_delay_multiplier = 2.5;
    this.trophy_names.PushBack('modrer_human_trophy_low');
    this.trophy_names.PushBack('modrer_human_trophy_medium');
    this.trophy_names.PushBack('modrer_human_trophy_high');
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryHumanSkel2bandit extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureHUMAN;
    this.menu_name = 'Humans';
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_bandit_axe1h_normal.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_bandit_axe1h_hard.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_bandit_blunt_normal.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_bandit_blunt_hard.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_bandit_shield_axe1h_normal.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_bandit_shield_mace1h_normal.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_bandit_axe2h.w2ent", 2));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_bandit_sword_easy.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_bandit_sword_hard.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_bandit_sword_normal.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_bandit_hammer2h.w2ent", 1));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_bandit_bow.w2ent", 2));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_bandit_crossbow.w2ent", 1));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 5;
    this.template_list.difficulty_factor.minimum_count_hard = 4;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.ecosystem_delay_multiplier = 2.5;
    this.trophy_names.PushBack('modrer_human_trophy_low');
    this.trophy_names.PushBack('modrer_human_trophy_medium');
    this.trophy_names.PushBack('modrer_human_trophy_high');
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryHumanSkelbandit extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureHUMAN;
    this.menu_name = 'Humans';
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\skellige\ske_1h_axe_t1.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\skellige\ske_1h_club.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\skellige\ske_bow.w2ent", 3));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\skellige\ske_2h_spear.w2ent", 3));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\skellige\ske_shield_axe_t1.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\skellige\ske_shield_club.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\skellige\ske_1h_axe_t2.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\skellige\ske_1h_sword.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\skellige\ske_shield_axe_t2.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\skellige\ske_shield_sword.w2ent"));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 5;
    this.template_list.difficulty_factor.minimum_count_hard = 4;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.ecosystem_delay_multiplier = 2.5;
    this.trophy_names.PushBack('modrer_human_trophy_low');
    this.trophy_names.PushBack('modrer_human_trophy_medium');
    this.trophy_names.PushBack('modrer_human_trophy_high');
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryHumanSkelpirate extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureHUMAN;
    this.menu_name = 'Humans';
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_pirate_axe1h_hard.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_pirate_axe1h_normal.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_pirate_axe2h.w2ent", 2));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_pirate_blunt_hard.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_pirate_blunt_normal.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_pirate_bow.w2ent", 2));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_pirate_crossbow.w2ent", 1));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_pirate_hammer2h.w2ent", 1));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_pirate_swordshield.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_pirate_sword_easy.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_pirate_sword_hard.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("living_world\enemy_templates\skellige_pirate_sword_normal.w2ent"));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 5;
    this.template_list.difficulty_factor.minimum_count_hard = 4;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.ecosystem_delay_multiplier = 2.5;
    this.trophy_names.PushBack('modrer_human_trophy_low');
    this.trophy_names.PushBack('modrer_human_trophy_medium');
    this.trophy_names.PushBack('modrer_human_trophy_high');
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

class RER_BestiaryHumanWhunter extends RER_BestiaryEntry {
  public function init() {
    var influences: RER_ConstantInfluences;
    influences = RER_ConstantInfluences();
    this.type = CreatureHUMAN;
    this.menu_name = 'Humans';
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\inquisition\inq_1h_sword_t2.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\inquisition\inq_1h_mace_t2.w2ent"));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\inquisition\inq_crossbow.w2ent", 2));
    this.template_list.templates.PushBack(makeEnemyTemplate("gameplay\templates\characters\presets\inquisition\inq_2h_sword.w2ent"));
    this.template_list.difficulty_factor.minimum_count_easy = 3;
    this.template_list.difficulty_factor.maximum_count_easy = 4;
    this.template_list.difficulty_factor.minimum_count_medium = 3;
    this.template_list.difficulty_factor.maximum_count_medium = 5;
    this.template_list.difficulty_factor.minimum_count_hard = 4;
    this.template_list.difficulty_factor.maximum_count_hard = 6;
    this.ecosystem_delay_multiplier = 2.5;
    this.trophy_names.PushBack('modrer_human_trophy_low');
    this.trophy_names.PushBack('modrer_human_trophy_medium');
    this.trophy_names.PushBack('modrer_human_trophy_high');
  }
  
  public function setCreaturePreferences(preferences: RER_CreaturePreferences, encounter_type: EncounterType): RER_CreaturePreferences {
    return super.setCreaturePreferences(preferences, encounter_type);
  }
  
}

statemachine class RER_BountyManager extends CEntity {
  var master: CRandomEncounters;
  
  var bounty_master_manager: RER_BountyMasterManager;
  
  var oneliner: RER_Oneliner;
  
  public function init(master: CRandomEncounters) {
    this.master = master;
    this.bounty_master_manager = new RER_BountyMasterManager in this;
    this.GotoState('Initialising');
  }
  
  public function getSeedDifficultyStep(): int {
    return 1000;
  }
  
  public function getDifficultyForSeed(seed: int): int {
    if (seed==0) {
      return getRandomLevelBasedOnSettings(this.master.settings);
    }
    
    return (int)((seed/this.getSeedDifficultyStep()));
  }
  
  public function getSeedBountyLevelStep(): int {
    return 500;
  }
  
  public function getMaximumSeed(): int {
    return this.getTotalBountyLevel()*this.getSeedBountyLevelStep();
  }
  
  private latent function getNewBounty(seed: int): RER_Bounty {
    var bounty: RER_Bounty;
    bounty = RER_Bounty();
    bounty.seed = seed;
    bounty.is_active = true;
    bounty.random_data = this.generateRandomDataForBounty(seed);
    bounty.region_name = SUH_getCurrentRegion();
    return bounty;
  }
  
  public latent function getBountyBestiaryEntry(rng: RandomNumberGenerator, seed: int): RER_BestiaryEntry {
    var constants: RER_ConstantCreatureTypes;
    var output: RER_BestiaryEntry;
    var creature_type: CreatureType;
    constants = RER_ConstantCreatureTypes();
    if (seed==0) {
      output = this.master.bestiary.getRandomEntryFromBestiary(this.master, EncounterType_CONTRACT, RER_BREF_IGNORE_BIOMES|RER_BREF_IGNORE_SETTLEMENT|RER_BREF_IGNORE_BESTIARY, (new RER_SpawnRollerFilter in this).init().multiplyEveryone(100).setOffsets(constants.large_creature_begin, constants.large_creature_max, 0.01));
      return output;
    }
    
    creature_type = (int)((rng.next()*((int)(CreatureMAX))));
    output = this.master.bestiary.getEntry(this.master, creature_type);
    return output;
  }
  
  private latent function generateRandomDataForBounty(seed: int): RER_BountyRandomData {
    var current_group_data: RER_BountyRandomMonsterGroupData;
    var point_of_interests_positions: array<Vector>;
    var current_bestiary_entry: RER_BestiaryEntry;
    var main_bestiary_entry: RER_BestiaryEntry;
    var creature_type: CreatureType;
    var rng: RandomNumberGenerator;
    var data: RER_BountyRandomData;
    var number_of_groups: int;
    var constants: RER_ConstantCreatureTypes;
    var i: int;
    var k: int;
    constants = RER_ConstantCreatureTypes();
    rng = (new RandomNumberGenerator in this).setSeed(seed).useSeed(seed!=0);
    main_bestiary_entry = this.getBountyBestiaryEntry(rng, seed);
    data = RER_BountyRandomData();
    number_of_groups = this.getNumberOfGroupsForSeed(rng, seed);
    NLOG("generateRandomDataForBounty(), number of groups = "+number_of_groups);
    point_of_interests_positions = RER_getClosestDestinationPoints(thePlayer.GetWorldPosition(), 5000);
    current_group_data = RER_BountyRandomMonsterGroupData();
    current_group_data.type = main_bestiary_entry.type;
    current_group_data.count = Max(1, rollDifficultyFactorWithRng(main_bestiary_entry.template_list.difficulty_factor, this.master.settings.selectedDifficulty, this.master.settings.enemy_count_multiplier*main_bestiary_entry.creature_type_multiplier*(1+this.getDifficultyForSeed(seed)*0.01), rng));
    k = (int)(rng.nextRange(point_of_interests_positions.Size(), 0));
    current_group_data.position = point_of_interests_positions[k];
    point_of_interests_positions.EraseFast(k);
    data.main_group = current_group_data;
    for (i = 0; i<number_of_groups; i += 1) {
      current_group_data = RER_BountyRandomMonsterGroupData();
      
      if (seed==0) {
        creature_type = main_bestiary_entry.getRandomCompositionCreature(this.master, EncounterType_CONTRACT, (new RER_SpawnRollerFilter in this).init().multiplyEveryone(100).setOffsets(constants.small_creature_begin_no_humans, constants.small_creature_max, 0.01), RER_flag(RER_BREF_IGNORE_BESTIARY, true));
        current_bestiary_entry = this.master.bestiary.getEntry(this.master, creature_type);
        current_group_data.type = current_bestiary_entry.type;
      }
      else  {
        current_group_data.type = (int)((rng.next()*((int)(CreatureMAX))));
        
        current_bestiary_entry = this.master.bestiary.getEntry(this.master, current_group_data.type);
        
      }
      
      
      if (current_bestiary_entry.isNull()) {
        continue;
      }
      
      
      current_group_data.count = Max(1, rollDifficultyFactorWithRng(current_bestiary_entry.template_list.difficulty_factor, this.master.settings.selectedDifficulty, this.master.settings.enemy_count_multiplier*current_bestiary_entry.creature_type_multiplier*(1+this.getDifficultyForSeed(seed)*0.01), rng));
      
      k = (int)(rng.nextRange(point_of_interests_positions.Size(), 0));
      
      current_group_data.position = point_of_interests_positions[k];
      
      point_of_interests_positions.EraseFast(k);
      
      data.side_groups.PushBack(current_group_data);
    }
    
    return data;
  }
  
  public latent function startBounty(seed: int) {
    this.master.storages.bounty.current_bounty = this.getNewBounty(seed);
    this.master.storages.bounty.save();
    theSound.SoundEvent("gui_ingame_quest_active");
    Sleep(0.2);
    RER_tutorialTryShowBounty();
    Sleep(0.5);
    RER_openPopup(GetLocStringByKey("rer_bounty_start_popup_title"), this.getInformationMessageAboutCurrentBounty());
    this.displayMarkersForCurrentBounty();
    this.displayOnelinersForCurrentBounty();
  }
  
  public function endBounty() {
    var message: string;
    var new_level: int;
    var bonus: int;
    bonus = this.getNumberOfSideGroupsKilled();
    new_level = this.increaseBountyLevel();
    if (bonus>0) {
      RER_giveItemForLevelUnknown(this.master, thePlayer.GetInventory(), new_level*bonus);
    }
    
    this.abandonBounty();
    message = GetLocStringByKey("rer_bounty_finished_notification");
    message = StrReplace(message, "{{side_groups_killed}}", RER_yellowFont(bonus));
    message = StrReplace(message, "{{bounty_level}}", RER_yellowFont(new_level));
    NDEBUG(message);
    theSound.SoundEvent("gui_inventory_buy");
  }
  
  public function abandonBounty() {
    this.master.storages.bounty.current_bounty.is_active = false;
    this.master.storages.bounty.save();
    this.removeMarkersForCurrentBounty();
    this.displayOnelinersForCurrentBounty();
  }
  
  public function displayOnelinersForCurrentBounty() {
    if (this.oneliner) {
      this.oneliner.unregister();
      delete this.oneliner;
    }
    
    if (!isBountyActive()) {
      return ;
    }
    
    if (!theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERonelinersBountyMainTarget')) {
      return ;
    }
    
    this.oneliner = RER_oneliner(" <img src='img://icons/quests/monsterhunt.png' vspace='-10' />", this.master.storages.bounty.current_bounty.random_data.main_group.position);
  }
  
  public function removeMarkersForCurrentBounty() {
    SU_removeCustomPinByTag("RER_bounty_target");
    SU_removeCustomPinByTag("RER_bounty_target_main");
  }
  
  public function displayMarkersForCurrentBounty() {
    var map_pin: SU_MapPin;
    var i: int;
    this.removeMarkersForCurrentBounty();
    if (!isBountyActive()) {
      return ;
    }
    
    if (!theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERmarkersBountyHunting')) {
      return ;
    }
    
    map_pin = new SU_MapPin in this;
    map_pin.tag = "RER_bounty_target_main";
    map_pin.pin_tag = 'RER_bounty_target_main';
    map_pin.is_fast_travel = true;
    map_pin.position = this.master.storages.bounty.current_bounty.random_data.main_group.position;
    map_pin.description = StrReplace(GetLocStringByKey("rer_mappin_bounty_main_target_description"), "{{creature_type}}", getCreatureNameFromCreatureType(this.master.bestiary, this.master.storages.bounty.current_bounty.random_data.main_group.type));
    map_pin.label = GetLocStringByKey("rer_mappin_bounty_main_target_title");
    map_pin.type = "MonsterQuest";
    map_pin.filtered_type = "MonsterQuest";
    map_pin.radius = 100;
    map_pin.region = SUH_getCurrentRegion();
    map_pin.appears_on_minimap = theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERminimapMarkerBounties');
    SUMP_addCustomPin(map_pin);
    for (i = 0; i<this.master.storages.bounty.current_bounty.random_data.side_groups.Size(); i += 1) {
      if (this.master.storages.bounty.current_bounty.random_data.side_groups[i].was_killed) {
        continue;
      }
      
      
      map_pin = new SU_MapPin in this;
      
      map_pin.tag = "RER_bounty_target";
      
      map_pin.pin_tag = this.getPinTagForIndex(i);
      
      map_pin.is_fast_travel = true;
      
      map_pin.position = this.master.storages.bounty.current_bounty.random_data.side_groups[i].position;
      
      map_pin.description = StrReplace(GetLocStringByKey("rer_mappin_bounty_side_target_description"), "{{creature_type}}", getCreatureNameFromCreatureType(this.master.bestiary, this.master.storages.bounty.current_bounty.random_data.side_groups[i].type));
      
      map_pin.label = GetLocStringByKey("rer_mappin_bounty_side_target_title");
      
      map_pin.type = "MonsterQuest";
      
      map_pin.filtered_type = "MonsterQuest";
      
      map_pin.radius = 50;
      
      map_pin.region = SUH_getCurrentRegion();
      
      map_pin.appears_on_minimap = theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERminimapMarkerBounties');
      
      SUMP_addCustomPin(map_pin);
    }
    
    SU_updateMinimapPins();
  }
  
  private function getPinTagForIndex(index: int): name {
    var tag: name;
    tag = 'RER_bounty_side_target';
    switch (index) {
      case 0:
      tag = 'RER_bounty_side_target_0';
      break;
      
      case 1:
      tag = 'RER_bounty_side_target_1';
      break;
      
      case 2:
      tag = 'RER_bounty_side_target_2';
      break;
      
      case 3:
      tag = 'RER_bounty_side_target_3';
      break;
      
      case 4:
      tag = 'RER_bounty_side_target_4';
      break;
      
      case 5:
      tag = 'RER_bounty_side_target_5';
      break;
      
      case 6:
      tag = 'RER_bounty_side_target_6';
      break;
      
      case 7:
      tag = 'RER_bounty_side_target_7';
      break;
      
      case 8:
      tag = 'RER_bounty_side_target_8';
      break;
      
      case 9:
      tag = 'RER_bounty_side_target_9';
      break;
      
      case 10:
      tag = 'RER_bounty_side_target_10';
      break;
      
      case 11:
      tag = 'RER_bounty_side_target_11';
      break;
      
      case 12:
      tag = 'RER_bounty_side_target_12';
      break;
      
      case 13:
      tag = 'RER_bounty_side_target_13';
      break;
      
      case 14:
      tag = 'RER_bounty_side_target_14';
      break;
      
      case 15:
      tag = 'RER_bounty_side_target_15';
      break;
      
      case 16:
      tag = 'RER_bounty_side_target_16';
      break;
      
      case 17:
      tag = 'RER_bounty_side_target_17';
      break;
      
      case 18:
      tag = 'RER_bounty_side_target_18';
      break;
      
      case 19:
      tag = 'RER_bounty_side_target_19';
      break;
      
      case 20:
      tag = 'RER_bounty_side_target_20';
      break;
      
      case 21:
      tag = 'RER_bounty_side_target_21';
      break;
      
      case 22:
      tag = 'RER_bounty_side_target_22';
      break;
      
      case 23:
      tag = 'RER_bounty_side_target_23';
      break;
    }
    return tag;
  }
  
  public function isBountyActive(): bool {
    return this.master.storages.bounty.current_bounty.is_active;
  }
  
  public function isMainGroupDead(): bool {
    if (!this.isBountyActive()) {
      NDEBUG("RER warning: isMainGroupDead() was called but no active bounty was found.");
      return false;
    }
    
    return this.master.storages.bounty.current_bounty.random_data.main_group.was_killed;
  }
  
  public function getNumberOfSideGroupsKilled(): int {
    var count: int;
    var i: int;
    if (!this.isBountyActive()) {
      NDEBUG("RER warning: getNumberOfSideGroupsKilled() was called but no active bounty was found.");
      return 0;
    }
    
    count = 0;
    for (i = 0; i<this.master.storages.bounty.current_bounty.random_data.side_groups.Size(); i += 1) {
      count += (int)(this.master.storages.bounty.current_bounty.random_data.side_groups[i].was_killed);
    }
    
    return count;
  }
  
  public function resetBountyLevel() {
    this.setCurrentRegionBountyLevel(0);
    this.master.storages.bounty.save();
  }
  
  public function notifyMainGroupKilled() {
    if (!this.isBountyActive()) {
      NDEBUG("RER warning: notifyMainGroupKilled() was called but no active bounty was found.");
    }
    
    this.endBounty();
  }
  
  public function notifySideGroupKilled(index: int) {
    if (!this.isBountyActive()) {
      NDEBUG("RER warning: notifySideGroupKilled("+index+") was called but no active bounty was found.");
      return ;
    }
    
    if (index>=this.master.storages.bounty.current_bounty.random_data.side_groups.Size()) {
      NDEBUG("RER warning: out of bound index, notifySideGroupKilled("+index+") but there are only "+this.master.storages.bounty.current_bounty.random_data.side_groups.Size()+" side groups");
      return ;
    }
    
    this.master.storages.bounty.current_bounty.random_data.side_groups[index].was_killed = true;
    this.master.storages.bounty.save();
    this.displayMarkersForCurrentBounty();
    this.displayOnelinersForCurrentBounty();
    thePlayer.DisplayHudMessage(GetLocStringByKeyExt("rer_bounty_side_target_killed"));
  }
  
  public function getInformationMessageAboutCurrentBounty(): string {
    var group: RER_BountyRandomMonsterGroupData;
    var segment: string;
    var message: string;
    var i: int;
    if (!this.isBountyActive()) {
      NDEBUG("RER warning: getInformationMessageAboutCurrentBounty() was called but no active bounty was found");
      return "";
    }
    
    message = GetLocStringByKey("rer_bounty_start_popup");
    message = StrReplace(message, "{{main_creature_listing}}", " - "+getCreatureNameFromCreatureType(this.master.bestiary, this.master.storages.bounty.current_bounty.random_data.main_group.type));
    for (i = 0; i<this.master.storages.bounty.current_bounty.random_data.side_groups.Size(); i += 1) {
      group = this.master.storages.bounty.current_bounty.random_data.side_groups[i];
      
      segment += " - "+getCreatureNameFromCreatureType(this.master.bestiary, group.type)+"<br />";
    }
    
    message = StrReplace(message, "{{side_creature_listing}}", segment);
    return message;
  }
  
  public function getNumberOfGroupsForSeed(rng: RandomNumberGenerator, seed: int): int {
    var min: int;
    var max: int;
    min = 1;
    max = 2+((int)(this.getDifficultyForSeed(seed)*0.1))+min;
    NLOG("getNumberOfGroupsForSeed("+seed+") - "+RandNoiseF(seed, max, min)+" "+max);
    return (int)(rng.nextRange(max, min));
  }
  
  function getCurrentRegionBountyLevel(): int {
    var region: string;
    var output: int;
    region = SUH_getCurrentRegion();
    switch (region) {
      case "no_mans_land":
      output = this.master.storages.bounty.velen_level;
      break;
      
      case "skellige":
      output = this.master.storages.bounty.skellige_level;
      break;
      
      case "bob":
      output = this.master.storages.bounty.toussaint_level;
      break;
      
      case "prolog_village":
      output = this.master.storages.bounty.whiteorchard_level;
      break;
      
      case "kaer_morhen":
      output = this.master.storages.bounty.kaermorhen_level;
      break;
      
      default:
      output = this.master.storages.bounty.unknown_level;
      break;
    }
    return output;
  }
  
  function getTotalBountyLevel(): int {
    return this.master.storages.bounty.velen_level+this.master.storages.bounty.skellige_level+this.master.storages.bounty.toussaint_level+this.master.storages.bounty.whiteorchard_level+this.master.storages.bounty.kaermorhen_level+this.master.storages.bounty.unknown_level;
  }
  
  function setCurrentRegionBountyLevel(level: int) {
    var region: string;
    region = SUH_getCurrentRegion();
    switch (region) {
      case "no_mans_land":
      this.master.storages.bounty.velen_level = level;
      break;
      
      case "skellige":
      this.master.storages.bounty.skellige_level = level;
      break;
      
      case "bob":
      this.master.storages.bounty.toussaint_level = level;
      break;
      
      case "prolog_village":
      this.master.storages.bounty.whiteorchard_level = level;
      break;
      
      case "kaer_morhen":
      this.master.storages.bounty.kaermorhen_level = level;
      break;
      
      default:
      this.master.storages.bounty.unknown_level = level;
      break;
    }
  }
  
  public function increaseBountyLevel(optional multiplier: int): int {
    var level_before: int;
    var i: int;
    multiplier = Max(1, multiplier);
    level_before = this.getCurrentRegionBountyLevel();
    this.setCurrentRegionBountyLevel(level_before+multiplier);
    this.master.storages.bounty.save();
    for (i = level_before; i<level_before+multiplier; i += 1) {
      this.giveBountyLevelupItemToPlayer(i);
    }
    
    RER_tutorialTryShowBountyLevel();
    return level_before+multiplier;
  }
  
  public function giveBountyLevelupItemToPlayer(bounty_level: int) {
    RER_giveItemForBountyLevelAndCurrentRegion(this.master, thePlayer.GetInventory(), bounty_level);
  }
  
}


state Initialising in RER_BountyManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_BountyManager - Initialising");
    parent.GotoState('Processing');
  }
  
}


state Processing in RER_BountyManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_BountyManager - Processing");
    this.Processing_main();
  }
  
  entry function Processing_main() {
    this.verifyBountyRegion();
    parent.displayMarkersForCurrentBounty();
    parent.displayOnelinersForCurrentBounty();
    while (true) {
      if (!parent.isBountyActive()) {
        Sleep(20);
        continue;
      }
      
      this.spawnNearbyBountyGroups();
      Sleep(10);
    }
    
  }
  
  function verifyBountyRegion() {
    if (!parent.isBountyActive()) {
      return ;
    }
    
    if (SUH_isPlayerInRegion(parent.master.storages.bounty.current_bounty.region_name)) {
      return ;
    }
    
    NHUD(StrReplace(GetLocStringByKey("rer_strayed_too_far_cancelled"), "{{thing}}", StrLower(GetLocStringByKey("rer_bounty"))));
    theSound.SoundEvent("gui_global_denied");
    parent.abandonBounty();
  }
  
  latent function spawnNearbyBountyGroups() {
    var groups: array<RER_BountyRandomMonsterGroupData>;
    var player_position: Vector;
    var i: int;
    if (!parent.isBountyActive()) {
      NDEBUG("RER warning: spawnNearbyBountyGroups() was called but no active bounty was found");
      return ;
    }
    
    player_position = thePlayer.GetWorldPosition();
    this.trySpawnBountyGroup(parent.master.storages.bounty.current_bounty.random_data.main_group, 100, player_position, -1);
    groups = parent.master.storages.bounty.current_bounty.random_data.side_groups;
    for (i = 0; i<groups.Size(); i += 1) {
      if (groups[i].was_killed) {
        continue;
      }
      
      
      NLOG("spawnNearbyBountyGroups(), side group "+i);
      
      this.trySpawnBountyGroup(groups[i], 50, player_position, i);
    }
    
  }
  
  latent function trySpawnBountyGroup(group: RER_BountyRandomMonsterGroupData, radius: float, player_position: Vector, index: int) {
    var distance_from_player: float;
    var max_distance: float;
    var position: Vector;
    max_distance = radius*radius;
    position = group.position;
    position.Z = player_position.Z;
    distance_from_player = VecDistanceSquared2D(player_position, position);
    NLOG("trySpawnBountyGroup(), distance from player = "+distance_from_player);
    if (distance_from_player>max_distance) {
      return ;
    }
    
    if (this.areThereBountyCreaturesNearby(player_position)) {
      return ;
    }
    
    this.spawnBountyGroup(group, index);
    if (!parent.master.hasJustBooted()) {
      theGame.SaveGame(SGT_QuickSave, -1);
    }
    
    theSound.SoundEvent("gui_ingame_new_journal");
  }
  
  public latent function spawnBountyGroup(group_data: RER_BountyRandomMonsterGroupData, group_index: int): RandomEncountersReworkedHuntingGroundEntity {
    var rer_entity: RandomEncountersReworkedHuntingGroundEntity;
    var current_group: RER_BountyRandomMonsterGroupData;
    var side_bestiary_entry: RER_BestiaryEntry;
    var damage_modifier: SU_BaseDamageModifier;
    var rer_entity_template: CEntityTemplate;
    var bestiary_entry: RER_BestiaryEntry;
    var side_entities: array<CEntity>;
    var entities: array<CEntity>;
    var player_position: Vector;
    var position: Vector;
    var i: int;
    NLOG("spawnBountyGroup()"+group_index);
    bestiary_entry = parent.master.bestiary.entries[group_data.type];
    position = group_data.position;
    if (position.Z==0) {
      player_position = thePlayer.GetWorldPosition();
      position.Z = player_position.Z;
    }
    
    if (!getGroundPosition(position, 2, 50) || position.Z<=0) {
      FixZAxis(position);
      NLOG("spawnBountyGroup, could not find a safe ground position. Defaulting to marker position");
    }
    
    damage_modifier = new SU_BaseDamageModifier in parent;
    damage_modifier.damage_received_modifier = 0.7;
    damage_modifier.damage_dealt_modifier = 1.05;
    entities = bestiary_entry.spawn(parent.master, position, group_data.count, , EncounterType_CONTRACT, RER_BESF_NO_BESTIARY_FEATURE|RER_BESF_NO_PERSIST, 'RandomEncountersReworked_BountyCreature', , damage_modifier);
    if (group_index<0) {
      for (i = 0; i<parent.master.storages.bounty.current_bounty.random_data.side_groups.Size(); i += 1) {
        current_group = parent.master.storages.bounty.current_bounty.random_data.side_groups[i];
        
        if (!current_group.was_killed) {
          continue;
        }
        
        
        side_bestiary_entry = parent.master.bestiary.getEntry(parent.master, current_group.type);
        
        side_entities = side_bestiary_entry.spawn(parent.master, position, 1, , EncounterType_CONTRACT, RER_BESF_NO_BESTIARY_FEATURE|RER_BESF_NO_PERSIST, 'RandomEncountersReworked_BountyCreature', , damage_modifier);
        
        if (side_entities.Size()>0) {
          entities.PushBack(side_entities[0]);
        }
        
      }
      
    }
    
    NLOG("bounty group "+group_index+" spawned "+entities.Size()+" entities at "+VecToString(position));
    rer_entity_template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\rer_hunting_ground_entity.w2ent", true));
    rer_entity = (RandomEncountersReworkedHuntingGroundEntity)(theGame.CreateEntity(rer_entity_template, position, thePlayer.GetWorldRotation()));
    rer_entity.activateBountyMode(parent, group_index);
    rer_entity.startEncounter(parent.master, entities, bestiary_entry);
    for (i = 0; i<entities.Size(); i += 1) {
      if (!entities[i].HasTag('RER_BountyEntity')) {
        entities[i].AddTag('RER_BountyEntity');
      }
      
    }
    
    parent.master.storages.bounty.save();
    theSound.SoundEvent("gui_journal_track_quest");
    return rer_entity;
  }
  
  function areThereBountyCreaturesNearby(player_position: Vector): bool {
    var entities: array<CEntity>;
    var distance: float;
    var i: int;
    theGame.GetEntitiesByTag('RER_BountyEntity', entities);
    for (i = 0; i<entities.Size(); i += 1) {
      distance = VecDistanceSquared2D(entities[i].GetWorldPosition(), player_position);
      
      if (distance<=200*200) {
        return true;
      }
      
    }
    
    return false;
  }
  
}

function RER_giveItemForBountyLevelAndCurrentRegion(master: CRandomEncounters, inventory: CInventoryComponent, level: int) {
  RER_giveItemForBountyLevelAndRegion(master, inventory, level, SUH_getCurrentRegion());
}


function RER_giveItemForBountyLevelAndRegion(master: CRandomEncounters, inventory: CInventoryComponent, level: int, region: string) {
  if (region=="no_mans_land") {
    RER_giveItemForLevelNoMansLand(master, inventory, level);
  }
  else if (region=="skellige") {
    RER_giveItemForLevelSkellige(master, inventory, level);
    
  }
  else if (region=="bob") {
    RER_giveItemForLevelToussaint(master, inventory, level);
    
  }
  else if (region=="prolog_village") {
    RER_giveItemForLevelWhiteOrchard(master, inventory, level);
    
  }
  else if (region=="kaer_morhen") {
    RER_giveItemForLevelKaerMorhen(master, inventory, level);
    
  }
  else  {
    RER_giveItemForLevelUnknown(master, inventory, level);
    
  }
  
}


function RER_giveItemForLevelNoMansLand(master: CRandomEncounters, inventory: CInventoryComponent, level: int) {
  if (level==5) {
    inventory.AddAnItem('DLC5 Nilfgaardian Armor');
    inventory.AddAnItem('DLC5 Nilfgaardian Pants');
    inventory.AddAnItem('DLC5 Nilfgaardian Boots');
    inventory.AddAnItem('DLC5 Nilfgaardian Gloves');
    inventory.AddAnItem('DLC5 Nilfgaardian HorseBag');
    inventory.AddAnItem('DLC5 Nilfgaardian HorseBlinders');
    inventory.AddAnItem('DLC5 Nilfgaardian HorseSaddle');
  }
  else if (level==10) {
    inventory.AddAnItem('Ofir Sabre 1');
    
    inventory.AddAnItem('Crafted Ofir Steel Sword');
    
  }
  else if (level==15) {
    inventory.AddAnItem('Crafted Ofir Armor');
    
    inventory.AddAnItem('Crafted Ofir Pants');
    
    inventory.AddAnItem('Crafted Ofir Gloves');
    
    inventory.AddAnItem('Crafted Ofir Boots');
    
    inventory.AddAnItem('Ofir Horse Bag');
    
    inventory.AddAnItem('Ofir Horse Blinders');
    
    inventory.AddAnItem('Horse Saddle 6');
    
  }
  else if (level==20) {
    inventory.AddAnItem('Olgierd Sabre');
    
    inventory.AddAnItem('EP1 Crafted Witcher Silver Sword');
    
  }
  else if (level==25) {
    inventory.AddAnItem('EP1 Viper School steel sword');
    
    inventory.AddAnItem('EP1 Viper School silver sword');
    
  }
  else if (level==30) {
    inventory.AddAnItem('EP1 Witcher Armor');
    
    inventory.AddAnItem('EP1 Witcher Boots');
    
    inventory.AddAnItem('EP1 Witcher Gloves');
    
    inventory.AddAnItem('EP1 Witcher Pants ');
    
  }
  else if (level==35) {
    inventory.AddAnItem('Devil Saddle');
    
  }
  else if (level==40) {
    inventory.AddAnItem('Cornucopia');
    
  }
  else if (level==45) {
    inventory.AddMoney(5000);
    
  }
  else if (level==50) {
    inventory.AddAnItem('Soltis Vodka');
    
  }
  else  {
    RER_giveItemForLevelUnknown(master, inventory, level);
    
  }
  
}


function RER_giveItemForLevelSkellige(master: CRandomEncounters, inventory: CInventoryComponent, level: int) {
  if (level==5) {
    inventory.AddAnItem('DLC14 Skellige Armor');
    inventory.AddAnItem('DLC14 Skellige Pants');
    inventory.AddAnItem('DLC14 Skellige Boots');
    inventory.AddAnItem('DLC14 Skellige Gloves');
    inventory.AddAnItem('DLC14 Skellige HorseBag');
    inventory.AddAnItem('DLC14 Skellige HorseBlinders');
    inventory.AddAnItem('DLC14 Skellige HorseSaddle');
  }
  else if (level==10) {
    inventory.AddAnItem('Gloryofthenorth');
    
    inventory.AddAnItem('Gloryofthenorth_crafted');
    
  }
  else if (level==15) {
    inventory.AddAnItem('q402 Skellige sword 3');
    
  }
  else  {
    RER_giveItemForLevelUnknown(master, inventory, level);
    
  }
  
}


function RER_giveItemForLevelToussaint(master: CRandomEncounters, inventory: CInventoryComponent, level: int) {
  if (level==5) {
    inventory.AddAnItem('Gwent steel sword 1');
  }
  else if (level==10) {
    inventory.AddAnItem('Unique steel sword');
    
    inventory.AddAnItem('Unique silver sword');
    
  }
  else if (level==15) {
    inventory.AddAnItem('EP2 Silver sword 2');
    
    inventory.AddAnItem('q704 vampire silver sword');
    
  }
  else if (level==20) {
    inventory.AddAnItem('q702 vampire steel sword');
    
    inventory.AddAnItem('q704 vampire steel sword');
    
  }
  else if (level==25) {
    inventory.AddAnItem('q702_vampire_boots');
    
    inventory.AddAnItem('q702_vampire_pants');
    
    inventory.AddAnItem('q702_vampire_gloves');
    
    inventory.AddAnItem('q702_vampire_armor');
    
    inventory.AddAnItem('q702_vampire_mask');
    
  }
  else if (level==30) {
    inventory.AddAnItem('q704_vampire_boots');
    
    inventory.AddAnItem('q704_vampire_pants');
    
    inventory.AddAnItem('q704_vampire_gloves');
    
    inventory.AddAnItem('q704_vampire_armor');
    
    inventory.AddAnItem('q704_vampire_mask');
    
  }
  else  {
    RER_giveItemForLevelUnknown(master, inventory, level);
    
  }
  
}


function RER_giveItemForLevelWhiteOrchard(master: CRandomEncounters, inventory: CInventoryComponent, level: int) {
  if (level==5) {
    inventory.AddAnItem('Viper School steel sword');
    inventory.AddAnItem('Viper School silver sword');
  }
  else if (level==10) {
    inventory.AddAnItem('DLC1 Temerian Armor');
    
    inventory.AddAnItem('DLC1 Temerian Pants');
    
    inventory.AddAnItem('DLC1 Temerian Boots');
    
    inventory.AddAnItem('DLC1 Temerian Gloves');
    
    inventory.AddAnItem('DLC1 Temerian HorseBag');
    
    inventory.AddAnItem('DLC1 Temerian HorseBlinders');
    
    inventory.AddAnItem('DLC1 Temerian HorseSaddle');
    
  }
  else  {
    RER_giveItemForLevelUnknown(master, inventory, level);
    
  }
  
}


function RER_giveItemForLevelKaerMorhen(master: CRandomEncounters, inventory: CInventoryComponent, level: int) {
  if (level==5) {
    inventory.AddAnItem('Roseofaelirenn');
  }
  else if (level==10) {
    inventory.AddAnItem('Crafted Burning Rose Sword');
    
  }
  else  {
    RER_giveItemForLevelUnknown(master, inventory, level);
    
  }
  
}


function RER_giveItemForLevelUnknown(master: CRandomEncounters, inventory: CInventoryComponent, level: int) {
  master.loot_manager.rollAndGiveItemsTo(inventory, 1+((float)(level))*0.02);
}

struct RER_Bounty {
  var seed: int;
  
  var random_data: RER_BountyRandomData;
  
  var is_active: bool;
  
  var region_name: string;
  
}


struct RER_BountyRandomData {
  var main_group: RER_BountyRandomMonsterGroupData;
  
  var side_groups: array<RER_BountyRandomMonsterGroupData>;
  
}


struct RER_BountyRandomMonsterGroupData {
  var type: CreatureType;
  
  var count: int;
  
  var position: Vector;
  
  var was_killed: bool;
  
}

class RER_BountyModuleDialog extends CR4HudModuleDialog {
  var bounty_master_manager: RER_BountyMasterManager;
  
  function DialogueSliderDataPopupResult(value: float, optional isItemReward: bool) {
    super.DialogueSliderDataPopupResult(0, false);
    this.bounty_master_manager.bountySeedSelected((int)(value));
  }
  
  function openSeedSelectorWindow(bounty_master_manager: RER_BountyMasterManager) {
    var data: RER_SeedSelectorBettingSliderData;
    var bounty_level: int;
    this.bounty_master_manager = bounty_master_manager;
    bounty_level = bounty_master_manager.bounty_manager.getTotalBountyLevel();
    data = new RER_SeedSelectorBettingSliderData in this;
    data.bounty_master_manager = bounty_master_manager;
    data.ScreenPosX = 0.62;
    data.ScreenPosY = 0.65;
    data.SetMessageTitle(GetLocStringByKey("panel_hud_dialogue_title_bet_rer"));
    data.dialogueRef = this;
    data.BlurBackground = false;
    data.minValue = 0;
    data.maxValue = bounty_master_manager.bounty_manager.getSeedBountyLevelStep()*bounty_level;
    data.currentValue = 0;
    theGame.RequestMenu('PopupMenu', data);
  }
  
}


class RER_SeedSelectorBettingSliderData extends BettingSliderData {
  var bounty_master_manager: RER_BountyMasterManager;
  
  public function GetGFxData(parentFlashValueStorage: CScriptedFlashValueStorage): CScriptedFlashObject {
    var l_flashObject: CScriptedFlashObject;
    l_flashObject = super.GetGFxData(parentFlashValueStorage);
    l_flashObject.SetMemberFlashInt("playerMoney", bounty_master_manager.bounty_manager.getMaximumSeed());
    l_flashObject.SetMemberFlashBool("displayMoneyIcon", false);
    return l_flashObject;
  }
  
  public function OnUserFeedback(KeyCode: string): void {
    if (KeyCode=="enter-gamepad_A") {
      dialogueRef.DialogueSliderDataPopupResult(currentValue);
      ClosePopup();
    }
    
  }
  
}

statemachine class RER_BountyMasterManager {
  var bounty_master_entity: CEntity;
  
  var last_talking_time: float;
  
  var bounty_manager: RER_BountyManager;
  
  var picked_seed: int;
  
  var oneliner: RER_OnelinerEntity;
  
  public latent function init(bounty_manager: RER_BountyManager) {
    this.bounty_manager = bounty_manager;
    this.spawnBountyMaster();
    this.GotoState('Waiting');
  }
  
  public latent function spawnBountyMaster() {
    var valid_positions: array<Vector>;
    var template: CEntityTemplate;
    var position_index: int;
    var template_path: string;
    var map_pin: SU_MapPin;
    var current_region: string;
    if (!RER_modPowerIsBountySystemEnabled(this.bounty_manager.master.getModPower())) {
      return ;
    }
    
    current_region = SUH_getCurrentRegion();
    this.bounty_master_entity = theGame.GetEntityByTag('RER_bounty_master');
    if (current_region=="no_mans_land") {
      template_path = "gameplay\community\community_npcs\prologue\regular\temerian_merchant.w2ent";
    }
    else if (current_region=="skellige") {
      template_path = "gameplay\community\community_npcs\skellige\regular\skellige_merchant.w2ent";
      
    }
    else if (current_region=="bob") {
      template_path = "dlc\bob\data\gameplay\community\community_npcs\craftsmen\merchant.w2ent";
      
    }
    else if (current_region=="prolog_village") {
      template_path = "gameplay\community\community_npcs\prologue\regular\nilfgaardian_noble.w2ent";
      
    }
    else  {
      template_path = "dlc\ep1\community\community_npcs\gustfields_hunter.w2ent";
      
    }
    
    valid_positions = this.getBountyMasterValidPositions();
    position_index = ((int)(RandNoiseF(GameTimeHours(theGame.CalculateTimePlayed()), valid_positions.Size())))%valid_positions.Size();
    if (position_index<0 || position_index>valid_positions.Size()-1) {
      position_index = ((int)(RandNoiseF(RER_getPlayerLevel(), valid_positions.Size()-1)))%valid_positions.Size();
    }
    
    if (position_index<0 || position_index>valid_positions.Size()-1) {
      position_index = 0;
    }
    
    if (this.bounty_master_entity) {
      NLOG("bounty master exists, template = "+StrAfterFirst(this.bounty_master_entity.ToString(), "::"));
      if (StrAfterFirst(this.bounty_master_entity.ToString(), "::")!=template_path) {
        NLOG("bounty master wrong template");
        this.bounty_master_entity.Destroy();
        delete this.bounty_master_entity;
      }
      else  {
        bounty_master_entity.TeleportWithRotation(valid_positions[position_index]+Vector(0, 0, 0.2), VecToRotation(thePlayer.GetWorldPosition()-valid_positions[position_index]));
        
      }
      
    }
    
    if (!this.bounty_master_entity) {
      NLOG("bounty master doesn't exist");
      template = (CEntityTemplate)(LoadResourceAsync(template_path, true));
      this.bounty_master_entity = theGame.CreateEntity(template, valid_positions[position_index]+Vector(0, 0, 0.2), thePlayer.GetWorldRotation(), , , , PM_Persist);
      this.bounty_master_entity.AddTag('RER_bounty_master');
    }
    
    SU_removeCustomPinByTag("RER_bounty_master");
    if (theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERmarkersBountyHunting')) {
      map_pin = new SU_MapPin in thePlayer;
      map_pin.tag = "RER_bounty_master";
      map_pin.pin_tag = 'RER_bounty_master';
      map_pin.position = valid_positions[position_index];
      map_pin.description = GetLocStringByKey("rer_mappin_bounty_master_description");
      map_pin.label = GetLocStringByKey("rer_mappin_bounty_master_title");
      map_pin.type = "QuestAvailableBaW";
      map_pin.filtered_type = "QuestAvailableBaW";
      map_pin.radius = 10;
      map_pin.region = SUH_getCurrentRegion();
      map_pin.is_fast_travel = true;
      map_pin.appears_on_minimap = theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERminimapMarkerBountyMaster');
      SUMP_addCustomPin(map_pin);
      NLOG("bounty master placed at "+VecToString(valid_positions[position_index]));
    }
    
    this.addOneliner();
  }
  
  private function addOneliner() {
    if (!theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERonelinersBountyMaster')) {
      return ;
    }
    
    this.oneliner = RER_onelinerEntity("<img src='img://icons/quests/treasurehunt.png' vspace='-24' /> Bounty Master", this.bounty_master_entity);
  }
  
  public function getBountyMasterValidPositions(): array<Vector> {
    var area: EAreaName;
    var area_string: string;
    var output: array<Vector>;
    area = theGame.GetCommonMapManager().GetCurrentArea();
    switch (area) {
      case AN_Prologue_Village:
      case AN_Prologue_Village_Winter:
      output.PushBack(Vector(-371.5, 372.5, 1.9));
      output.PushBack(Vector(491.3, -64.7, 8.9));
      output.PushBack(Vector(11.5, -24.9, 2.3));
      break;
      
      case AN_Skellige_ArdSkellig:
      output.PushBack(Vector(-297.9, -1049, 6));
      output.PushBack(Vector(-36, 613.5, 2));
      output.PushBack(Vector(1488, 1907, 4.7));
      break;
      
      case AN_Kaer_Morhen:
      output.PushBack(Vector(-91, -22.8, 146));
      break;
      
      case AN_NMLandNovigrad:
      case AN_Velen:
      output.PushBack(Vector(-186, 187, 7.6));
      output.PushBack(Vector(175, 7, 13.8));
      output.PushBack(Vector(2321, -881, 16.1));
      output.PushBack(Vector(691, 2025, 33.4));
      output.PushBack(Vector(543, 1669, 4.12));
      output.PushBack(Vector(707.6, 1751.2, 4.3));
      output.PushBack(Vector(1758, 1049, 6.8));
      output.PushBack(Vector(1714.3, 918, 14));
      output.PushBack(Vector(2497, 2497, 2.8));
      break;
      
      default:
      area_string = AreaTypeToName(theGame.GetCommonMapManager().GetCurrentArea());
      if (area_string=="bob") {
        output.PushBack(Vector(-229, -1184, 3.7));
        output.PushBack(Vector(-745, -321, 29.4));
        output.PushBack(Vector(-148.6, -635.4, 11.4));
        output.PushBack(Vector(-490.4, -954.3, 61.2));
      }
      else  {
      }
      
      break;
    }
    return output;
  }
  
  public function bountySeedSelected(seed: int) {
    this.picked_seed = seed;
    this.GotoState('CreateBounty');
  }
  
}

state CreateBounty in RER_BountyMasterManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_BountyMasterManager - CreateBounty");
    this.CreateBounty_main();
  }
  
  entry function CreateBounty_main() {
    parent.bounty_manager.startBounty(parent.picked_seed);
    parent.GotoState('Waiting');
  }
  
}

state DialogChoice in RER_BountyMasterManager {
  private var cameras: array<SU_StaticCamera>;
  
  private var current_camera_index: int;
  
  private var camera_time_counter: float;
  
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_BountyMasterManager - DialogChoice");
    this.DialogChoice_main();
  }
  
  private latent function pushCameras() {
    var camera_0: SU_StaticCamera;
    var camera_1: SU_StaticCamera;
    camera_0 = SU_getStaticCamera();
    this.cameras.PushBack(camera_0);
    camera_1 = SU_getStaticCamera();
    this.cameras.PushBack(camera_1);
  }
  
  private function getCurrentCamera(): SU_StaticCamera {
    return this.cameras[this.current_camera_index];
  }
  
  private latent function swapCamera() {
    var camera: SU_StaticCamera;
    if (this.current_camera_index==0) {
      this.current_camera_index = 1;
    }
    else  {
      this.current_camera_index = 0;
      
    }
    
    camera = SU_getStaticCamera();
    camera.activationDuration = 20;
    camera.deactivationDuration = 2;
    this.cameras[this.current_camera_index] = camera;
  }
  
  entry function DialogChoice_main() {
    var choices: array<SSceneChoice>;
    var has_completed_a_bounty: bool;
    var crowns_from_trophies: int;
    var trophy_line: string;
    this.pushCameras();
    has_completed_a_bounty = parent.bounty_manager.getTotalBountyLevel()>0;
    this.doMovementAdjustment();
    choices.PushBack(SSceneChoice(GetLocStringByKey("rer_dialog_start_bounty"), true, has_completed_a_bounty, false, DialogAction_MONSTERCONTRACT, 'StartBounty'));
    crowns_from_trophies = this.convertTrophiesIntoCrowns(true);
    trophy_line = StrReplace(GetLocStringByKey("rer_dialog_sell_trophies"), "{{crowns_amount}}", crowns_from_trophies);
    if (RER_playerUsesEnhancedEditionRedux() && thePlayer.GetSkillLevel(S_Perk_19)>0) {
      trophy_line += " ("+GetLocStringByKey('rer_huntsman_redux_bonus')+")";
    }
    
    choices.PushBack(SSceneChoice(trophy_line, false, crowns_from_trophies<=0, false, DialogAction_SHOPPING, 'SellTrophies'));
    choices.PushBack(SSceneChoice(GetLocStringByKey("rer_trade_tokens"), false, false, false, DialogAction_SHOPPING, 'TradeTokens'));
    choices.PushBack(SSceneChoice(GetLocStringByKey("rer_dialog_farewell"), false, false, false, DialogAction_GETBACK, 'CloseDialog'));
    this.displayDialogChoices(choices);
  }
  
  latent function displayDialogChoices(choices: array<SSceneChoice>) {
    var response: SSceneChoice;
    Sleep(0.25);
    this.swapCameraAndStartNewCamera();
    while (true) {
      response = this.waitForResponseAndPlayCameraScene(choices);
      SU_closeDialogChoiceInterface();
      if (response.playGoChunk=='CloseDialog') {
        (new RER_RandomDialogBuilder in thePlayer).start().dialog(new REROL_farewell in thePlayer, true).play();
        parent.GotoState('Waiting');
        return ;
      }
      
      if (response.playGoChunk=='StartBounty') {
        parent.GotoState('SeedSelection');
        return ;
      }
      
      if (response.playGoChunk=='StartBountySkipConversation') {
        parent.GotoState('SeedSelection');
        return ;
      }
      
      if (response.playGoChunk=='TradeTokens') {
        this.displayTokenTradingDialogChoice();
        Sleep(0.2);
      }
      else  {
        (new RER_RandomDialogBuilder in thePlayer).start().dialog(new REROL_thanks_all_i_need_for_now in thePlayer, true).play();
        
        this.convertTrophiesIntoCrowns();
        
        this.removeTrophyChoiceFromList(choices);
        
      }
      
    }
    
  }
  
  latent function waitForResponseAndPlayCameraScene(choices: array<SSceneChoice>): SSceneChoice {
    var dialogue_module: CR4HudModuleDialog;
    var last_frame_time: float;
    var current_frame_time: float;
    var delta: float;
    last_frame_time = theGame.GetEngineTimeAsSeconds();
    dialogue_module = SU_setDialogChoices(choices);
    while (true) {
      SleepOneFrame();
      current_frame_time = theGame.GetEngineTimeAsSeconds();
      delta = current_frame_time-last_frame_time;
      last_frame_time = current_frame_time;
      this.camera_time_counter -= delta;
      if (this.camera_time_counter<=0) {
        this.camera_time_counter = 20;
        this.swapCameraAndStartNewCamera();
      }
      
      if (SU_isDialogChoiceCurrentlyPlaying(dialogue_module)) {
        continue;
      }
      
      return SU_getLastAcceptedChoiceAndFlushDialog(dialogue_module);
    }
    
  }
  
  latent function swapCameraAndStartNewCamera() {
    var player_position: Vector;
    var bounty_master_position: Vector;
    var heading: float;
    var camera_position: Vector;
    var current_camera: SU_StaticCamera;
    var mean_position: Vector;
    player_position = thePlayer.GetWorldPosition();
    bounty_master_position = parent.bounty_master_entity.GetWorldPosition();
    heading = VecHeading(player_position-bounty_master_position);
    camera_position = player_position+VecConeRand(heading, 100, 1.5, 3)+Vector(0, 0, RandRangeF(1.5, 3));
    this.swapCamera();
    current_camera = this.getCurrentCamera();
    mean_position = (player_position+bounty_master_position)/2+Vector(0, 0, 2);
    current_camera.teleportAndLookAt(camera_position, mean_position);
    current_camera.start();
  }
  
  latent function displayTokenTradingDialogChoice() {
    var inventory: CInventoryComponent;
    var choices: array<SSceneChoice>;
    var response: SSceneChoice;
    inventory = thePlayer.GetInventory();
    Sleep(0.25);
    while (true) {
      choices.Clear();
      this.addChoiceAboutToken(choices, inventory, ContractRewardType_GEAR);
      this.addChoiceAboutToken(choices, inventory, ContractRewardType_CONSUMABLES);
      this.addChoiceAboutToken(choices, inventory, ContractRewardType_EXPERIENCE);
      this.addChoiceAboutToken(choices, inventory, ContractRewardType_GOLD);
      this.addChoiceAboutToken(choices, inventory, ContractRewardType_MATERIALS);
      if (choices.Size()<=0) {
        choices.PushBack(SSceneChoice(GetLocStringByKey('rer_token_trading_option_empty'), true, true, false, DialogAction_GETBACK, 'CloseDialog'));
      }
      else  {
        choices.PushBack(SSceneChoice(GetLocStringByKey('rer_trade_all_tokens'), true, false, false, DialogAction_SHOPPING, 'TradeAllTokens'));
        
      }
      
      choices.PushBack(SSceneChoice(GetLocStringByKey('rer_cancel'), false, false, false, DialogAction_GETBACK, 'CloseDialog'));
      response = this.waitForResponseAndPlayCameraScene(choices);
      SU_closeDialogChoiceInterface();
      if (response.playGoChunk=='CloseDialog') {
        return ;
      }
      
      if (response.playGoChunk=='TradeAllTokens') {
        tradeAllTokens();
        return ;
      }
      
      RER_applyLootFromContractTokenName(parent.bounty_manager.master, thePlayer.GetInventory(), response.playGoChunk);
    }
    
  }
  
  function addChoiceAboutToken(out choices: array<SSceneChoice>, inventory: CInventoryComponent, type: RER_ContractRewardType) {
    var quantity: int;
    var line: string;
    quantity = inventory.GetItemQuantityByName(RER_contractRewardTypeToItemName(type));
    if (quantity<=0) {
      return ;
    }
    
    line = GetLocStringByKey('rer_token_trading_option');
    line = StrReplace(line, "{{reward_type}}", RER_getLocalizedRewardType(type));
    line = StrReplace(line, "{{tokens_amount}}", IntToString(quantity));
    choices.PushBack(SSceneChoice(line, true, false, false, DialogAction_SHOPPING, RER_contractRewardTypeToItemName(type)));
  }
  
  latent function tradeAllTokens() {
    var inventories: array<CInventoryComponent>;
    var possibles_token_names: array<name>;
    var quantity: int;
    var price: int;
    var inventory: CInventoryComponent;
    var idx55bc3e8c45d94987af8b842933d4d912: int;
    var token_name: name;
    var idx4816684089384f2b959a8f5270dd7b09: int;
    possibles_token_names.PushBack(RER_contractRewardTypeToItemName(ContractRewardType_GEAR));
    possibles_token_names.PushBack(RER_contractRewardTypeToItemName(ContractRewardType_CONSUMABLES));
    possibles_token_names.PushBack(RER_contractRewardTypeToItemName(ContractRewardType_EXPERIENCE));
    possibles_token_names.PushBack(RER_contractRewardTypeToItemName(ContractRewardType_GOLD));
    possibles_token_names.PushBack(RER_contractRewardTypeToItemName(ContractRewardType_MATERIALS));
    inventories.PushBack(thePlayer.GetInventory());
    inventories.PushBack(GetWitcherPlayer().GetHorseManager().GetInventoryComponent());
    for (idx55bc3e8c45d94987af8b842933d4d912 = 0; idx55bc3e8c45d94987af8b842933d4d912 < inventories.Size(); idx55bc3e8c45d94987af8b842933d4d912 += 1) {
      inventory = inventories[idx55bc3e8c45d94987af8b842933d4d912];
      for (idx4816684089384f2b959a8f5270dd7b09 = 0; idx4816684089384f2b959a8f5270dd7b09 < possibles_token_names.Size(); idx4816684089384f2b959a8f5270dd7b09 += 1) {
        token_name = possibles_token_names[idx4816684089384f2b959a8f5270dd7b09];
        quantity = inventory.GetItemQuantityByName(token_name);
        
        if (quantity<=0) {
          continue;
        }
        
        
        RER_applyLootFromContractTokenName(parent.bounty_manager.master, inventory, token_name, quantity);
      }
    }
  }
  
  function removeTrophyChoiceFromList(out choices: array<SSceneChoice>) {
    var i: int;
    for (i = 0; i<choices.Size(); i += 1) {
      if (choices[i].playGoChunk=='SellTrophies') {
        choices.Erase(i);
        return ;
      }
      
    }
    
  }
  
  function convertTrophiesIntoCrowns(optional ignore_item_transaction: bool): int {
    var trophy_guids: array<SItemUniqueId>;
    var inventory: CInventoryComponent;
    var guid: SItemUniqueId;
    var price: int;
    var i: int;
    var output: int;
    var buying_price: float;
    var quantity: int;
    buying_price = StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('RERmonsterTrophies', 'RERtrophyMasterBuyingPrice'))/100;
    inventory = thePlayer.GetInventory();
    trophy_guids = inventory.GetItemsByTag('RER_Trophy');
    for (i = 0; i<trophy_guids.Size(); i += 1) {
      guid = trophy_guids[i];
      
      quantity = inventory.GetItemQuantity(guid);
      
      price = ((int)(inventory.GetItemPrice(guid)*buying_price))*quantity;
      
      if (RER_playerUsesEnhancedEditionRedux() && thePlayer.GetSkillLevel(S_Perk_19)>0) {
        price = (int)((price*1.5));
      }
      
      
      if (!ignore_item_transaction) {
        inventory.AddMoney(price);
        inventory.RemoveItem(guid, quantity);
      }
      
      
      output += price;
    }
    
    if (output>0 && !ignore_item_transaction) {
      NDEBUG(StrReplace(GetLocStringByKey("rer_bounty_master_trophies_bought_notification"), "{{crowns_amount}}", RER_yellowFont(output)));
    }
    
    return output;
  }
  
  function doMovementAdjustment() {
    var movement_adjustor: CMovementAdjustor;
    var slide_ticket: SMovementAdjustmentRequestTicket;
    var target: CActor;
    target = thePlayer;
    movement_adjustor = ((CActor)(parent.bounty_master_entity)).GetMovingAgentComponent().GetMovementAdjustor();
    slide_ticket = movement_adjustor.GetRequest('RotateTowardsPlayer');
    movement_adjustor.CancelByName('RotateTowardsPlayer');
    slide_ticket = movement_adjustor.CreateNewRequest('RotateTowardsPlayer');
    movement_adjustor.AdjustmentDuration(slide_ticket, 0.25);
    movement_adjustor.RotateTowards(slide_ticket, target);
    parent.bounty_master_entity.Teleport(parent.bounty_master_entity.GetWorldPosition());
  }
  
  event OnLeaveState(nextStateName: name) {
    var camera: SU_StaticCamera;
    camera = this.getCurrentCamera();
    camera.Stop();
    super.OnLeaveState(nextStateName);
  }
  
}

state SeedSelection in RER_BountyMasterManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_BountyMasterManager - SeedSelection");
    this.SeedSelection_main();
  }
  
  entry function SeedSelection_main() {
    var distance_from_player: float;
    distance_from_player = VecDistanceSquared(thePlayer.GetWorldPosition(), parent.bounty_master_entity.GetWorldPosition());
    if (distance_from_player<10*10) {
      parent.last_talking_time = theGame.GetEngineTimeAsSeconds();
      if (theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERignoreSeedSelectorWindow')) {
        parent.bountySeedSelected(0);
      }
      else  {
        this.openHaggleWindow();
        
      }
      
    }
    else  {
      parent.GotoState('Waiting');
      
    }
    
  }
  
  function openHaggleWindow() {
    var haggle_module_dialog: RER_BountyModuleDialog;
    haggle_module_dialog = new RER_BountyModuleDialog in parent;
    haggle_module_dialog.openSeedSelectorWindow(parent);
  }
  
}

state Waiting in RER_BountyMasterManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_BountyMasterManager - Waiting");
    this.Waiting_main();
  }
  
  entry function Waiting_main() {
    var already_has_listener: bool;
    already_has_listener = SU_NpcInteraction_hasEventListenerWithTag((CNewNPC)(parent.bounty_master_entity), "RER_StartBountyMasterConversationOnInteraction");
    if (!already_has_listener) {
      ((CNewNPC)(parent.bounty_master_entity)).addInteractionEventListener(new RER_StartBountyMasterConversationOnInteraction in parent.bounty_master_entity);
    }
    
  }
  
}


class RER_StartBountyMasterConversationOnInteraction extends SU_InteractionEventListener {
  default tag = "RER_StartBountyMasterConversationOnInteraction";
  
  public function run(actionName: string, activator: CEntity, receptor: CPeristentEntity): bool {
    var rer: CRandomEncounters;
    if (!getRandomEncounters(rer)) {
      NDEBUG("An error occured, could not find the RER entity in the world");
      return false;
    }
    
    if (rer.bounty_manager.bounty_master_manager.GetCurrentStateName()=='Waiting') {
      rer.bounty_manager.bounty_master_manager.GotoState('DialogChoice');
    }
    
    return true;
  }
  
}

class RER_CameraDataInterface {
  public var can_loop: bool;
  
  default can_loop = true;
  
  latent function loop(camera: RER_StaticCamera) {
  }
  
}


class RER_CameraDataMoveToPositionLookAtPosition extends RER_CameraDataInterface {
  public var camera_position_goal: Vector;
  
  public var camera_target: Vector;
  
  function getCameraTarget(): Vector {
    return this.camera_target;
  }
  
  function getCameraPositionGoal(): Vector {
    return this.camera_position_goal;
  }
  
  function canRunLoop(): bool {
    var camera_rotation_blending: float;
    var camera_position: Vector;
    var camera_rotation: EulerAngles;
    var camera_rotation_goal: EulerAngles;
    return VecDistanceSquared(this.camera_position, this.camera_position_goal)>1;
  }
  
  public var camera_rotation_blending: float;
  
  default camera_rotation_blending = 0.01;
  
  private var camera_position: Vector;
  
  private var camera_rotation: EulerAngles;
  
  private var camera_rotation_goal: EulerAngles;
  
  latent function loop(camera: RER_StaticCamera) {
    var distance_to_position: Vector;
    var rotation_velocity: EulerAngles;
    var position_velocity: Vector;
    var position_goal: Vector;
    this.camera_position = theCamera.GetCameraPosition();
    this.camera_rotation = theCamera.GetCameraRotation();
    while (this.can_loop && this.canRunLoop()) {
      position_goal = this.getCameraPositionGoal();
      position_velocity += VecNormalize(position_goal-this.camera_position)*0.001+position_velocity*0.01;
      position_velocity *= 0.90;
      if (VecDistanceSquared(this.camera_position, position_goal)<0.001) {
        position_velocity *= 0.5;
      }
      
      this.camera_position += position_velocity;
      this.camera_target = this.getCameraTarget();
      this.camera_rotation_goal = VecToRotation(this.camera_target-this.camera_position);
      this.camera_rotation_goal.Pitch *= -1;
      rotation_velocity.Roll += AngleNormalize180(this.camera_rotation_goal.Roll-this.camera_rotation.Roll)*this.camera_rotation_blending;
      rotation_velocity.Yaw += AngleNormalize180(this.camera_rotation_goal.Yaw-this.camera_rotation.Yaw)*this.camera_rotation_blending;
      rotation_velocity.Pitch += AngleNormalize180(this.camera_rotation_goal.Pitch-this.camera_rotation.Pitch)*this.camera_rotation_blending;
      rotation_velocity.Roll *= 0.8;
      rotation_velocity.Yaw *= 0.8;
      rotation_velocity.Pitch *= 0.8;
      this.camera_rotation.Roll += rotation_velocity.Roll;
      this.camera_rotation.Yaw += rotation_velocity.Yaw;
      this.camera_rotation.Pitch += rotation_velocity.Pitch;
      camera.TeleportWithRotation(this.camera_position, this.camera_rotation);
      SleepOneFrame();
    }
    
  }
  
}


class RER_CameraDataMoveToPoint extends RER_CameraDataInterface {
  public var camera_position_goal: Vector;
  
  private var camera_position: Vector;
  
  private var camera_rotation: EulerAngles;
  
  private var camera_rotation_goal: EulerAngles;
  
  private var camera_target: Vector;
  
  function getCameraTarget(): Vector {
    return this.camera_target;
  }
  
  function canRunLoop(): bool {
    return VecDistanceSquared(this.camera_position, this.camera_position_goal)>1;
  }
  
  latent function loop(camera: RER_StaticCamera) {
    var distance_to_position: float;
    this.camera_position = theCamera.GetCameraPosition();
    this.camera_rotation = theCamera.GetCameraRotation();
    while (this.can_loop && this.canRunLoop()) {
      this.camera_target = this.getCameraTarget();
      this.camera_position += (this.camera_position_goal-this.camera_position)*0.01;
      this.camera_rotation_goal = VecToRotation(this.camera_target+Vector(0, 0, 1)-this.camera_position);
      this.camera_rotation_goal.Pitch *= -1;
      this.camera_rotation.Roll += AngleNormalize180(this.camera_rotation_goal.Roll-this.camera_rotation.Roll)*0.01;
      this.camera_rotation.Yaw += AngleNormalize180(this.camera_rotation_goal.Yaw-this.camera_rotation.Yaw)*0.01;
      this.camera_rotation.Pitch += AngleNormalize180(this.camera_rotation_goal.Pitch-this.camera_rotation.Pitch)*0.01;
      camera.TeleportWithRotation(this.camera_position, this.camera_rotation);
    }
    
  }
  
}


class RER_CameraDataFloatAndLookAtTalkingActors extends RER_CameraDataMoveToPositionLookAtPosition {
  public var actors: array<CActor>;
  
  default camera_rotation_blending = 0.01;
  
  function getCameraPositionGoal(): Vector {
    var number_of_actors: int;
    var heading: float;
    var actor_1: CActor;
    var actor_2: CActor;
    var distance_between_actors: float;
    var target: EulerAngles;
    var i: int;
    var talking_actor: CActor;
    var last_talking_actor_index: int;
    number_of_actors = this.actors.Size();
    for (i = 0; i<number_of_actors; i += 1) {
      heading += this.actors[i].GetHeading();
    }
    
    if (number_of_actors>1) {
      actor_1 = this.actors[0];
      actor_2 = this.actors[1];
      distance_between_actors = VecDistance(actor_1.GetWorldPosition(), actor_2.GetWorldPosition());
    }
    else  {
      distance_between_actors = 2;
      
    }
    
    if (last_talking_actor_index>=0) {
      talking_actor = this.actors[this.last_talking_actor_index];
      return this.getCameraTarget()+(VecFromHeading(heading/number_of_actors))*(distance_between_actors+1)+Vector(0, 0, 1.5)+VecFromHeading(talking_actor.GetHeading());
    }
    
    return this.getCameraTarget()+(VecFromHeading(heading/number_of_actors))*(distance_between_actors+1)+Vector(0, 0, 1.5);
  }
  
  protected var last_talking_actor_index: int;
  
  default last_talking_actor_index = -1;
  
  function getCameraTarget(): Vector {
    var number_of_actors: int;
    var position: Vector;
    var weight: int;
    var i: int;
    number_of_actors = this.actors.Size();
    for (i = 0; i<number_of_actors; i += 1) {
      if (this.actors[i].IsSpeaking()) {
        this.last_talking_actor_index = i;
      }
      
    }
    
    for (i = 0; i<number_of_actors; i += 1) {
      if (this.last_talking_actor_index==i) {
        position += (this.actors[i].GetWorldPosition()+Vector(0, 0, 1.5))*2;
        weight += 2;
      }
      else  {
        position += this.actors[i].GetWorldPosition()+Vector(0, 0, 1.5);
        
        weight += 1;
        
      }
      
    }
    
    return position/weight;
  }
  
  function addActor(actor: CActor): RER_CameraDataFloatAndLookAtTalkingActors {
    this.actors.PushBack(actor);
    return this;
  }
  
  function canRunLoop(): bool {
    return true;
  }
  
}


statemachine class RER_CameraManager extends CEntity {
  public var camera: RER_StaticCamera;
  
  latent function spawnCameraEntity() {
    this.camera = RER_getStaticCamera();
  }
  
  public latent function init() {
    var current_scenes: array<RER_CameraDataInterface>;
    var current_scene_index: int;
    this.spawnCameraEntity();
  }
  
  public var current_scenes: array<RER_CameraDataInterface>;
  
  public var current_scene_index: int;
  
  public latent function play(scenes: array<RER_CameraDataInterface>) {
    this.current_scenes = scenes;
    this.current_scene_index = 0;
    this.GotoState('Running');
  }
  
  public latent function playScene(scene: RER_CameraDataInterface) {
    var scenes: array<RER_CameraDataInterface>;
    scenes.PushBack(scene);
    this.play(scenes);
  }
  
  public function stopCurrentScene() {
    if (this.current_scene_index<0 && this.current_scene_index>=this.current_scenes.Size()) {
      return ;
    }
    
    this.current_scenes[this.current_scene_index].can_loop = false;
  }
  
}


state Running in RER_CameraManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_CameraManager - State RUNNING");
    this.run();
  }
  
  entry function run() {
    var i: int;
    parent.camera.deactivationDuration = 1.5;
    parent.camera.activationDuration = 1.5;
    parent.camera.Run();
    for (i = 0; i<parent.current_scenes.Size(); i += 1) {
      parent.current_scene_index = i;
      
      parent.current_scenes[i].loop(parent.camera);
    }
    
    parent.camera.Stop();
  }
  
}


state Waiting in RER_CameraManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_CameraManager - State WAITING");
  }
  
}

latent function createRandomCreatureHunt(master: CRandomEncounters, optional creature_type: CreatureType) {
  var bestiary_entry: RER_BestiaryEntry;
  NLOG("making create hunt");
  if (creature_type==CreatureNONE) {
    bestiary_entry = master.bestiary.getRandomEntryFromBestiary(master, EncounterType_HUNT);
  }
  else  {
    bestiary_entry = master.bestiary.entries[creature_type];
    
  }
  
  if (bestiary_entry.isNull()) {
    NLOG("creature_type is NONE, cancelling spawn");
    return ;
  }
  
  RER_emitEncounterSpawned(master, EncounterType_HUNT);
  if (bestiary_entry.type==CreatureGRYPHON) {
    makeGryphonCreatureHunt(master);
  }
  else  {
    makeDefaultCreatureHunt(master, bestiary_entry);
    
  }
  
}


latent function makeGryphonCreatureHunt(master: CRandomEncounters) {
  var composition: CreatureHuntGryphonComposition;
  composition = new CreatureHuntGryphonComposition in master;
  composition.init(master.settings);
  composition.setBestiaryEntry(master.bestiary.entries[CreatureGRYPHON]).spawn(master);
}


class CreatureHuntGryphonComposition extends CompositionSpawner {
  public function init(settings: RE_Settings) {
    var rer_entity_template: CEntityTemplate;
    var blood_splats_templates: array<RER_TrailMakerTrack>;
    this.setRandomPositionMinRadius(settings.minimum_spawn_distance*3).setRandomPositionMaxRadius((settings.minimum_spawn_distance+settings.spawn_diameter)*3).setAutomaticKillThresholdDistance(settings.kill_threshold_distance*3).setAllowTrophy(settings.trophies_enabled_by_encounter[EncounterType_HUNT]).setAllowTrophyPickupScene(settings.trophy_pickup_scene).setNumberOfCreatures(1);
  }
  
  var rer_entity_template: CEntityTemplate;
  
  var blood_splats_templates: array<RER_TrailMakerTrack>;
  
  protected latent function beforeSpawningEntities(): bool {
    var rer_entities: array<RandomEncountersReworkedGryphonHuntEntity>;
    this.rer_entity_template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\rer_flying_hunt_entity.w2ent", true));
    this.blood_splats_templates = this.master.resources.getBloodSplatsResources();
    return true;
  }
  
  var rer_entities: array<RandomEncountersReworkedGryphonHuntEntity>;
  
  protected latent function forEachEntity(entity: CEntity) {
    var current_rer_entity: RandomEncountersReworkedGryphonHuntEntity;
    current_rer_entity = (RandomEncountersReworkedGryphonHuntEntity)(theGame.CreateEntity(rer_entity_template, initial_position, thePlayer.GetWorldRotation()));
    current_rer_entity.attach((CActor)(entity), (CNewNPC)(entity), entity, this.master);
    if (this.allow_trophy) {
      current_rer_entity.pickup_animation_on_death = this.allow_trophy_pickup_scene;
    }
    
    current_rer_entity.automatic_kill_threshold_distance = this.automatic_kill_threshold_distance;
    if (!master.settings.enable_encounters_loot) {
      current_rer_entity.removeAllLoot();
    }
    
    current_rer_entity.startEncounter(this.blood_splats_templates);
    this.rer_entities.PushBack(current_rer_entity);
  }
  
}


latent function makeDefaultCreatureHunt(master: CRandomEncounters, bestiary_entry: RER_BestiaryEntry) {
  var composition: CreatureHuntComposition;
  composition = new CreatureHuntComposition in master;
  composition.init(master.settings);
  composition.setBestiaryEntry(bestiary_entry).spawn(master);
}


class CreatureHuntComposition extends CreatureAmbushWitcherComposition {
  public function init(settings: RE_Settings) {
    this.setRandomPositionMinRadius(settings.minimum_spawn_distance*2).setRandomPositionMaxRadius((settings.minimum_spawn_distance+settings.spawn_diameter)*2).setAutomaticKillThresholdDistance(settings.kill_threshold_distance*2).setEncounterType(EncounterType_HUNT).setAllowTrophy(settings.trophies_enabled_by_encounter[EncounterType_HUNT]).setAllowTrophyPickupScene(settings.trophy_pickup_scene);
  }
  
  protected latent function afterSpawningEntities(): bool {
    var rer_entity: RandomEncountersReworkedHuntEntity;
    var rer_entity_template: CEntityTemplate;
    rer_entity_template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\rer_hunt_entity.w2ent", true));
    rer_entity = (RandomEncountersReworkedHuntEntity)(theGame.CreateEntity(rer_entity_template, this.initial_position, thePlayer.GetWorldRotation()));
    rer_entity.startEncounter(this.master, this.created_entities, this.bestiary_entry);
    return true;
  }
  
}

latent function createRandomCreatureHuntingGround(master: CRandomEncounters, bestiary_entry: RER_BestiaryEntry) {
  var composition: CreatureHuntingGroundComposition;
  RER_emitEncounterSpawned(master, EncounterType_HUNTINGGROUND);
  composition = new CreatureHuntingGroundComposition in master;
  composition.init(master.settings);
  composition.setBestiaryEntry(bestiary_entry).spawn(master);
}


class CreatureHuntingGroundComposition extends CompositionSpawner {
  public function init(settings: RE_Settings) {
    NLOG("CreatureHuntingGroundComposition");
    this.setRandomPositionMinRadius(settings.minimum_spawn_distance).setRandomPositionMaxRadius(settings.minimum_spawn_distance+settings.spawn_diameter).setAutomaticKillThresholdDistance(settings.kill_threshold_distance).setAllowTrophy(settings.trophies_enabled_by_encounter[EncounterType_HUNTINGGROUND]).setEncounterType(EncounterType_HUNTINGGROUND);
  }
  
  protected latent function afterSpawningEntities(): bool {
    var rer_entity: RandomEncountersReworkedHuntingGroundEntity;
    var rer_entity_template: CEntityTemplate;
    rer_entity_template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\rer_hunting_ground_entity.w2ent", true));
    rer_entity = (RandomEncountersReworkedHuntingGroundEntity)(theGame.CreateEntity(rer_entity_template, this.initial_position, thePlayer.GetWorldRotation()));
    rer_entity.startEncounter(this.master, this.created_entities, this.bestiary_entry);
    return true;
  }
  
}

enum CreatureComposition {
  CreatureComposition_AmbushWitcher = 1,
}


latent function createRandomCreatureAmbush(out master: CRandomEncounters, creature_type: CreatureType) {
  var creature_composition: CreatureComposition;
  var bestiary_entry: RER_BestiaryEntry;
  creature_composition = CreatureComposition_AmbushWitcher;
  if (creature_type==CreatureNONE) {
    bestiary_entry = master.bestiary.getRandomEntryFromBestiary(master, EncounterType_DEFAULT);
  }
  else  {
    bestiary_entry = master.bestiary.entries[creature_type];
    
  }
  
  if (bestiary_entry.isNull()) {
    NLOG("creature_type is NONE, cancelling spawn");
    return ;
  }
  
  NLOG("spawning ambush - "+bestiary_entry.type);
  RER_emitEncounterSpawned(master, EncounterType_DEFAULT);
  if (creature_type==CreatureWILDHUNT) {
    makeCreatureWildHunt(master);
  }
  else  {
    switch (creature_composition) {
      case CreatureComposition_AmbushWitcher:
      makeCreatureAmbushWitcher(bestiary_entry, master);
      break;
    }
    
  }
  
}


latent function makeCreatureWildHunt(out master: CRandomEncounters) {
  var composition: WildHuntAmbushWitcherComposition;
  composition = new WildHuntAmbushWitcherComposition in master;
  composition.init(master.settings);
  composition.setBestiaryEntry(master.bestiary.entries[CreatureWILDHUNT]).spawn(master);
}


class WildHuntAmbushWitcherComposition extends CreatureAmbushWitcherComposition {
  var portal_template: CEntityTemplate;
  
  var rifts: array<CRiftEntity>;
  
  protected latent function beforeSpawningEntities(): bool {
    var success: bool;
    success = super.beforeSpawningEntities();
    if (!success) {
      return false;
    }
    
    this.portal_template = master.resources.getPortalResource();
    return true;
  }
  
  protected latent function forEachEntity(entity: CEntity) {
    var rift: CRiftEntity;
    super.forEachEntity(entity);
    ((CNewNPC)(entity)).SetTemporaryAttitudeGroup('hostile_to_player', AGP_Default);
    ((CNewNPC)(entity)).NoticeActor(thePlayer);
    rift = (CRiftEntity)(theGame.CreateEntity(this.portal_template, entity.GetWorldPosition(), entity.GetWorldRotation()));
    rift.ActivateRift();
    rifts.PushBack(rift);
  }
  
}


latent function makeCreatureAmbushWitcher(bestiary_entry: RER_BestiaryEntry, out master: CRandomEncounters) {
  var composition: CreatureAmbushWitcherComposition;
  composition = new CreatureAmbushWitcherComposition in master;
  composition.init(master.settings);
  composition.setBestiaryEntry(bestiary_entry).spawn(master);
}


class CreatureAmbushWitcherComposition extends CompositionSpawner {
  public function init(settings: RE_Settings) {
    NLOG("CreatureAmbushWitcherComposition");
    this.setRandomPositionMinRadius(settings.minimum_spawn_distance).setRandomPositionMaxRadius(settings.minimum_spawn_distance+settings.spawn_diameter).setAutomaticKillThresholdDistance(settings.kill_threshold_distance).setEncounterType(EncounterType_DEFAULT).setAllowTrophy(settings.trophies_enabled_by_encounter[EncounterType_DEFAULT]).setAllowTrophyPickupScene(settings.trophy_pickup_scene);
  }
  
  protected latent function afterSpawningEntities(): bool {
    var rer_entity: RandomEncountersReworkedHuntEntity;
    var rer_entity_template: CEntityTemplate;
    rer_entity_template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\rer_hunt_entity.w2ent", true));
    rer_entity = (RandomEncountersReworkedHuntEntity)(theGame.CreateEntity(rer_entity_template, this.initial_position, thePlayer.GetWorldRotation()));
    rer_entity.startEncounter(this.master, this.created_entities, this.bestiary_entry, true);
    return true;
  }
  
}

struct RER_ContractSeedFactory {
  var origin: Vector;
  
  var level: int;
  
  var index: int;
  
  var region_name: string;
  
  var timeoffset: int;
  
}


class RER_Contract {
  var factory: RER_ContractSeedFactory;
  
  var seed: int;
  
  public function init(factory: RER_ContractSeedFactory): RER_Contract {
    this.factory = factory;
    this.seed = factory.level*(factory.index+1)+((int)(factory.origin.X))+((int)(factory.origin.Y))+factory.timeoffset;
    return this;
  }
  
  public function difficulty(): int {
    var seed: int;
    var max: int;
    var min: int;
    seed = this.seed+70;
    max = this.factory.level+2;
    min = Max(this.factory.level-2, 0);
    return (int)(RandNoiseF(seed, (float)(max), (float)(min)));
  }
  
  public function hasBonusRewards(): bool {
    var species: array<CreatureType>;
    species = this.speciesList();
    return RandNoiseF(this.seed+80, 1.0)<=species.Size()*0.1;
  }
  
  public function speciesList(): array<CreatureType> {
    var output: array<CreatureType>;
    var seed: int;
    var bestiary: RER_Bestiary;
    var i: int;
    var cmaxf: float;
    var cminf: float;
    seed = this.seed+10;
    bestiary = RER_getBestiary();
    if (bestiary) {
      output.PushBack(bestiary.getRandomSeededEntry(seed).type);
      for (i = 0; i*25<this.factory.level; i += 1) {
        if (RandNoiseF(seed+i, 1.0)<=0.10) {
          output.PushBack(bestiary.getRandomSeededEntry(seed-1).type);
        }
        
      }
      
    }
    else  {
      cmaxf = (float)(((int)(CreatureMAX)));
      
      cminf = (float)(((int)(CreatureARACHAS)));
      
      output.PushBack((int)(RandNoiseF(seed, cmaxf, cminf)));
      
      
      for (i = 0; i*25<this.factory.level; i += 1) {
        if (RandNoiseF(seed+i, 1.0)<=0.10) {
          output.PushBack((int)(RandNoiseF(seed-i, cmaxf)));
        }
        
      }
      
      
    }
    
    return output;
  }
  
  public function destinations(spread: RER_ContractTargetsSpread): array<Vector> {
    var output: array<Vector>;
    var destinations: array<Vector>;
    var species: array<CreatureType>;
    var seed: int;
    var index: int;
    var i: int;
    destinations = RER_getClosestDestinationPoints(this.factory.origin, this.maxPointOfInterestDistance());
    species = this.speciesList();
    seed = this.seed+20;
    if (spread==RER_ContractTargetsSpread_GROUPED) {
      index = (int)(RandNoiseF(seed, (float)(destinations.Size())));
      i = 0;
      for (i = 0; i<species.Size(); i += 1) {
        output.PushBack(destinations[index]);
      }
      
    }
    else  {
      i = 0;
      
      index = (int)(RandNoiseF(seed, (float)(destinations.Size())));
      
      for (i = 0; i<species.Size(); i += 1) {
        index = Clamp((int)(index+(RandNoiseF(seed, 4.0)-2.0)), 0, destinations.Size()-1);
        
        NLOG("destinations(), seed = "+seed+1);
        
        NLOG("destinations(), index = "+index+" position = "+VecToString(destinations[index]));
        
        output.PushBack(destinations[index]);
        
        destinations.EraseFast(index);
      }
      
      
    }
    
    return output;
  }
  
  public function maxPointOfInterestDistance(): float {
    return StringToInt(RER_menuContract('RERcontractTargetMaxDistance'));
  }
  
  public function destinationRadius(): float {
    return StringToFloat(RER_menuContract('RERcontractTargetAreaRadius'));
  }
  
  public function getPrimaryTargetOffset(index: int): Vector {
    var seed: int;
    var radius: float;
    seed = this.seed+60+index;
    radius = this.destinationRadius();
    return VecRingRandStatic(seed, 0, radius*0.75);
  }
  
  public function damageDealtModifier(scaling: RER_ContractScaling): float {
    var modifier: float;
    modifier = 0.015*(this.factory.level*0.01);
    switch (scaling) {
      case RER_ContractScaling_MIXED:
      modifier *= 0.5;
      break;
      
      case RER_ContractScaling_ENEMY_COUNT:
      modifier *= 0;
      break;
      
      case RER_ContractScaling_DAMAGE_MODIFIERS:
      modifier *= 1;
      break;
    }
    return 1.0+modifier;
  }
  
  public function damageReceivedModifier(scaling: RER_ContractScaling): float {
    var modifier: float;
    modifier = 0.01*(this.factory.level*0.01);
    switch (scaling) {
      case RER_ContractScaling_MIXED:
      modifier *= 0.5;
      break;
      
      case RER_ContractScaling_ENEMY_COUNT:
      modifier *= 0;
      break;
      
      case RER_ContractScaling_DAMAGE_MODIFIERS:
      modifier *= 1;
      break;
    }
    return 1.0/(1.0+modifier);
  }
  
  public function enemyCountMultiplier(scaling: RER_ContractScaling): float {
    var modifier: float;
    modifier = 0.01*(this.factory.level*0.01);
    switch (scaling) {
      case RER_ContractScaling_MIXED:
      modifier *= 0.5;
      break;
      
      case RER_ContractScaling_ENEMY_COUNT:
      modifier *= 1;
      break;
      
      case RER_ContractScaling_DAMAGE_MODIFIERS:
      modifier *= 0;
      break;
    }
    return 1.0+modifier;
  }
  
}


function RER_getClosestDestinationPoints(starting_point: Vector, max_distance: float): array<Vector> {
  var sorter_data: array<SU_ArraySorterData>;
  var mappins: array<SEntityMapPinInfo>;
  var entities: array<CEntity>;
  var current_position: Vector;
  var current_distance: float;
  var current_region: string;
  var output: array<Vector>;
  var i: int;
  var commonMapManager: CCommonMapManager;
  var max_distance_squared: float;
  commonMapManager = theGame.GetCommonMapManager();
  current_region = AreaTypeToName(commonMapManager.GetCurrentArea());
  max_distance_squared = max_distance*max_distance;
  mappins = RER_getPointOfInterests();
  for (i = 0; i<mappins.Size(); i += 1) {
    current_position = mappins[i].entityPosition;
    
    current_distance = VecDistanceSquared2D(starting_point, current_position);
    
    if (current_distance>=max_distance_squared) {
      continue;
    }
    
    
    sorter_data.PushBack((new RER_ContractLocation in commonMapManager).init(current_position, current_distance));
  }
  
  theGame.GetEntitiesByTag('RER_contractPointOfInterest', entities);
  for (i = 0; i<entities.Size(); i += 1) {
    current_position = entities[i].GetWorldPosition();
    
    current_distance = VecDistanceSquared2D(starting_point, current_position);
    
    if (current_distance>=max_distance_squared) {
      continue;
    }
    
    
    sorter_data.PushBack((new RER_ContractLocation in commonMapManager).init(current_position, current_distance));
  }
  
  sorter_data = SU_sortArray(sorter_data);
  for (i = 0; i<sorter_data.Size(); i += 1) {
    output.PushBack(((RER_ContractLocation)(sorter_data[i])).position);
  }
  
  return output;
}


function RER_getPointOfInterests(): array<SEntityMapPinInfo> {
  var output: array<SEntityMapPinInfo>;
  var all_pins: array<SEntityMapPinInfo>;
  var i: int;
  all_pins = theGame.GetCommonMapManager().GetEntityMapPins(theGame.GetWorld().GetDepotPath());
  for (i = 0; i<all_pins.Size(); i += 1) {
    if (all_pins[i].entityType=='MonsterNest' || all_pins[i].entityType=='InfestedVineyard' || all_pins[i].entityType=='BanditCamp' || all_pins[i].entityType=='BanditCampfire' || all_pins[i].entityType=='BossAndTreasure' || all_pins[i].entityType=='RescuingTown' || all_pins[i].entityType=='DungeonCrawl' || all_pins[i].entityType=='Hideout' || all_pins[i].entityType=='Plegmund' || all_pins[i].entityType=='KnightErrant' || all_pins[i].entityType=='SignalingStake' || all_pins[i].entityType=='MonsterNest' || all_pins[i].entityType=='TreasureHuntMappin' || all_pins[i].entityType=='PointOfInterestMappin' || all_pins[i].entityType=='MonsterNestDisabled' || all_pins[i].entityType=='InfestedVineyardDisabled' || all_pins[i].entityType=='BanditCampDisabled' || all_pins[i].entityType=='BanditCampfireDisabled' || all_pins[i].entityType=='BossAndTreasureDisabled' || all_pins[i].entityType=='RescuingTownDisabled' || all_pins[i].entityType=='DungeonCrawlDisabled' || all_pins[i].entityType=='HideoutDisabled' || all_pins[i].entityType=='PlegmundDisabled' || all_pins[i].entityType=='KnightErrantDisabled' || all_pins[i].entityType=='SignalingStakeDisabled' || all_pins[i].entityType=='MonsterNestDisabled' || all_pins[i].entityType=='TreasureHuntMappinDisabled' || all_pins[i].entityType=='PointOfInterestMappinDisabled' || all_pins[i].entityType=='PointOfInterestMappinDisabled') {
      output.PushBack(all_pins[i]);
    }
    
  }
  
  return output;
}

statemachine class RER_ContractManager {
  var master: CRandomEncounters;
  
  function init(_master: CRandomEncounters) {
    this.master = _master;
    this.GotoState('Waiting');
  }
  
  public function pickedContractNoticeFromNoticeboard(errand_name: string) {
    this.GotoState('DialogChoice');
  }
  
  public function getNearbyNoticeboard(): W3NoticeBoard {
    var entities: array<CGameplayEntity>;
    var board: W3NoticeBoard;
    var i: int;
    FindGameplayEntitiesInRange(entities, thePlayer, 20, 1, , FLAG_ExcludePlayer, , 'W3NoticeBoard');
    board = (W3NoticeBoard)(entities[0]);
    return board;
  }
  
  public function getMaximumContractCount(): int {
    return 2+Min(this.getMaximumDifficulty()/30, 8);
  }
  
  public function startContract(factory: RER_ContractSeedFactory) {
    var contract: RER_Contract;
    var species: array<CreatureType>;
    var c: CreatureType;
    var idxdb8b1dcf3b464d40bbfe70e2c6ee0bbd: int;
    contract = (new RER_Contract in this).init(factory);
    this.master.storages.contract.has_ongoing_contract = true;
    this.master.storages.contract.active_contract = factory;
    this.master.storages.contract.killed_targets.Clear();
    species = contract.speciesList();
    for (idxdb8b1dcf3b464d40bbfe70e2c6ee0bbd = 0; idxdb8b1dcf3b464d40bbfe70e2c6ee0bbd < species.Size(); idxdb8b1dcf3b464d40bbfe70e2c6ee0bbd += 1) {
      c = species[idxdb8b1dcf3b464d40bbfe70e2c6ee0bbd];
      this.master.storages.contract.killed_targets.PushBack(false);
    }
    this.master.storages.contract.save();
    this.GotoState('Waiting');
  }
  
  public function hasOngoingContract(): bool {
    return this.master.storages.contract.has_ongoing_contract;
  }
  
  public function endOngoingContract() {
    this.master.storages.contract.has_ongoing_contract = false;
    this.master.storages.contract.save();
  }
  
  public function getOngoingContractFactory(): RER_ContractSeedFactory {
    return this.master.storages.contract.active_contract;
  }
  
  public function isTargetKilled(index: int): bool {
    if (index>=this.master.storages.contract.killed_targets.Size()) {
      return false;
    }
    
    return this.master.storages.contract.killed_targets[index];
  }
  
  public function setTargetKilled(index: int) {
    this.master.storages.contract.killed_targets[index] = true;
    this.master.storages.contract.save();
  }
  
  public function areAllTargetsKilled(): bool {
    var killed: bool;
    var idxe61ebc58cf124bb79ee2135b438afdaf: int;
    for (idxe61ebc58cf124bb79ee2135b438afdaf = 0; idxe61ebc58cf124bb79ee2135b438afdaf < this.master.storages.contract.killed_targets.Size(); idxe61ebc58cf124bb79ee2135b438afdaf += 1) {
      killed = this.master.storages.contract.killed_targets[idxe61ebc58cf124bb79ee2135b438afdaf];
      if (!killed) {
        return false;
      }
      
    }
    return true;
  }
  
  public function clearContractStorage() {
    this.master.storages.contract.completed_contracts.Clear();
    this.master.storages.contract.has_ongoing_contract = false;
    this.master.storages.contract.killed_targets.Clear();
    this.master.storages.contract.save();
  }
  
  public function completeOngoingContract() {
    var contract: RER_Contract;
    var has_bonus_rewards: bool;
    var total_crowns_amount: float;
    var total_reputation_points: float;
    var species_list: array<CreatureType>;
    var species: CreatureType;
    var idxb8bca344e0a84d07bbe085e630ad4a4a: int;
    var bestiary_entry: RER_BestiaryEntry;
    var strength: float;
    var enemy_count: int;
    var crowns_amount_settings: float;
    if (!this.hasOngoingContract()) {
      return ;
    }
    
    contract = (new RER_Contract in this).init(this.getOngoingContractFactory());
    NLOG("completeOngoingContract(), seed = "+contract.seed);
    has_bonus_rewards = contract.hasBonusRewards();
    total_crowns_amount = 0;
    total_reputation_points = 0;
    species_list = contract.speciesList();
    for (idxb8bca344e0a84d07bbe085e630ad4a4a = 0; idxb8bca344e0a84d07bbe085e630ad4a4a < species_list.Size(); idxb8bca344e0a84d07bbe085e630ad4a4a += 1) {
      species = species_list[idxb8bca344e0a84d07bbe085e630ad4a4a];
      bestiary_entry = this.master.bestiary.getEntry(this.master, species);
      
      if (has_bonus_rewards) {
        strength = bestiary_entry.ecosystem_delay_multiplier;
        enemy_count = bestiary_entry.getSpawnCount(this.master);
        crowns_amount_settings = (master.settings.crowns_amounts_by_encounter[EncounterType_CONTRACT]/100.0)*bestiary_entry.crowns_percentage*RandRangeF(1+contract.factory.level*0.01, 0.8+contract.factory.level*0.005)*bestiary_entry.ecosystem_delay_multiplier;
        total_crowns_amount += enemy_count*crowns_amount_settings;
      }
      
      
      total_reputation_points += MaxF(bestiary_entry.ecosystem_delay_multiplier*0.25, 1);
    }
    total_crowns_amount *= 1+(species_list.Size()*0.1);
    NLOG("completeOngoingContract(), total_crowns_amount = "+total_crowns_amount);
    NLOG("completeOngoingContract(), total_reputation_points = "+total_reputation_points);
    if (has_bonus_rewards) {
      thePlayer.AddMoney((int)(total_crowns_amount));
      thePlayer.DisplayItemRewardNotification('Crowns', (int)(total_crowns_amount));
      theSound.SoundEvent("gui_inventory_buy");
    }
    
    RER_addContractReputationFactValue(RoundF(total_reputation_points));
    thePlayer.DisplayHudMessage(GetLocStringByKeyExt("rer_contract_finished"));
    this.endOngoingContract();
  }
  
  public function getMaximumDifficulty(): int {
    return RER_getContractReputationFactValue()*1+1;
  }
  
  public function setPreferredDifficuty(difficulty: int) {
    if (difficulty<=0 || difficulty==this.getMaximumDifficulty()) {
      RER_removeContractPreferredDifficultyFact();
    }
    else  {
      RER_setContractPreferredDifficultyFactValue(difficulty);
      
    }
    
  }
  
  private function getPreferredDifficulty(): int {
    var prefered: int;
    var difficulty: int;
    prefered = RER_getContractPreferredDifficultyFactValue();
    difficulty = this.getMaximumDifficulty();
    if (prefered<=0 || prefered>difficulty) {
      return difficulty;
    }
    
    return prefered;
  }
  
  public function getSelectedDifficulty(): int {
    var difficulty: int;
    difficulty = this.getPreferredDifficulty();
    return difficulty;
  }
  
  public function contractHagglePreferredDifficultySelected(difficulty: int) {
    this.setPreferredDifficuty(difficulty);
    this.GotoState('DialogChoice');
  }
  
}

function RER_getContractReputationFactValue(): int {
  return Max(FactsQueryLatestValue("rer_contract_reputation_fact_id"), 0);
}


function RER_setContractReputationFactValue(value: int) {
  FactsSet("rer_contract_reputation_fact_id", Max(value, 0));
}


function RER_addContractReputationFactValue(gain: int) {
  RER_setContractReputationFactValue(RER_getContractReputationFactValue()+gain);
}


function RER_removeContractReputationFact() {
  FactsRemove("rer_contract_reputation_fact_id");
}


function RER_getContractPreferredDifficultyFactValue(): int {
  return FactsQueryLatestValue("rer_contract_preferred_difficulty_fact_id");
}


function RER_setContractPreferredDifficultyFactValue(value: int) {
  FactsSet("rer_contract_preferred_difficulty_fact_id", Max(value, 0));
}


function RER_removeContractPreferredDifficultyFact() {
  FactsRemove("rer_contract_preferred_difficulty_fact_id");
}


function RER_createIgnoreSlowBootFact() {
  FactsSet("rer_ignoreslowboot_fact_id", 1);
}


function RER_removeIgnoreSlowBootFact() {
  FactsRemove("rer_ignoreslowboot_fact_id");
}


function RER_doesIgnoreSlowBootFactExist(): bool {
  return FactsDoesExist("rer_ignoreslowboot_fact_id");
}

class RER_ContractModuleDialog extends CR4HudModuleDialog {
  var contract_manager: RER_ContractManager;
  
  function DialogueSliderDataPopupResult(value: float, optional isItemReward: bool) {
    super.DialogueSliderDataPopupResult(0, false);
    theGame.CloseMenu('PopupMenu');
    theInput.SetContext(thePlayer.GetExplorationInputContext());
    theGame.SetIsDialogOrCutscenePlaying(false);
    theGame.GetGuiManager().RequestMouseCursor(false);
    this.contract_manager.contractHagglePreferredDifficultySelected((int)(value));
  }
  
  function openDifficultySelectorWindow(contract_manager: RER_ContractManager) {
    var data: BettingSliderData;
    this.contract_manager = contract_manager;
    data = new BettingSliderData in this;
    data.ScreenPosX = 0.62;
    data.ScreenPosY = 0.65;
    data.SetMessageTitle(GetLocStringByKey("rer_difficulty"));
    data.dialogueRef = this;
    data.BlurBackground = false;
    data.minValue = 0;
    data.maxValue = contract_manager.getMaximumDifficulty();
    data.currentValue = contract_manager.getSelectedDifficulty();
    theGame.RequestMenu('PopupMenu', data);
  }
  
}

function RER_addNoticeboardInjectors() {
  var entities: array<CGameplayEntity>;
  var board: W3NoticeBoard;
  var i: int;
  FindGameplayEntitiesInRange(entities, thePlayer, 5000, 100, , FLAG_ExcludePlayer, , 'W3NoticeBoard');
  for (i = 0; i<entities.Size(); i += 1) {
    board = (W3NoticeBoard)(entities[i]);
    
    if (board && !SU_hasErrandInjectorWithTag(board, "RER_ContractErrandInjector")) {
      NLOG("adding errand injector to 1 board");
      board.addErrandInjector(new RER_ContractErrandInjector in board);
    }
    
  }
  
}


class RER_ContractErrandInjector extends SU_ErrandInjector {
  default tag = "RER_ContractErrandInjector";
  
  public function run(out board: W3NoticeBoard) {
    var reputation_system_enabled: bool;
    var master: CRandomEncounters;
    var can_inject_errand: bool;
    can_inject_errand = theGame.GetInGameConfigWrapper().GetVarValue('RERcontracts', 'RERnoticeboardErrands');
    if (!getRandomEncounters(master)) {
      NLOG("ERROR: could not get the RER entity for RER_ContractErrandInjector.");
      return ;
    }
    
    if (!can_inject_errand || !RER_modPowerIsContractSystemEnabled(master.getModPower())) {
      return ;
    }
    
    if (!SU_replaceFlawWithErrand(board, "rer_noticeboard_errand_1")) {
      if (board.HasTag('rer_errand')) {
        board.AddErrand(ErrandDetailsList("rer_noticeboard_errand_1", "injected_errand"), true);
      }
      
      return ;
    }
    
  }
  
  public function accepted(out board: W3NoticeBoard, errand_name: string) {
    var rer_entity: CRandomEncounters;
    if (errand_name!="rer_noticeboard_errand_1") {
      return ;
    }
    
    if (getRandomEncounters(rer_entity)) {
      rer_entity.contract_manager.pickedContractNoticeFromNoticeboard(errand_name);
    }
    
  }
  
  private function hideAllQuestErrands(out board: W3NoticeBoard) {
    var card: CDrawableComponent;
    var i: int;
    for (i = board.activeErrands.Size(); i>=0; i -= 1) {
      if (board.activeErrands[i].newQuestFact=="flaw" || board.activeErrands[i].newQuestFact=="injected_errand") {
        continue;
      }
      
      
      board.activeErrands.EraseFast(i);
    }
    
  }
  
}

function RER_contractRewardTypeToItemName(type: RER_ContractRewardType): name {
  var item_name: name;
  switch (type) {
    case ContractRewardType_GEAR:
    item_name = 'rer_token_gear';
    break;
    
    case ContractRewardType_MATERIALS:
    item_name = 'rer_token_materials';
    break;
    
    case ContractRewardType_CONSUMABLES:
    item_name = 'rer_token_consumables';
    break;
    
    case ContractRewardType_EXPERIENCE:
    item_name = 'rer_token_experience';
    break;
    
    case ContractRewardType_GOLD:
    item_name = 'rer_token_gold';
    break;
  }
  return item_name;
}


latent function RER_applyLootFromContractTokenName(master: CRandomEncounters, inventory: CInventoryComponent, item: name, optional count: int) {
  var category: RER_LootCategory;
  var loot_tables: array<name>;
  var index: int;
  count = Max(1, count);
  inventory.RemoveItemByName(item, count);
  if (item=='rer_token_experience') {
    index = RER_getPlayerLevel()*10;
    GetWitcherPlayer().AddPoints(EExperiencePoint, index, true);
    thePlayer.DisplayItemRewardNotification('experience', index);
    return ;
  }
  
  switch (item) {
    case 'rer_token_gear':
    category = LootCategory_Gear;
    theSound.SoundEvent("gui_inventory_weapon_attach");
    break;
    
    case 'rer_token_consumables':
    category = LootCategory_Consumables;
    theSound.SoundEvent("gui_pick_up_herbs");
    break;
    
    case 'rer_token_gold':
    category = LootCategory_Valuables;
    theSound.SoundEvent("gui_inventory_buy");
    break;
    
    case 'rer_token_materials':
    category = LootCategory_Materials;
    theSound.SoundEvent("gui_inventory_potion_attach");
    break;
  }
  while (count>0) {
    count -= 1;
    NLOG("RER_applyLootFromContractTokenName, category = "+category);
    master.loot_manager.rollAndGiveItemsTo(inventory, 1.0, , category);
  }
  
}


function RER_getLocalizedRewardType(type: RER_ContractRewardType): string {
  var item_name: string;
  item_name = NameToString(RER_contractRewardTypeToItemName(type))+"_short";
  return GetLocStringByKey(item_name);
}


function RER_getLocalizedRewardTypesFromFlag(flag: RER_ContractRewardType): string {
  var output: string;
  if (RER_flagEnabled(flag, ContractRewardType_GEAR)) {
    output += RER_getLocalizedRewardType(ContractRewardType_GEAR);
  }
  
  if (RER_flagEnabled(flag, ContractRewardType_CONSUMABLES)) {
    if (StrLen(output)>0) {
      output += ", ";
    }
    
    output += RER_getLocalizedRewardType(ContractRewardType_CONSUMABLES);
  }
  
  if (RER_flagEnabled(flag, ContractRewardType_EXPERIENCE)) {
    if (StrLen(output)>0) {
      output += ", ";
    }
    
    output += RER_getLocalizedRewardType(ContractRewardType_EXPERIENCE);
  }
  
  if (RER_flagEnabled(flag, ContractRewardType_GOLD)) {
    if (StrLen(output)>0) {
      output += ", ";
    }
    
    output += RER_getLocalizedRewardType(ContractRewardType_GOLD);
  }
  
  if (RER_flagEnabled(flag, ContractRewardType_MATERIALS)) {
    if (StrLen(output)>0) {
      output += ", ";
    }
    
    output += RER_getLocalizedRewardType(ContractRewardType_MATERIALS);
  }
  
  return output;
}


function RER_getRandomContractRewardTypeFromFlag(flag: RER_ContractRewardType, rng: RandomNumberGenerator): RER_ContractRewardType {
  var enabled_types: array<RER_ContractRewardType>;
  var index: int;
  if (RER_flagEnabled(flag, ContractRewardType_GEAR)) {
    enabled_types.PushBack(ContractRewardType_GEAR);
  }
  
  if (RER_flagEnabled(flag, ContractRewardType_CONSUMABLES)) {
    enabled_types.PushBack(ContractRewardType_CONSUMABLES);
  }
  
  if (RER_flagEnabled(flag, ContractRewardType_EXPERIENCE)) {
    enabled_types.PushBack(ContractRewardType_EXPERIENCE);
  }
  
  if (RER_flagEnabled(flag, ContractRewardType_GOLD)) {
    enabled_types.PushBack(ContractRewardType_GOLD);
  }
  
  if (RER_flagEnabled(flag, ContractRewardType_MATERIALS)) {
    enabled_types.PushBack(ContractRewardType_MATERIALS);
  }
  
  index = (int)(rng.nextRange(enabled_types.Size(), 0));
  return enabled_types[index];
}


function RER_getAllowedContractRewardsMaskFromRegion(): RER_ContractRewardType {
  var region: string;
  var position: Vector;
  region = SUH_getCurrentRegion();
  NLOG("RER_getAllowedContractRewardsMaskFromRegion, region = "+region);
  if (region=="prolog_village_winter") {
    region = "prolog_village";
  }
  
  if (region=="no_mans_land") {
    position = thePlayer.GetWorldPosition();
    if (position.X<1150) {
      return ContractRewardType_GOLD|ContractRewardType_GEAR;
    }
    else  {
      return ContractRewardType_EXPERIENCE|ContractRewardType_MATERIALS;
      
    }
    
  }
  else if (region=="novigrad") {
    return ContractRewardType_GOLD|ContractRewardType_GEAR;
    
  }
  else if (region=="skellige") {
    return ContractRewardType_CONSUMABLES|ContractRewardType_GEAR;
    
  }
  else if (region=="bob") {
    return ContractRewardType_CONSUMABLES|ContractRewardType_GOLD;
    
  }
  
  return ContractRewardType_ALL;
}


function RER_getRandomAllowedRewardType(contract_manager: RER_ContractManager, noticeboard_identifier: RER_NoticeboardIdentifier): RER_ContractRewardType {
  var allowed_reward: RER_ContractRewardType;
  var rng: RandomNumberGenerator;
  var roll: int;
  rng = (new RandomNumberGenerator in contract_manager).setSeed(RER_identifierToInt(noticeboard_identifier.identifier)).useSeed(true);
  allowed_reward = ContractRewardType_NONE;
  roll = (int)(rng.nextRange(15, 0));
  switch (roll) {
    case 0:
    allowed_reward = ContractRewardType_GEAR;
    break;
    
    case 1:
    allowed_reward = ContractRewardType_MATERIALS;
    break;
    
    case 2:
    allowed_reward = ContractRewardType_EXPERIENCE;
    break;
    
    case 3:
    allowed_reward = ContractRewardType_CONSUMABLES;
    break;
    
    case 4:
    allowed_reward = ContractRewardType_GOLD;
    break;
  }
  NLOG("RER_getRandomAllowedRewardType, allowed_reward = "+allowed_reward);
  return allowed_reward;
}


function RER_getRandomJewelName(rng: RandomNumberGenerator): name {
  var names: array<name>;
  var output: name;
  names.PushBack('Ruby');
  names.PushBack('Amber');
  names.PushBack('Amethyst');
  names.PushBack('Diamond');
  names.PushBack('Emerald');
  names.PushBack('Sapphire');
  output = names[(int)(rng.nextRange(names.Size(), 0))];
  return output;
}

enum RER_SpeciesTypes {
  SpeciesTypes_BEASTS = 0,
  SpeciesTypes_INSECTOIDS = 1,
  SpeciesTypes_NECROPHAGES = 2,
  SpeciesTypes_OGROIDS = 3,
  SpeciesTypes_SPECTERS = 4,
  SpeciesTypes_CURSED = 5,
  SpeciesTypes_DRACONIDS = 6,
  SpeciesTypes_ELEMENTA = 7,
  SpeciesTypes_HYBRIDS = 8,
  SpeciesTypes_RELICTS = 9,
  SpeciesTypes_VAMPIRES = 10,
  SpeciesTypes_MAX = 11,
  SpeciesTypes_NONE = 12,
}


function RER_getRandomSpeciesType(): RER_SpeciesTypes {
  return (RER_SpeciesTypes)(RandRange(SpeciesTypes_MAX));
}


function RER_getSeededRandomSpeciesType(rng: RandomNumberGenerator): RER_SpeciesTypes {
  var max: float;
  max = ((float)(((int)(SpeciesTypes_MAX))));
  return (RER_SpeciesTypes)(RoundF(rng.nextRange(max, 0)));
}


function RER_getSeededRandomEasySpeciesType(rng: RandomNumberGenerator): RER_SpeciesTypes {
  var max: float;
  if (RER_playerUsesEnhancedEditionRedux()) {
    max = ((float)(((int)(SpeciesTypes_SPECTERS))));
  }
  else  {
    max = ((float)(((int)(SpeciesTypes_CURSED))));
    
  }
  
  return (RER_SpeciesTypes)(RoundF(rng.nextRange(max, 0)));
}


latent function RER_getSeededRandomCreatureType(master: CRandomEncounters, difficulty_level: RER_ContractDifficultyLevel, rng: RandomNumberGenerator): CreatureType {
  var creature_types: array<CreatureType>;
  var bestiary_entry: RER_BestiaryEntry;
  var maxmimum_strength: float;
  var i: int;
  var current_region: string;
  var manager: CWitcherJournalManager;
  var can_spawn_creature: bool;
  master.spawn_roller.reset();
  maxmimum_strength = MaxF(difficulty_level.value, 5);
  current_region = SUH_getCurrentRegion();
  if (master.settings.only_known_bestiary_creatures) {
    manager = theGame.GetJournalManager();
  }
  
  for (i = 0; i<CreatureMAX; i += 1) {
    bestiary_entry = master.bestiary.getEntry(master, i);
    
    if (master.settings.only_known_bestiary_creatures) {
      can_spawn_creature = bestiaryCanSpawnEnemyTemplateList(master.bestiary.entries[i].template_list, manager);
      if (!can_spawn_creature) {
        continue;
      }
      
    }
    
    
    if (bestiary_entry.ecosystem_delay_multiplier>maxmimum_strength) {
      continue;
    }
    
    
    if (!RER_isRegionConstraintValid(bestiary_entry.region_constraint, current_region)) {
      continue;
    }
    
    
    creature_types.PushBack(i);
  }
  
  return creature_types[(int)(rng.nextRange(creature_types.Size(), 0))];
}


function RER_getSpeciesLocalizedString(species: RER_SpeciesTypes): string {
  var output: string;
  switch (species) {
    case SpeciesTypes_BEASTS:
    output = GetLocStringByKey("rer_species_beasts");
    break;
    
    case SpeciesTypes_CURSED:
    output = GetLocStringByKey("rer_species_cursed");
    break;
    
    case SpeciesTypes_DRACONIDS:
    output = GetLocStringByKey("rer_species_draconids");
    break;
    
    case SpeciesTypes_ELEMENTA:
    output = GetLocStringByKey("rer_species_elementa");
    break;
    
    case SpeciesTypes_HYBRIDS:
    output = GetLocStringByKey("rer_species_hybrids");
    break;
    
    case SpeciesTypes_INSECTOIDS:
    output = GetLocStringByKey("rer_species_insectoids");
    break;
    
    case SpeciesTypes_NECROPHAGES:
    output = GetLocStringByKey("rer_species_necrophages");
    break;
    
    case SpeciesTypes_OGROIDS:
    output = GetLocStringByKey("rer_species_ogroids");
    break;
    
    case SpeciesTypes_RELICTS:
    output = GetLocStringByKey("rer_species_relicts");
    break;
    
    case SpeciesTypes_SPECTERS:
    output = GetLocStringByKey("rer_species_specters");
    break;
    
    case SpeciesTypes_VAMPIRES:
    output = GetLocStringByKey("rer_species_vampires");
    break;
  }
  return output;
}


function RER_getSpeciesFromLocalizedString(localized_string: string): RER_SpeciesTypes {
  if (StrContains(localized_string, GetLocStringByKey("rer_species_beasts"))) {
    return SpeciesTypes_BEASTS;
  }
  
  if (StrContains(localized_string, GetLocStringByKey("rer_species_cursed"))) {
    return SpeciesTypes_CURSED;
  }
  
  if (StrContains(localized_string, GetLocStringByKey("rer_species_draconids"))) {
    return SpeciesTypes_DRACONIDS;
  }
  
  if (StrContains(localized_string, GetLocStringByKey("rer_species_elementa"))) {
    return SpeciesTypes_ELEMENTA;
  }
  
  if (StrContains(localized_string, GetLocStringByKey("rer_species_hybrids"))) {
    return SpeciesTypes_HYBRIDS;
  }
  
  if (StrContains(localized_string, GetLocStringByKey("rer_species_insectoids"))) {
    return SpeciesTypes_INSECTOIDS;
  }
  
  if (StrContains(localized_string, GetLocStringByKey("rer_species_necrophages"))) {
    return SpeciesTypes_NECROPHAGES;
  }
  
  if (StrContains(localized_string, GetLocStringByKey("rer_species_ogroids"))) {
    return SpeciesTypes_OGROIDS;
  }
  
  if (StrContains(localized_string, GetLocStringByKey("rer_species_relicts"))) {
    return SpeciesTypes_RELICTS;
  }
  
  if (StrContains(localized_string, GetLocStringByKey("rer_species_specters"))) {
    return SpeciesTypes_SPECTERS;
  }
  
  if (StrContains(localized_string, GetLocStringByKey("rer_species_vampires"))) {
    return SpeciesTypes_VAMPIRES;
  }
  
  return SpeciesTypes_NONE;
}

function RER_menuContract(item: name): string {
  return RER_menu('RERcontracts', item);
}


enum RER_ContractScaling {
  RER_ContractScaling_MIXED = 0,
  RER_ContractScaling_ENEMY_COUNT = 1,
  RER_ContractScaling_DAMAGE_MODIFIERS = 2,
}


function RER_getContractDifficultyScaling(): RER_ContractScaling {
  return StringToInt(RER_menuContract('RERcontractDifficultyScaling'));
}


enum RER_ContractTargetsSpread {
  RER_ContractTargetsSpread_SPREAD = 0,
  RER_ContractTargetsSpread_GROUPED = 1,
}


function RER_getContractTargetsSpread(): RER_ContractTargetsSpread {
  return StringToInt(RER_menuContract('RERcontractTargetsSpread'));
}


function RER_getHoursBeforeNewContract(): int {
  return StringToInt(RER_menuContract('RERhoursBeforeNewContracts'));
}


function RER_getAllowBackToCamp(): bool {
  return RER_menuContract('RERallowBackToCamp');
}


struct RER_NoticeboardIdentifier {
  var identifier: string;
  
}


struct RER_ContractIdentifier {
  var identifier: string;
  
}


function RER_identifierToInt(identifier: string): int {
  var segment: string;
  var sub: string;
  var output: int;
  segment = identifier;
  while (StrLen(segment)>0) {
    if (StrFindFirst(segment, "-")>=0) {
      sub = StrBeforeFirst(segment, "-");
    }
    else  {
      sub = segment;
      
    }
    
    output += StringToInt(sub);
    segment = StrMid(segment, StrLen(sub)+1);
  }
  
  return output;
}


struct RER_GenerationTime {
  var time: float;
  
}


enum RER_ContractDifficulty {
  ContractDifficulty_EASY = 0,
  ContractDifficulty_MEDIUM = 1,
  ContractDifficulty_HARD = 2,
}


struct RER_ContractDifficultyLevel {
  var value: int;
  
}


struct RER_ContractGenerationData {
  var starting_point: Vector;
  
  var difficulty: RER_ContractDifficulty;
  
  var difficulty_level: RER_ContractDifficultyLevel;
  
  var creature_type: CreatureType;
  
  var identifier: RER_ContractIdentifier;
  
  var noticeboard_identifier: RER_NoticeboardIdentifier;
  
  var region_name: string;
  
  var rng_seed: int;
  
}


enum RER_ContractEventType {
  ContractEventType_NEST = 0,
  ContractEventType_HORDE = 1,
  ContractEventType_BOSS = 2,
}


enum RER_ContractRewardType {
  ContractRewardType_NONE = 0,
  ContractRewardType_GEAR = 1,
  ContractRewardType_MATERIALS = 2,
  ContractRewardType_EXPERIENCE = 4,
  ContractRewardType_CONSUMABLES = 8,
  ContractRewardType_GOLD = 16,
  ContractRewardType_ALL = 32,
}


enum RER_ContractRewardOption {
  RER_ContractRewardOption_CROWNS = 0,
  RER_ContractRewardOption_TOKENS = 1,
}


function RER_getContractRewardOption(): RER_ContractRewardOption {
  return StringToInt(theGame.GetInGameConfigWrapper().GetVarValue('RERcontracts', 'RERcontractsRewardOption'));
}


struct RER_ContractRepresentation {
  var destination_point: Vector;
  
  var destination_radius: float;
  
  var event_type: RER_ContractEventType;
  
  var difficulty_level: RER_ContractDifficultyLevel;
  
  var creature_type: CreatureType;
  
  var identifier: RER_ContractIdentifier;
  
  var noticeboard_identifier: RER_NoticeboardIdentifier;
  
  var reward_type: int;
  
  var region_name: string;
  
  var rng_seed: int;
  
}


class RER_ContractLocation extends SU_ArraySorterData {
  var position: Vector;
  
  public function init(position: Vector, distance: float): RER_ContractLocation {
    this.position = position;
    this.value = distance;
    return this;
  }
  
}


struct RER_NoticeboardReputation {
  var noticeboard_identifier: RER_NoticeboardIdentifier;
  
  var reputation: float;
  
}

state DialogChoice in RER_ContractManager {
  var camera: SU_StaticCamera;
  
  var completed: bool;
  
  event OnEnterState(previous_state_name: name) {
    var menu_distance_value: float;
    super.OnEnterState(previous_state_name);
    NLOG("RER_ContractManager - state DialogChoice");
    this.DialogChoice_main();
  }
  
  private var menu_distance_value: float;
  
  entry function DialogChoice_main() {
    this.completed = false;
    this.startNoticeboardCutscene();
    while (!this.completed) {
      this.DialogChoice_prepareAndDisplayDialogChoices();
    }
    
  }
  
  private latent function startNoticeboardCutscene() {
    var noticeboard: W3NoticeBoard;
    RER_tutorialTryShowNoticeboard();
    REROL_mhm();
    Sleep(0.1);
    this.camera = SU_getStaticCamera();
    noticeboard = parent.getNearbyNoticeboard();
    this.camera.teleportAndLookAt(noticeboard.GetWorldPosition()+VecFromHeading(noticeboard.GetHeading())*2+Vector(0, 0, 1.5), noticeboard.GetWorldPosition()+Vector(0, 0, 1.5));
    theGame.FadeOut(0.2);
    this.camera.start();
    theGame.FadeInAsync(0.4);
  }
  
  private latent function DialogChoice_prepareAndDisplayDialogChoices() {
    var contracts_count: int;
    var noticeboard: W3NoticeBoard;
    var difficulty: int;
    var contracts: array<RER_Contract>;
    var timeoffset: int;
    var i: int;
    var factory: RER_ContractSeedFactory;
    var contract: RER_Contract;
    var choices: array<SSceneChoice>;
    var species_list: array<CreatureType>;
    var line: string;
    var require_comma: bool;
    var species: CreatureType;
    var idxd0a9bbe9b3b2493cb8db14f52bbd3f17: int;
    var has_bonus_rewards: bool;
    contracts_count = parent.getMaximumContractCount();
    noticeboard = parent.getNearbyNoticeboard();
    difficulty = parent.getSelectedDifficulty();
    timeoffset = GameTimeHours(theGame.CalculateTimePlayed())/RER_getHoursBeforeNewContract();
    for (i = contracts_count; i>0; i -= 1) {
      factory = RER_ContractSeedFactory(noticeboard.GetWorldPosition(), difficulty, i, SUH_getCurrentRegion(), timeoffset);
      
      contract = new RER_Contract in parent;
      
      contract.init(factory);
      
      contracts.PushBack(contract);
    }
    
    choices.PushBack(SSceneChoice(StrReplace(GetLocStringByKey("rer_select_difficulty"), "{{difficulty}}", difficulty), false, true, false, DialogAction_EXIT, 'SelectDifficulty'));
    for (i = 0; i<contracts.Size(); i += 1) {
      contract = contracts[i];
      
      species_list = contract.speciesList();
      
      line = "["+contract.difficulty()+"-"+(i+1)+"] ";
      
      require_comma = false;
      
      for (idxd0a9bbe9b3b2493cb8db14f52bbd3f17 = 0; idxd0a9bbe9b3b2493cb8db14f52bbd3f17 < species_list.Size(); idxd0a9bbe9b3b2493cb8db14f52bbd3f17 += 1) {
        species = species_list[idxd0a9bbe9b3b2493cb8db14f52bbd3f17];
        if (require_comma) {
          line += ", ";
        }
        
        
        require_comma = true;
        
        line += upperCaseFirstLetter(getCreatureNameFromCreatureType(parent.master.bestiary, species));
      }
      
      has_bonus_rewards = contract.hasBonusRewards();
      
      if (has_bonus_rewards) {
        line += " ("+GetLocStringByKey('rer_contract_crowns_reward')+")";
      }
      
      
      choices.PushBack(SSceneChoice(upperCaseFirstLetter(line), has_bonus_rewards, false, false, DialogAction_MONSTERCONTRACT, 'StartContract'));
    }
    
    choices.PushBack(SSceneChoice(GetLocStringByKey("rer_cancel"), false, true, false, DialogAction_EXIT, 'Cancel'));
    this.DialogChoice_displayDialogChoices(choices, contracts);
  }
  
  private latent function DialogChoice_displayDialogChoices(choices: array<SSceneChoice>, contracts: array<RER_Contract>) {
    var response: SSceneChoice;
    var haggle: RER_ContractModuleDialog;
    var offset: int;
    var i: int;
    var selected_contract: RER_Contract;
    Sleep(0.25);
    response = SU_setDialogChoicesAndWaitForResponse(choices);
    SU_closeDialogChoiceInterface();
    if (!IsNameValid(response.playGoChunk) || response.playGoChunk=='Cancel') {
      this.camera.Stop();
      Sleep(0.25);
      parent.GotoState('Waiting');
      return ;
    }
    
    if (response.playGoChunk=='SelectDifficulty') {
      this.camera.Stop();
      haggle = new RER_ContractModuleDialog in this;
      haggle.openDifficultySelectorWindow(parent);
      parent.GotoState('Waiting');
      return ;
    }
    
    offset = 1;
    NLOG("DialogChoice_displayDialogChoices"+response.description);
    for (i = 0; i<choices.Size(); i += 1) {
      if (StrContains(response.description, choices[i].description)) {
        selected_contract = contracts[i-1];
        if (selected_contract) {
          this.completed = true;
          theSound.SoundEvent("gui_ingame_quest_active");
          this.camera.Stop();
          NHUD(GetLocStringByKey('rer_contract_started'));
          parent.startContract(selected_contract.factory);
          return ;
        }
        
      }
      
    }
    
    NDEBUG("RER ERROR: Unable to get creature_type from dialogue choices");
  }
  
  private function openMapMenuForContract(contract: RER_Contract) {
    var initData: W3MapInitData;
    initData = new W3MapInitData in this;
    initData.ignoreSaveSystem = true;
    initData.setDefaultState('FastTravel');
    theGame.RequestMenuWithBackground('MapMenu', 'CommonMenu', initData);
  }
  
}

state Processing in RER_ContractManager {
  var target_encounters: array<RER_ContractTargetEncounter>;
  
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_ContractManager - Processing");
    this.Processing_main();
  }
  
  entry function Processing_main() {
    var contract: RER_Contract;
    var finished: bool;
    if (!parent.hasOngoingContract()) {
      parent.GotoState('Waiting');
      return ;
    }
    
    contract = (new RER_Contract in parent).init(parent.getOngoingContractFactory());
    this.verifyContractRegion();
    finished = this.waitForPlayerToFinishContract(contract);
    this.cleanupEncounters();
    if (finished) {
      this.promptBackToCamp(contract);
      Sleep(2);
      parent.completeOngoingContract();
    }
    
    parent.GotoState('Waiting');
  }
  
  function verifyContractRegion() {
    if (!parent.hasOngoingContract()) {
      return ;
    }
    
    if (SUH_isPlayerInRegion(parent.master.storages.contract.active_contract.region_name)) {
      return ;
    }
    
    NHUD(StrReplace(GetLocStringByKey("rer_strayed_too_far_cancelled"), "{{thing}}", StrLower(GetLocStringByKey("rer_contract"))));
    theSound.SoundEvent("gui_global_denied");
    parent.endOngoingContract();
  }
  
  latent function promptBackToCamp(contract: RER_Contract) {
    var confirmation: RER_ContractBackToCampConfirmation;
    if (!RER_getAllowBackToCamp()) {
      return ;
    }
    
    confirmation = new RER_ContractBackToCampConfirmation in this;
    NLOG("contract.factory.origin = "+VecToString(contract.factory.origin));
    confirmation.open(contract.factory.origin);
  }
  
  latent function waitForPlayerToFinishContract(contract: RER_Contract): bool {
    var primary_targets: array<CreatureType>;
    var locations: array<Vector>;
    var i: int;
    var target_encounter: RER_ContractTargetEncounter;
    var destination_radius: float;
    var player_position: Vector;
    var idx4b97b04a99dc42a785aacf0781566676: int;
    primary_targets = contract.speciesList();
    locations = contract.destinations(RER_getContractTargetsSpread());
    SU_removeCustomPinByTag("RER_contract_target");
    i = 0;
    for (i = 0; i<primary_targets.Size(); i += 1) {
      target_encounter = (new RER_ContractTargetEncounter in this).init(i, locations[i], primary_targets[i], parent);
      
      target_encounter.createOneliner();
      
      target_encounter.createMapPin(contract);
      
      this.target_encounters.PushBack(target_encounter);
    }
    
    SU_updateMinimapPins();
    theSound.SoundEvent("gui_hubmap_mark_pin");
    while (true) {
      if (parent.areAllTargetsKilled()) {
        return true;
      }
      
      destination_radius = contract.destinationRadius();
      player_position = thePlayer.GetWorldPosition();
      for (idx4b97b04a99dc42a785aacf0781566676 = 0; idx4b97b04a99dc42a785aacf0781566676 < this.target_encounters.Size(); idx4b97b04a99dc42a785aacf0781566676 += 1) {
        target_encounter = this.target_encounters[idx4b97b04a99dc42a785aacf0781566676];
        if (target_encounter.isSpawnedAndKilled()) {
          parent.setTargetKilled(target_encounter.index);
          target_encounter.removeMapPin();
          SU_updateMinimapPins();
        }
        
        
        if (target_encounter.canSpawn(player_position, destination_radius)) {
          if (!parent.master.hasJustBooted()) {
            theGame.SaveGame(SGT_QuickSave, -1);
          }
          
          theSound.SoundEvent("gui_ingame_new_journal");
          target_encounter.removeOneliner();
          thePlayer.DisplayHudMessage(StrReplace(GetLocStringByKeyExt("rer_kill_target"), "{{type}}", getCreatureNameFromCreatureType(parent.master.bestiary, target_encounter.species)));
          target_encounter.spawn(contract);
          Sleep(0.5);
        }
        
      }
      Sleep(5);
    }
    
    return parent.areAllTargetsKilled();
  }
  
  latent function cleanupEncounters() {
    var target_encounter: RER_ContractTargetEncounter;
    var idxc610f35fbab343f29fce50562db1d9a1: int;
    for (idxc610f35fbab343f29fce50562db1d9a1 = 0; idxc610f35fbab343f29fce50562db1d9a1 < this.target_encounters.Size(); idxc610f35fbab343f29fce50562db1d9a1 += 1) {
      target_encounter = this.target_encounters[idxc610f35fbab343f29fce50562db1d9a1];
      target_encounter.cleanupEncounter();
    }
    this.target_encounters.Clear();
    SU_updateMinimapPins();
  }
  
  event OnLeaveState(nextStateName: name) {
    var target_encounter: RER_ContractTargetEncounter;
    var idx09cd202fbd694f4a9fd656c3ede9b9e4: int;
    for (idx09cd202fbd694f4a9fd656c3ede9b9e4 = 0; idx09cd202fbd694f4a9fd656c3ede9b9e4 < this.target_encounters.Size(); idx09cd202fbd694f4a9fd656c3ede9b9e4 += 1) {
      target_encounter = this.target_encounters[idx09cd202fbd694f4a9fd656c3ede9b9e4];
      target_encounter.removeOneliner();
    }
    SU_removeCustomPinByTag("RER_contract_target");
  }
  
}


class RER_ContractTargetEncounter {
  var manager: RER_ContractManager;
  
  var index: int;
  
  var location: Vector;
  
  var species: CreatureType;
  
  var encounter: RandomEncountersReworkedHuntingGroundEntity;
  
  var oneliner: RER_Oneliner;
  
  var map_pin: SU_MapPin;
  
  public function init(index: int, location: Vector, species: CreatureType, manager: RER_ContractManager): RER_ContractTargetEncounter {
    this.index = index;
    this.location = location;
    this.manager = manager;
    this.species = species;
    NLOG("new RER_ContractTargetEncounter, index="+this.index+", location="+VecToString(this.location)+"species="+this.species);
    return this;
  }
  
  public function createOneliner() {
    if (!RER_menu('RERoptionalFeatures', 'RERonelinersContract')) {
      return ;
    }
    
    this.oneliner = RER_oneliner(" <img src='img://icons/quests/monsterhunt.png' vspace='-10' />", this.location);
  }
  
  public function createMapPin(contract: RER_Contract) {
    var map_pin: SU_MapPin;
    map_pin = new SU_MapPin in this;
    map_pin.tag = "RER_contract_target";
    map_pin.pin_tag = 'RER_contract_target';
    map_pin.is_fast_travel = false;
    map_pin.position = this.location;
    map_pin.description = GetLocStringByKey("rer_mappin_regular_description");
    map_pin.label = GetLocStringByKey("rer_mappin_regular_title");
    map_pin.type = "MonsterQuest";
    map_pin.filtered_type = "MonsterQuest";
    map_pin.radius = contract.destinationRadius();
    map_pin.region = SUH_getCurrentRegion();
    map_pin.appears_on_minimap = theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERminimapMarkerBounties');
    SUMP_addCustomPin(map_pin);
    this.map_pin = map_pin;
  }
  
  public function canSpawn(player_position: Vector, radius: float): bool {
    return !this.isSpawned() && !this.isEncounterFinished() && this.isPlayerInArea(player_position, radius);
  }
  
  public function isEncounterFinished(): bool {
    return this.isTargetKilledStorage() || this.isSpawnedAndKilled();
  }
  
  public function isSpawnedAndKilled(): bool {
    return this.isSpawned() && this.encounter.GetCurrentStateName()=='Ending';
  }
  
  private function isPlayerInArea(player_position: Vector, radius: float): bool {
    return VecDistanceSquared2D(player_position, location)<=radius*radius;
  }
  
  private function isTargetKilledStorage(): bool {
    return this.manager.isTargetKilled(this.index);
  }
  
  private function isSpawned(): bool {
    if (this.encounter) {
      return true;
    }
    
    return false;
  }
  
  public latent function spawn(contract: RER_Contract) {
    this.spawnPrimaryTarget(contract, this.species, this.location);
  }
  
  latent function spawnPrimaryTarget(contract: RER_Contract, species: CreatureType, position: Vector) {
    var encounter: RandomEncountersReworkedHuntingGroundEntity;
    getGroundPosition(position);
    encounter = this.spawnEncounter(contract, species, position);
    this.encounter = encounter;
  }
  
  private latent function spawnEncounter(contract: RER_Contract, species: CreatureType, position: Vector): RandomEncountersReworkedHuntingGroundEntity {
    var bestiary_entry: RER_BestiaryEntry;
    var count: int;
    var entities: array<CEntity>;
    var rer_entity_template: CEntityTemplate;
    var rer_entity: RandomEncountersReworkedHuntingGroundEntity;
    bestiary_entry = this.manager.master.bestiary.getEntry(this.manager.master, species);
    count = RoundF(((float)(bestiary_entry.getSpawnCount(this.manager.master)))*contract.enemyCountMultiplier(RER_getContractDifficultyScaling()));
    entities = bestiary_entry.spawn(this.manager.master, position, count, , EncounterType_CONTRACT, RER_BESF_NO_BESTIARY_FEATURE|RER_BESF_NO_PERSIST, 'RandomEncountersReworked_ContractCreature', 10000, this.getDamageModifiers(contract));
    rer_entity_template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\rer_hunting_ground_entity.w2ent", true));
    rer_entity = (RandomEncountersReworkedHuntingGroundEntity)(theGame.CreateEntity(rer_entity_template, position, thePlayer.GetWorldRotation()));
    rer_entity.manual_destruction = true;
    rer_entity.startEncounter(this.manager.master, entities, bestiary_entry);
    return rer_entity;
  }
  
  private function getDamageModifiers(contract: RER_Contract): SU_BaseDamageModifier {
    var scaling: RER_ContractScaling;
    var damage_modifier: SU_BaseDamageModifier;
    scaling = RER_getContractDifficultyScaling();
    damage_modifier = new SU_BaseDamageModifier in this.manager;
    damage_modifier.damage_received_modifier = contract.damageReceivedModifier(scaling);
    damage_modifier.damage_dealt_modifier = contract.damageDealtModifier(scaling);
    NLOG("contract, getDamageModifiers, damage_received_modifier ="+damage_modifier.damage_received_modifier);
    NLOG("contract, getDamageModifiers, damage_dealt_modifier ="+damage_modifier.damage_dealt_modifier);
    return damage_modifier;
  }
  
  public latent function cleanupEncounter() {
    if (!this.isSpawned()) {
      return ;
    }
    
    if (this.encounter) {
      this.encounter.clean();
    }
    
    this.removeOneliner();
    this.removeMapPin();
  }
  
  public function removeOneliner() {
    if (this.oneliner) {
      this.oneliner.unregister();
      delete this.oneliner;
    }
    
  }
  
  public function removeMapPin() {
    if (this.map_pin) {
      SU_removeCustomPin(this.map_pin);
      delete this.map_pin;
    }
    
  }
  
}

state Waiting in RER_ContractManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_ContractManager - state WAITING");
    this.Waiting_main();
  }
  
  entry function Waiting_main() {
    if (parent.hasOngoingContract()) {
      parent.GotoState('Processing');
    }
    else  {
      SU_removeCustomPinByTag("RER_contract_target");
      
      SU_updateMinimapPins();
      
    }
    
  }
  
}

statemachine class RER_EcosystemAnalyzer extends CEntity {
  var ecosystem_manager: RER_EcosystemManager;
  
  public function init(manager: RER_EcosystemManager) {
    this.ecosystem_manager = manager;
    theInput.RegisterListener(this, 'OnAnalyseEcosystem', 'EcosystemAnalyse');
    this.GotoState('Waiting');
  }
  
  event OnAnalyseEcosystem(action: SInputAction) {
    if (IsPressed(action) && this.GetCurrentStateName()!='Analysing') {
      this.GotoState('Analysing');
    }
    
  }
  
}


state Waiting in RER_EcosystemAnalyzer {
}


state Analysing in RER_EcosystemAnalyzer {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_EcosystemAnalyzer - state ANALYSING");
    this.startAnalysing();
  }
  
  entry function startAnalysing() {
    (new RER_RandomDialogBuilder in parent).start().either(new REROL_ill_check_area_data in parent, false, 1).either(new REROL_see_if_i_can_learn_what_out_there_data in parent, false, 1).either(new REROL_mhm_data in parent, false, 1).play();
    Sleep(0.5);
    this.playAnimation();
    Sleep(1.5);
    this.openBookPopup(this.getSurroundingCreaturesPercentages());
    this.stopAnimation();
    parent.GotoState('Waiting');
  }
  
  latent function playRandomNothingOneliner() {
    if (RandRange(10)<3) {
      REROL_nothing(true);
    }
    else if (RandRange(10)<3) {
      REROL_nothing_here(true);
      
    }
    else  {
      REROL_nothing_interesting(true);
      
    }
    
  }
  
  latent function playAnimation() {
    thePlayer.PlayerStartAction(PEA_ExamineGround, '');
  }
  
  latent function stopAnimation() {
    thePlayer.PlayerStopAction(PEA_ExamineGround);
  }
  
  function getSurroundingCreaturesPercentages(): array<RER_SurroundingCreaturePercentage> {
    var output: array<RER_SurroundingCreaturePercentage>;
    var modifiers: array<float>;
    var positive_total: float;
    var negative_total: float;
    var percent: float;
    var i: int;
    modifiers = parent.ecosystem_manager.getCreatureModifiersForEcosystemAreas(parent.ecosystem_manager.getCurrentEcosystemAreas());
    for (i = 0; i<CreatureMAX; i += 1) {
      if (modifiers[i]>0) {
        positive_total += modifiers[i];
      }
      else  {
        negative_total += modifiers[i];
        
      }
      
      
      NLOG("getSurroundingCreaturesPercentages - current modifier = "+modifiers[i]);
    }
    
    negative_total = AbsF(negative_total);
    for (i = 0; i<CreatureMAX; i += 1) {
      if (modifiers[i]!=0) {
        if (modifiers[i]>0) {
          percent = modifiers[i]/positive_total;
        }
        else  {
          percent = modifiers[i]/negative_total;
          
        }
        
        NLOG("getSurroundingCreaturesPercentages - percent for "+((CreatureType)(i))+" - "+percent);
        output.PushBack(newSurroundingCreaturePercentage(i, percent));
      }
      
    }
    
    return output;
  }
  
  latent function openBookPopup(creatures: array<RER_SurroundingCreaturePercentage>) {
    var sorted_creatures_ascending: array<RER_SurroundingCreaturePercentage>;
    var picked_creature: RER_SurroundingCreaturePercentage;
    var message: string;
    var teeming_creature_names: string;
    var less_likely_creature_names: string;
    var i: int;
    if (creatures.Size()==0) {
      this.playRandomNothingOneliner();
      return ;
    }
    
    sorted_creatures_ascending = this.sortCreaturePercentagesAscending(creatures);
    NLOG("positive sorted creatures size "+sorted_creatures_ascending.Size());
    if (sorted_creatures_ascending.Size()==0) {
      this.playRandomNothingOneliner();
      return ;
    }

    message = GetLocStringByKey('rer_surround_ecosystem_popup_body');

    teeming_creature_names = "";
    picked_creature = sorted_creatures_ascending[sorted_creatures_ascending.Size()-1];
    if (picked_creature.percentage>0) {
      teeming_creature_names += getCreatureNameFromCreatureType(parent.ecosystem_manager.master.bestiary, picked_creature.type);
    }
    
    if (sorted_creatures_ascending.Size()>1) {
      picked_creature = sorted_creatures_ascending[sorted_creatures_ascending.Size()-2];
      if (picked_creature.percentage>0) {
        teeming_creature_names += " "+GetLocStringByKey('rer_and')+" "+getCreatureNameFromCreatureType(parent.ecosystem_manager.master.bestiary, picked_creature.type);
      }
      
    }

    message = StrReplace(message, "{{teeming_creature_names}}", teeming_creature_names);

    less_likely_creature_names = "";
    picked_creature = sorted_creatures_ascending[0];
    if (picked_creature.percentage<0) {
      less_likely_creature_names += getCreatureNameFromCreatureType(parent.ecosystem_manager.master.bestiary, picked_creature.type);
    }
    
    if (sorted_creatures_ascending.Size()>1) {
      picked_creature = sorted_creatures_ascending[1];
      less_likely_creature_names += " " +GetLocStringByKey('rer_and')+" "+getCreatureNameFromCreatureType(parent.ecosystem_manager.master.bestiary, picked_creature.type);
    }
    
    message = StrReplace(message, "{{less_likely_creature_names}}", less_likely_creature_names);
    
    picked_creature = sorted_creatures_ascending[sorted_creatures_ascending.Size()-1];
    message = StrReplace(message, "{{ecosystem_advice}}", this.getEcosystemAdvice(picked_creature.type));
    message = StrReplace(message, "{{ecosystem_delay_multiplier}}", this.getMessageAboutEcosystemDelayMultiplier());

    RER_openPopup(GetLocStringByKey("rer_surround_ecosystem_popup_title"), message);
    if (RandRange(10)<1) {
      (new RER_RandomDialogBuilder in thePlayer).start().either(new REROL_well_well_still_learning in thePlayer, true, 0.5).play();
    }
    
  }
  
  function sortCreaturePercentagesAscending(percentages: array<RER_SurroundingCreaturePercentage>): array<RER_SurroundingCreaturePercentage> {
    var output: array<RER_SurroundingCreaturePercentage>;
    var sorted_percentages: array<float>;
    var sorted_size: int;
    var i: int;
    var j: int;
    for (i = 0; i<percentages.Size(); i += 1) {
      sorted_percentages.PushBack(percentages[i].percentage);
    }
    
    ArraySortFloats(sorted_percentages);
    for (i = 0; i<percentages.Size(); i += 1) {
      NLOG("sort positive, value"+sorted_percentages[i]);
    }
    
    sorted_size = sorted_percentages.Size();
    for (i = 0; i<percentages.Size(); i += 1) {
      for (j = sorted_size; j>=0; j -= 1) {
        if (percentages[j].percentage==sorted_percentages[i] && percentages[j].type!=CreatureNONE) {
          output.PushBack(percentages[j]);
          percentages[j].type = CreatureNONE;
        }
        
      }
      
    }
    
    for (i = 0; i<output.Size(); i += 1) {
      NLOG("sort ascending, value"+output[i].type+" "+output[i].percentage);
    }
    
    return output;
  }
  
  function getEcosystemAdvice(main_creature_type: CreatureType): string {
    var advice: string;
    var addition_advice: string;
    var advice_creature_names: string;
    var creatures: array<CreatureType>;
    var i: int;
    advice = GetLocStringByKey("rer_ecosystem_advice");
    advice = StrReplace(advice, "{{creature_name}}", getCreatureNameFromCreatureType(parent.ecosystem_manager.master.bestiary, main_creature_type));

    creatures = parent.ecosystem_manager.getCommunityReasonsToExist(main_creature_type);
    advice_creature_names = "";
    for (i = 0; i<creatures.Size(); i += 1) {
      if (i==3) {
        break;
      }
      
      
      if (i==creatures.Size()-1 || i==2) {
        advice_creature_names += ", "+GetLocStringByKey("rer_and")+" ";
      }
      else if (i>0) {
        advice_creature_names += ", ";
        
      }
      
      advice_creature_names += getCreatureNameFromCreatureType(parent.ecosystem_manager.master.bestiary, creatures[i]);
    }

    advice = StrReplace(advice, "{{advice_creature_names}}", advice_creature_names);
    
    creatures = parent.ecosystem_manager.getCommunityGoodInfluences(main_creature_type);
    advice_creature_names = "";
    for (i = 0; i<creatures.Size(); i += 1) {
      if (i==3) {
        break;
      }
      
      if (i==creatures.Size()-1 || i==2) {
        advice_creature_names += ", "+GetLocStringByKey("rer_and")+" ";
      }
      else if (i>0) {
        advice_creature_names += ", ";
        
      }
      
      advice_creature_names += getCreatureNameFromCreatureType(parent.ecosystem_manager.master.bestiary, creatures[i]);
    }

    advice = StrReplace(advice, "{{other_creature_names}}", advice_creature_names);

    creatures = parent.ecosystem_manager.getCommunityBadInfluences(main_creature_type);
    if (creatures.Size()>0) {
      addition_advice = GetLocStringByKey("rer_ecosystem_addition_advice");
      addition_advice = StrReplace(addition_advice, "{{creature_name}}", getCreatureNameFromCreatureType(parent.ecosystem_manager.master.bestiary, main_creature_type));
      creatures = parent.ecosystem_manager.getCommunityBadInfluences(main_creature_type);
      advice_creature_names = "";
      for (i = 0; i<creatures.Size(); i += 1) {
        if (i==3) {
          break;
        }
        
        
        if (i==creatures.Size()-1 || i==2) {
          if (creatures.Size()>2) {
            advice_creature_names += ",";
          }
          
          advice_creature_names += " "+GetLocStringByKey("rer_and")+" ";
        }
        else if (i>0) {
          advice_creature_names += ", ";
          
        }
        
        
        advice_creature_names += getCreatureNameFromCreatureType(parent.ecosystem_manager.master.bestiary, creatures[i]);
      }

      addition_advice = StrReplace(addition_advice, "{{advice_creature_names}}", advice_creature_names);
      advice += addition_advice;
    }
    
    return advice;
  }
  
  function getMessageAboutEcosystemDelayMultiplier(): string {
    var rate: float;
    var rate_parent: string;
    var message: string;
    parent.ecosystem_manager.master.refreshEcosystemFrequencyMultiplier();
    rate = 100*parent.ecosystem_manager.master.ecosystem_frequency_multiplier;
    rate_parent = "" +RoundF(rate)+"%";
    message = StrReplace(GetLocStringByKey("rer_ecosystem_delay_multiplier"), "{{rate_parent}}", rate_parent);
    return message;
  }
  
}


struct RER_SurroundingCreaturePercentage {
  var type: CreatureType;
  
  var percentage: float;
  
}


function newSurroundingCreaturePercentage(type: CreatureType, percentage: float): RER_SurroundingCreaturePercentage {
  var output: RER_SurroundingCreaturePercentage;
  output.type = type;
  output.percentage = percentage;
  return output;
}

class RER_EcosystemManager {
  var master: CRandomEncounters;
  
  var ecosystem_analyser: RER_EcosystemAnalyzer;
  
  var ecosystem_modifier: RER_EcosystemModifier;
  
  public function init(master: CRandomEncounters) {
    this.master = master;
    this.ecosystem_analyser = new RER_EcosystemAnalyzer in this;
    this.ecosystem_analyser.init(this);
    this.ecosystem_modifier = new RER_EcosystemModifier in this;
    this.ecosystem_modifier.init(this);
  }
  
  public function getCurrentEcosystemAreas(): array<int> {
    var player_position: Vector;
    var current_area: EcosystemArea;
    var output: array<int>;
    var i: int;
    NLOG("getCurrentEcosystemAreas, current areas count: "+this.master.storages.ecosystem.ecosystem_areas.Size());
    player_position = thePlayer.GetWorldPosition();
    for (i = 0; i<this.master.storages.ecosystem.ecosystem_areas.Size(); i += 1) {
      current_area = this.master.storages.ecosystem.ecosystem_areas[i];
      
      if (VecDistanceSquared(player_position, current_area.position)<current_area.radius*current_area.radius) {
        output.PushBack(i);
      }
      
    }
    
    NLOG("getCurrentEcosystemAreas, found "+output.Size()+" areas");
    return output;
  }
  
  public function getCreatureModifiersForEcosystemAreas(areas: array<int>): array<float> {
    var output: array<float>;
    var current_index: int;
    var current_area: EcosystemArea;
    var current_power: float;
    var current_impact: EcosystemCreatureImpact;
    var i: int;
    var j: int;
    var k: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      output.PushBack(0);
    }
    
    for (i = 0; i<areas.Size(); i += 1) {
      current_index = areas[i];
      
      current_area = this.master.storages.ecosystem.ecosystem_areas[current_index];
      
      for (j = 0; j<CreatureMAX; j += 1) {
        current_power = current_area.impacts_power_by_creature_type[j];
        
        if (current_power==0) {
          continue;
        }
        
        
        NLOG("current area, creature power = "+((CreatureType)(j))+" - "+current_power);
        
        current_impact = this.master.bestiary.entries[j].ecosystem_impact;
        
        for (k = 0; k<current_impact.influences.Size(); k += 1) {
          output[k] += current_power*current_impact.influences[k];
        }
        
      }
      
    }
    
    return output;
  }
  
  public function udpateCountersWithCreatureModifiers(out counters: array<int>, modifiers: array<float>) {
    var i: int;
    if (counters.Size()!=modifiers.Size()) {
      NLOG("attempt at updating counters with creature modifiers, but counters and modifiers are not of the same size");
      return ;
    }
    
    for (i = 0; i<counters.Size(); i += 1) {
      NLOG("udpateCountersWithCreatureModifiers, before = "+counters[i]);
      
      NLOG("udpateCountersWithCreatureModifiers, creature = "+((CreatureType)(i))+" modifier = "+modifiers[i]);
      
      if (counters[i]<=0) {
        NLOG("udpateCountersWithCreatureModifiers, counter = 0, skipping");
        continue;
      }
      
      
      counters[i] += (int)((((float)(counters[i]))*modifiers[i]*this.master.settings.ecosystem_community_power_effect));
      
      NLOG("udpateCountersWithCreatureModifiers, after = "+counters[i]);
    }
    
  }
  
  public function updatePowerForCreatureInCurrentEcosystemAreas(creature: CreatureType, power_change: float, position: Vector) {
    var ecosystem_areas: array<int>;
    var current_ecosystem_area: EcosystemArea;
    var current_index: int;
    var distance_from_center: float;
    var i: int;
    NLOG("power change for "+creature+" = "+power_change);
    ecosystem_areas = this.getCurrentEcosystemAreas();
    if (ecosystem_areas.Size()==0) {
      NLOG("no ecosystem area found, creating one");
      current_ecosystem_area = getNewEcosystemArea(position, this.master.settings.minimum_spawn_distance+this.master.settings.spawn_diameter);
      this.master.storages.ecosystem.ecosystem_areas.PushBack(current_ecosystem_area);
      ecosystem_areas.PushBack(0);
    }
    
    for (i = 0; i<ecosystem_areas.Size(); i += 1) {
      current_index = ecosystem_areas[i];
      
      current_ecosystem_area = this.master.storages.ecosystem.ecosystem_areas[current_index];
      
      distance_from_center = VecDistanceSquared(current_ecosystem_area.position, position);
      
      distance_from_center = distance_from_center/(current_ecosystem_area.radius*current_ecosystem_area.radius);
      
      distance_from_center = MinF(distance_from_center, 0.2);
      
      NLOG("ecosystem power change for "+creature+" distance from center = "+distance_from_center);
      
      NLOG("ecosystem power change for "+creature+" = "+power_change*(1-distance_from_center));
      
      this.master.storages.ecosystem.ecosystem_areas[current_index].impacts_power_by_creature_type[creature] += power_change*(1-distance_from_center)*(1+AbsF(this.master.storages.ecosystem.ecosystem_areas[current_index].impacts_power_by_creature_type[creature]*0.025));
    }
    
    this.ecosystem_modifier.executePowerSpreadAndNaturalDeath(ecosystem_areas);
    this.master.storages.ecosystem.save();
  }
  
  public function getNewEcosystemArea(position: Vector, radius: float): EcosystemArea {
    var area: EcosystemArea;
    var i: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      area.impacts_power_by_creature_type.PushBack(0);
    }
    
    area.position = position;
    area.radius = radius;
    return area;
  }
  
  public function getCommunityReasonsToExist(creature_type: CreatureType): array<CreatureType> {
    var current_bestiary_entry: RER_BestiaryEntry;
    var influences: RER_ConstantInfluences;
    var output: array<CreatureType>;
    var i: int;
    influences = RER_ConstantInfluences();
    for (i = 0; i<CreatureMAX; i += 1) {
      current_bestiary_entry = this.master.bestiary.entries[i];
      
      if (current_bestiary_entry.ecosystem_impact.influences[creature_type]==influences.friend_with) {
        output.PushBack(i);
      }
      
    }
    
    for (i = 0; i<CreatureMAX; i += 1) {
      current_bestiary_entry = this.master.bestiary.entries[i];
      
      if (current_bestiary_entry.ecosystem_impact.influences[creature_type]==influences.high_indirect_influence) {
        output.PushBack(i);
      }
      
    }
    
    for (i = 0; i<CreatureMAX; i += 1) {
      current_bestiary_entry = this.master.bestiary.entries[i];
      
      if (current_bestiary_entry.ecosystem_impact.influences[creature_type]==influences.low_indirect_influence) {
        output.PushBack(i);
      }
      
    }
    
    return output;
  }
  
  public function getCommunityReasonsToNotExist(creature_type: CreatureType): array<CreatureType> {
    var current_bestiary_entry: RER_BestiaryEntry;
    var influences: RER_ConstantInfluences;
    var output: array<CreatureType>;
    var i: int;
    influences = RER_ConstantInfluences();
    for (i = 0; i<CreatureMAX; i += 1) {
      current_bestiary_entry = this.master.bestiary.entries[i];
      
      if (current_bestiary_entry.ecosystem_impact.influences[creature_type]==influences.friend_with) {
        output.PushBack(i);
      }
      
    }
    
    for (i = 0; i<CreatureMAX; i += 1) {
      current_bestiary_entry = this.master.bestiary.entries[i];
      
      if (current_bestiary_entry.ecosystem_impact.influences[creature_type]==influences.high_indirect_influence) {
        output.PushBack(i);
      }
      
    }
    
    for (i = 0; i<CreatureMAX; i += 1) {
      current_bestiary_entry = this.master.bestiary.entries[i];
      
      if (current_bestiary_entry.ecosystem_impact.influences[creature_type]==influences.low_indirect_influence) {
        output.PushBack(i);
      }
      
    }
    
    return output;
  }
  
  public function getCommunityGoodInfluences(creature_type: CreatureType): array<CreatureType> {
    var influences: RER_ConstantInfluences;
    var output: array<CreatureType>;
    var current_influence: float;
    var current_type: int;
    influences = RER_ConstantInfluences();
    for (current_type = 0; current_type<CreatureMAX; current_type += 1) {
      current_influence = this.master.bestiary.entries[creature_type].ecosystem_impact.influences[current_type];
      
      if (current_influence==influences.friend_with) {
        output.PushBack(current_type);
      }
      
    }
    
    for (current_type = 0; current_type<CreatureMAX; current_type += 1) {
      current_influence = this.master.bestiary.entries[creature_type].ecosystem_impact.influences[current_type];
      
      if (current_influence==influences.high_indirect_influence) {
        output.PushBack(current_type);
      }
      
    }
    
    for (current_type = 0; current_type<CreatureMAX; current_type += 1) {
      current_influence = this.master.bestiary.entries[creature_type].ecosystem_impact.influences[current_type];
      
      if (current_influence==influences.low_indirect_influence) {
        output.PushBack(current_type);
      }
      
    }
    
    return output;
  }
  
  public function getCommunityBadInfluences(creature_type: CreatureType): array<CreatureType> {
    var influences: RER_ConstantInfluences;
    var output: array<CreatureType>;
    var current_influence: float;
    var current_type: int;
    influences = RER_ConstantInfluences();
    for (current_type = 0; current_type<CreatureMAX; current_type += 1) {
      current_influence = this.master.bestiary.entries[creature_type].ecosystem_impact.influences[current_type];
      
      if (current_influence==influences.kills_them) {
        output.PushBack(current_type);
      }
      
    }
    
    for (current_type = 0; current_type<CreatureMAX; current_type += 1) {
      current_influence = this.master.bestiary.entries[creature_type].ecosystem_impact.influences[current_type];
      
      if (current_influence==influences.high_bad_influence) {
        output.PushBack(current_type);
      }
      
    }
    
    for (current_type = 0; current_type<CreatureMAX; current_type += 1) {
      current_influence = this.master.bestiary.entries[creature_type].ecosystem_impact.influences[current_type];
      
      if (current_influence==influences.low_bad_influence) {
        output.PushBack(current_type);
      }
      
    }
    
    return output;
  }
  
  public function getEcosystemAreasFrequencyMultiplier(areas: array<int>): float {
    var current_index: int;
    var current_area: EcosystemArea;
    var number_of_areas: int;
    var current_power: float;
    var i: int;
    var j: int;
    var multiplier: float;
    number_of_areas = areas.Size();
    if (number_of_areas<=0) {
      return 1;
    }
    
    for (i = 0; i<number_of_areas; i += 1) {
      current_index = areas[i];
      
      current_area = this.master.storages.ecosystem.ecosystem_areas[current_index];
      
      for (j = 0; j<CreatureMAX; j += 1) {
        current_power = current_area.impacts_power_by_creature_type[j];
        
        if (current_power==0) {
          continue;
        }
        
        
        NLOG("current_power ["+((CreatureType)(j))+"] ="+current_power);
        
        multiplier += current_power*this.master.bestiary.entries[j].ecosystem_delay_multiplier;
      }
      
    }
    
    multiplier /= number_of_areas;
    multiplier *= StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('RERencountersGeneral', 'RERecosystemFrequencyMultiplier'))*0.01;
    NLOG("multiplier = "+multiplier);
    if (multiplier==0) {
      return 1;
    }
    else if (multiplier<0) {
      return multiplier*-0.01+1;
      
    }
    else  {
      return 1/((multiplier)*0.01+1);
      
    }
    
  }
  
  public function resetAllEcosystems() {
    var player_position: Vector;
    var current_area: EcosystemArea;
    var i: int;
    this.master.storages.ecosystem.ecosystem_areas.Clear();
    this.master.storages.ecosystem.save();
  }
  
}

statemachine class RER_EcosystemModifier {
  var ecosystem_manager: RER_EcosystemManager;
  
  var current_ecosystem_areas: array<int>;
  
  public function init(manager: RER_EcosystemManager) {
    this.ecosystem_manager = manager;
    this.GotoState('Waiting');
  }
  
  public function executePowerSpreadAndNaturalDeath(areas: array<int>) {
    if (this.GetCurrentStateName()=='PowerSpreadAndNaturalDeath') {
      return ;
    }
    
    this.current_ecosystem_areas = areas;
    this.GotoState('PowerSpreadAndNaturalDeath');
  }
  
}


state Waiting in RER_EcosystemModifier {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_EcosystemModifier - state WAITING");
  }
  
}


state PowerSpreadAndNaturalDeath in RER_EcosystemModifier {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_EcosystemModifier - state PowerSpreadAndNaturalDeath");
    this.powerSpreadAndNaturalDeathMain();
  }
  
  entry function powerSpreadAndNaturalDeathMain() {
    this.powerSpread();
    this.naturalDeath();
    parent.GotoState('Waiting');
  }
  
  latent function powerSpread() {
    var spread_settings: float;
    var default_radius: float;
    var current_power: float;
    var current_index: int;
    var type: int;
    var i: int;
    default_radius = parent.ecosystem_manager.master.settings.minimum_spawn_distance+parent.ecosystem_manager.master.settings.spawn_diameter;
    spread_settings = parent.ecosystem_manager.master.settings.ecosystem_community_power_spread;
    for (i = 0; i<parent.current_ecosystem_areas.Size(); i += 1) {
      current_index = parent.current_ecosystem_areas[i];
      
      for (type = 0; type<CreatureMAX; type += 1) {
        current_power += parent.ecosystem_manager.master.storages.ecosystem.ecosystem_areas[current_index].impacts_power_by_creature_type[type];
      }
      
      
      if (current_power>0) {
        parent.ecosystem_manager.master.storages.ecosystem.ecosystem_areas[current_index].radius = default_radius+current_power*spread_settings;
      }
      else  {
        parent.ecosystem_manager.master.storages.ecosystem.ecosystem_areas[current_index].radius = default_radius+AbsF(current_power)*spread_settings*0.5;
        
      }
      
    }
    
  }
  
  latent function naturalDeath() {
    var death_settings: float;
    var current_index: int;
    var type: int;
    var i: int;
    death_settings = parent.ecosystem_manager.master.settings.ecosystem_community_natural_death_speed;
    for (i = 0; i<parent.current_ecosystem_areas.Size(); i += 1) {
      current_index = parent.current_ecosystem_areas[i];
      
      for (type = 0; type<CreatureMAX; type += 1) {
        parent.ecosystem_manager.master.storages.ecosystem.ecosystem_areas[current_index].impacts_power_by_creature_type[type] *= 1-death_settings;
      }
      
    }
    
  }
  
}

struct EcosystemCreatureImpact {
  var influences: array<float>;
  
}


struct EcosystemArea {
  var radius: float;
  
  var position: Vector;
  
  var impacts_power_by_creature_type: array<float>;
  
}


class EcosystemCreatureImpactBuilder {
  var impact: EcosystemCreatureImpact;
  
  function influence(strength: float): EcosystemCreatureImpactBuilder {
    this.impact.influences.PushBack(strength);
    return this;
  }
  
  function build(): EcosystemCreatureImpact {
    return this.impact;
  }
  
}

statemachine class RandomEncountersReworkedGryphonHuntEntity extends CEntity {
  public var bait_position: Vector;
  
  public var ticks: int;
  
  public var this_entity: CEntity;
  
  public var this_actor: CActor;
  
  public var this_newnpc: CNewNPC;
  
  public var animation_slot: CAIPlayAnimationSlotAction;
  
  public var animation_slot_idle: CAIPlayAnimationSlotAction;
  
  public var automatic_kill_threshold_distance: float;
  
  default automatic_kill_threshold_distance = 600;
  
  public var blood_resources: array<RER_TrailMakerTrack>;
  
  public var blood_resources_size: int;
  
  public var pickup_animation_on_death: bool;
  
  default pickup_animation_on_death = false;
  
  var blood_maker: RER_TrailMaker;
  
  var horse_corpse_near_geralt: CEntity;
  
  var horse_corpse_near_gryphon: CEntity;
  
  var master: CRandomEncounters;
  
  event OnSpawned(spawnData: SEntitySpawnData) {
    super.OnSpawned(spawnData);
    animation_slot = new CAIPlayAnimationSlotAction in this;
    this.animation_slot.OnCreated();
    this.animation_slot.animName = 'monster_gryphon_special_attack_tearing_up_loop';
    this.animation_slot.blendInTime = 1.0;
    this.animation_slot.blendOutTime = 1.0;
    this.animation_slot.slotName = 'NPC_ANIM_SLOT';
    this.animation_slot_idle = new CAIPlayAnimationSlotAction in this;
    this.animation_slot_idle.OnCreated();
    this.animation_slot_idle.animName = 'monster_gryphon_idle';
    this.animation_slot_idle.blendInTime = 1.0;
    this.animation_slot_idle.blendOutTime = 1.0;
    this.animation_slot_idle.slotName = 'NPC_ANIM_SLOT';
    this.this_actor.SetTemporaryAttitudeGroup('q104_avallach_friendly_to_all', AGP_Default);
    NLOG("RandomEncountersReworkedGryphonHuntEntity spawned");
  }
  
  public function attach(actor: CActor, newnpc: CNewNPC, this_entity: CEntity, master: CRandomEncounters) {
    this.this_actor = actor;
    this.this_newnpc = newnpc;
    this.this_entity = this_entity;
    this.master = master;
    this.CreateAttachment(this_entity);
    this.AddTag('RandomEncountersReworked_Entity');
    newnpc.AddTag('RandomEncountersReworked_Entity');
  }
  
  public function startEncounter(blood_resources: array<RER_TrailMakerTrack>) {
    NLOG("RandomEncountersReworkedGryphonHuntEntity encounter started");
    this.blood_maker = new RER_TrailMaker in this;
    this.blood_maker.init(this.master.settings.foottracks_ratio, 200, blood_resources);
    this.AddTimer('intervalLifecheckFunction', 1, true);
    if (RandRange(10)>=5) {
      this.GotoState('WaitingForPlayer');
    }
    else  {
      this.GotoState('FlyingAbovePlayer');
      
    }
    
  }
  
  public function killNearbyEntities(center: CNode) {
    var entities_in_range: array<CGameplayEntity>;
    var i: int;
    FindGameplayEntitiesInRange(entities_in_range, center, 20, 50, , , , 'CNewNPC');
    for (i = 0; i<entities_in_range.Size(); i += 1) {
      if (((CActor)(entities_in_range[i]))!=this.this_actor && ((CActor)(entities_in_range[i]))!=this && ((CNode)(entities_in_range[i]))!=center && !((CNewNPC)(entities_in_range[i])).HasTag('RandomEncountersReworked_Entity') && (((CNewNPC)(entities_in_range[i])).HasTag('animal') || ((CActor)(entities_in_range[i])).IsMonster() || ((CActor)(entities_in_range[i])).GetAttitude(thePlayer)==AIA_Hostile)) {
        ((CActor)(entities_in_range[i])).Kill('RandomEncounters', true);
      }
      
    }
    
  }
  
  public function removeAllLoot() {
    var inventory: CInventoryComponent;
    inventory = this.this_actor.GetInventory();
    inventory.EnableLoot(false);
  }
  
  event OnDestroyed() {
    this.clean();
  }
  
  timer function intervalLifecheckFunction(optional dt: float, optional id: Int32) {
    var distance_from_player: float;
    if (!this.this_newnpc.IsAlive()) {
      this.clean();
      return ;
    }
    
    distance_from_player = VecDistance(this.GetWorldPosition(), thePlayer.GetWorldPosition());
    if (distance_from_player>this.automatic_kill_threshold_distance) {
      NLOG("killing entity - threshold distance reached: "+this.automatic_kill_threshold_distance);
      this.clean();
      return ;
    }
    
  }
  
  private function clean() {
    var i: int;
    NLOG("RandomEncountersReworkedGryphonHuntEntity destroyed");
    RemoveTimer('intervalDefaultFunction');
    this.horse_corpse_near_geralt.Destroy();
    this.horse_corpse_near_gryphon.Destroy();
    this.GotoState('ExitEncounter');
    theSound.SoundEvent("stop_music");
    theSound.InitializeAreaMusic(theGame.GetCommonMapManager().GetCurrentArea());
    this.this_actor.Kill('RandomEncountersReworked_Entity', true);
    if (this.pickup_animation_on_death) {
      this.master.requestOutOfCombatAction(OutOfCombatRequest_TROPHY_CUTSCENE);
    }
    
    this.Destroy();
  }
  
}


state ExitEncounter in RandomEncountersReworkedGryphonHuntEntity {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
  }
  
}

state GryphonFightingPlayer in RandomEncountersReworkedGryphonHuntEntity {
  var can_flee_fight: bool;
  
  var starting_health: float;
  
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    if (previous_state_name=='FlyingAbovePlayer') {
      this.can_flee_fight = true;
    }
    else  {
      this.can_flee_fight = false;
      
    }
    
    this.starting_health = parent.this_actor.GetHealthPercents();
    NLOG("Gryphon - State GryphonFightingPlayer");
    theSound.SoundEvent("stop_music");
    theSound.SoundEvent("play_music_nomansgrad");
    theSound.SoundEvent("mus_griffin_combat");
    parent.AddTimer('GryphonFightingPlayer_intervalDefaultFunction', 0.5, true);
  }
  
  timer function GryphonFightingPlayer_intervalDefaultFunction(optional dt: float, optional id: Int32) {
    NLOG("health loss: "+(this.starting_health-parent.this_actor.GetHealthPercents()));
    if (this.can_flee_fight && this.starting_health-parent.this_actor.GetHealthPercents()>0.45) {
      parent.GotoState('GryphonFleeingPlayer');
    }
    
  }
  
  event OnLeaveState(nextStateName: name) {
    parent.RemoveTimer('GryphonFightingPlayer_intervalDefaultFunction');
    theSound.SoundEvent("stop_music");
    theSound.InitializeAreaMusic(theGame.GetCommonMapManager().GetCurrentArea());
    super.OnLeaveState(nextStateName);
  }
  
}

state GryphonFleeingPlayer in RandomEncountersReworkedGryphonHuntEntity {
  var is_bleeding: bool;
  
  var bait: CEntity;
  
  var ai_behavior_flight: CAIFlightIdleFreeRoam;
  
  var ai_behavior_combat: CAIFlyingMonsterCombat;
  
  var flight_heading: float;
  
  var distance_threshold: float;
  
  var starting_position: Vector;
  
  var found_landing_position: bool;
  
  var landing_position: Vector;
  
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    if (previous_state_name=='GryphonFightingPlayer') {
      this.is_bleeding = true;
    }
    else  {
      this.is_bleeding = false;
      
    }
    
    NLOG("Gryphon - State GryphonFleeingPlayer");
    this.GryphonFleeingPlayer_main();
  }
  
  entry function GryphonFleeingPlayer_main() {
    var i: int;
    NLOG("Gryphon - State GryphonFleeingPlayer - main");
    (parent.this_actor).SetImmortalityMode(AIM_Invulnerable, AIC_Default);
    (parent.this_actor).EnableCharacterCollisions(false);
    (parent.this_actor).EnableDynamicCollisions(false);
    bait = theGame.CreateEntity((CEntityTemplate)(LoadResourceAsync("characters\npc_entities\animals\hare.w2ent", true)), parent.this_entity.GetWorldPosition(), thePlayer.GetWorldRotation(), true, false, false, PM_DontPersist);
    for (i = 0; i<100; i += 1) {
      parent.this_newnpc.CancelAIBehavior(i);
    }
    
    ((CNewNPC)(this.bait)).SetGameplayVisibility(false);
    ((CNewNPC)(this.bait)).SetVisibility(false);
    ((CActor)(this.bait)).EnableCharacterCollisions(false);
    ((CActor)(this.bait)).EnableDynamicCollisions(false);
    ((CActor)(this.bait)).EnableStaticCollisions(false);
    ((CActor)(this.bait)).SetImmortalityMode(AIM_Immortal, AIC_Default);
    ((CActor)(this.bait)).AddBuffImmunity_AllNegative('RandomEncountersReworked', false);
    parent.this_newnpc.SetUnstoppable(true);
    theSound.SoundEvent("stop_music");
    theSound.SoundEvent("mus_griffin_chase");
    this.GryphonFleeingPlayer_forgetPlayer();
    parent.AddTimer('GryphonFleeingPlayer_startFlying', 2, false);
    parent.AddTimer('GryphonFleeingPlayer_forgetPlayer', 0.05, true);
    parent.AddTimer('GryphonFleeingPlayer_GiveUp', 60, true);
  }
  
  timer function GryphonFleeingPlayer_forgetPlayer(optional dt: float, optional id: Int32) {
    parent.this_newnpc.ForgetActor(thePlayer);
  }
  
  timer function GryphonFleeingPlayer_startFlying(optional dt: float, optional id: Int32) {
    this.ai_behavior_flight = new CAIFlightIdleFreeRoam in this;
    this.flight_heading = VecHeading(parent.this_entity.GetWorldPosition()-thePlayer.GetWorldPosition());
    parent.this_actor.SetTemporaryAttitudeGroup('friendly_to_player', AGP_Default);
    parent.this_newnpc.ForgetActor(thePlayer);
    parent.this_newnpc.NoticeActor((CActor)(this.bait));
    this.distance_threshold = 150*150;
    this.starting_position = thePlayer.GetWorldPosition();
    theSound.SoundEvent("stop_music");
    theSound.SoundEvent("play_music_nomansgrad");
    theSound.SoundEvent("mus_griffin_chase");
    parent.AddTimer('GryphonFleeingPlayer_intervalDefaultFunction', 2, true);
    if (this.is_bleeding) {
      parent.AddTimer('GryphonFleeingPlayer_intervalDropBloodFunction', 0.3, true);
    }
    
  }
  
  timer function GryphonFleeingPlayer_intervalDefaultFunction(optional dt: float, optional id: Int32) {
    var bait_position: Vector;
    NLOG("gryphon fleeing");
    parent.this_actor.SetTemporaryAttitudeGroup('monsters', AGP_Default);
    bait_position = parent.this_entity.GetWorldPosition();
    bait_position += VecConeRand(this.flight_heading, 1, 100, 100);
    FixZAxis(bait_position);
    bait_position.Z += 50;
    this.bait.Teleport(bait_position);
    parent.this_newnpc.ForgetAllActors();
    parent.this_newnpc.NoticeActor((CActor)(this.bait));
    parent.this_actor.SetHealthPerc(parent.this_actor.GetHealthPercents()+0.01);
    parent.this_entity.Teleport(parent.this_entity.GetWorldPosition()+Vector(0, 0, 0.1));
    if (VecDistanceSquared(this.starting_position, parent.this_actor.GetWorldPosition())>distance_threshold) {
      NLOG("Gryphon looking for ground position");
      parent.RemoveTimer('GryphonFleeingPlayer_intervalDefaultFunction');
      parent.AddTimer('GryphonFightingPlayer_intervalLookingForGroundPositionFunction', 1, true);
      (parent.this_actor).SetImmortalityMode(AIM_Invulnerable, AIC_Default);
      (parent.this_actor).EnableCharacterCollisions(true);
      (parent.this_actor).EnableDynamicCollisions(true);
      parent.this_newnpc.SetUnstoppable(false);
    }
    
  }
  
  timer function GryphonFightingPlayer_intervalLookingForGroundPositionFunction(optional dt: float, optional id: Int32) {
    var bait_position: Vector;
    bait_position = VecRingRand(1, 20)+parent.this_entity.GetWorldPosition();
    bait_position.Z -= 20;
    if (!this.found_landing_position && ((CActor)(bait)).GetDistanceFromGround(500)<=20) {
      this.landing_position = bait_position;
      if (theGame.GetWorld().NavigationFindSafeSpot(this.landing_position, 2, 100, this.landing_position) && theGame.GetWorld().GetWaterLevel(this.landing_position, true)<=this.landing_position.Z) {
        NLOG("found landing position");
        this.found_landing_position = true;
        this.landing_position.Z += 0.5;
        bait_position = this.landing_position;
      }
      
    }
    
    if (this.found_landing_position) {
      bait_position = this.landing_position;
    }
    
    this.bait.Teleport(bait_position);
    parent.this_actor.SetTemporaryAttitudeGroup('monsters', AGP_Default);
    parent.this_newnpc.ForgetActor(thePlayer);
    parent.this_newnpc.NoticeActor((CActor)(this.bait));
    if (parent.this_actor.GetDistanceFromGround(500)>5) {
      parent.this_entity.Teleport(parent.this_entity.GetWorldPosition()-Vector(0, 0, 0.05));
    }
    
    parent.this_actor.SetHealthPerc(parent.this_actor.GetHealthPercents()+0.01);
    if (this.found_landing_position) {
      parent.killNearbyEntities(this.bait);
    }
    
    if (this.found_landing_position && parent.this_actor.GetDistanceFromGround(500)<5) {
      (parent.this_actor).EnableCharacterCollisions(true);
      (parent.this_actor).EnableDynamicCollisions(true);
      (parent.this_actor).EnableStaticCollisions(true);
      parent.this_newnpc.SetUnstoppable(false);
      NLOG("Gryphon landed");
      parent.RemoveTimer('GryphonFightingPlayer_intervalLookingForGroundPositionFunction');
      parent.RemoveTimer('GryphonFleeingPlayer_GiveUp');
      this.cancelAIBehavior();
      this.ai_behavior_combat = new CAIFlyingMonsterCombat in this;
      parent.this_actor.ForceAIBehavior(this.ai_behavior_combat, BTAP_Emergency);
      parent.AddTimer('GryphonFleeingPlayer_intervalWaitPlayerFunction', 0.5, true);
    }
    
  }
  
  timer function GryphonFleeingPlayer_intervalWaitPlayerFunction(optional dt: float, optional id: Int32) {
    var gryphon_position: Vector;
    var mac: CMovingPhysicalAgentComponent;
    this.bait.Teleport(this.landing_position);
    parent.this_newnpc.ForgetActor(thePlayer);
    parent.this_newnpc.NoticeActor((CActor)(this.bait));
    parent.this_newnpc.ChangeStance(NS_Normal);
    parent.this_newnpc.SetBehaviorVariable('2high', 0);
    parent.this_newnpc.SetBehaviorVariable('2low', 0);
    parent.this_newnpc.SetBehaviorVariable('2ground', 1);
    parent.this_newnpc.SetBehaviorVariable('DistanceFromGround', 0);
    parent.this_newnpc.SetBehaviorVariable('GroundContact', 1.0);
    mac = (CMovingPhysicalAgentComponent)(parent.this_newnpc.GetMovingAgentComponent());
    parent.this_newnpc.ChangeStance(NS_Wounded);
    mac.SetAnimatedMovement(false);
    parent.this_newnpc.EnablePhysicalMovement(false);
    mac.SnapToNavigableSpace(true);
    parent.this_newnpc.PlayEffect('hit_ground');
    parent.this_actor.SetHealthPerc(parent.this_actor.GetHealthPercents()+0.005);
    if (VecDistanceSquared(parent.this_actor.GetWorldPosition(), thePlayer.GetWorldPosition())<625) {
      parent.GotoState('GryphonFightingPlayer');
    }
    
  }
  
  function cancelAIBehavior() {
    var i: int;
    for (i = 0; i<100; i += 1) {
      parent.this_newnpc.CancelAIBehavior(i);
    }
    
  }
  
  timer function GryphonFleeingPlayer_intervalDropBloodFunction(optional dt: float, optional id: Int32) {
    var position: Vector;
    position = parent.this_actor.GetWorldPosition();
    FixZAxis(position);
    parent.blood_maker.addTrackHere(position);
  }
  
  timer function GryphonFleeingPlayer_GiveUp(optional dt: float, optional id: Int32) {
    parent.GotoState('FlyingAbovePlayer');
  }
  
  event OnLeaveState(nextStateName: name) {
    this.bait.Destroy();
    parent.RemoveTimer('GryphonFleeingPlayer_intervalDefaultFunction');
    parent.RemoveTimer('GryphonFleeingPlayer_intervalWaitPlayerFunction');
    parent.RemoveTimer('GryphonFleeingPlayer_intervalDropBloodFunction');
    parent.RemoveTimer('GryphonFleeingPlayer_forgetPlayer');
    parent.RemoveTimer('GryphonFleeingPlayer_GiveUp');
    (parent.this_actor).SetImmortalityMode(AIM_None, AIC_Default);
    (parent.this_actor).EnableCharacterCollisions(true);
    (parent.this_actor).EnableDynamicCollisions(true);
    (parent.this_actor).EnableStaticCollisions(true);
    parent.this_newnpc.SetUnstoppable(false);
    super.OnLeaveState(nextStateName);
  }
  
}

state FlyingAbovePlayer in RandomEncountersReworkedGryphonHuntEntity {
  var bait: CEntity;
  
  var ai_behavior_flight: CAIFlightIdleFreeRoam;
  
  var bait_distance_from_player: float;
  
  var flight_heading: float;
  
  var distance_threshold: float;
  
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("Gryphon - State FlyingAbovePlayer, from "+previous_state_name);
    parent.this_actor.SetTemporaryAttitudeGroup('q104_avallach_friendly_to_all', AGP_Default);
    if (previous_state_name!='GryphonFleeingPlayer') {
      parent.this_entity.Teleport(parent.this_entity.GetWorldPosition()+Vector(0, 0, 80));
    }
    
    this.FlyingAbovePlayer_main();
  }
  
  entry function FlyingAbovePlayer_main() {
    var i: int;
    bait = theGame.CreateEntity((CEntityTemplate)(LoadResourceAsync("characters\npc_entities\animals\hare.w2ent", true)), parent.this_entity.GetWorldPosition(), thePlayer.GetWorldRotation(), true, false, false, PM_DontPersist);
    for (i = 0; i<100; i += 1) {
      parent.this_newnpc.CancelAIBehavior(i);
    }
    
    ((CNewNPC)(this.bait)).SetGameplayVisibility(false);
    ((CNewNPC)(this.bait)).SetVisibility(false);
    ((CActor)(this.bait)).EnableCharacterCollisions(false);
    ((CActor)(this.bait)).EnableDynamicCollisions(false);
    ((CActor)(this.bait)).EnableStaticCollisions(false);
    ((CActor)(this.bait)).SetImmortalityMode(AIM_Immortal, AIC_Default);
    ((CActor)(this.bait)).AddBuffImmunity_AllNegative('RandomEncountersReworked', false);
    this.ai_behavior_flight = new CAIFlightIdleFreeRoam in this;
    this.flight_heading = VecHeading(thePlayer.GetWorldPosition()-parent.this_entity.GetWorldPosition());
    parent.this_actor.ForceAIBehavior(this.ai_behavior_flight, BTAP_Emergency);
    parent.this_actor.SetTemporaryAttitudeGroup('friendly_to_player', AGP_Default);
    this.distance_threshold = VecDistanceSquared(parent.this_entity.GetWorldPosition(), thePlayer.GetWorldPosition())+100;
    parent.AddTimer('FlyingAbovePlayer_intervalDefaultFunction', 2, true);
  }
  
  timer function FlyingAbovePlayer_intervalDefaultFunction(optional dt: float, optional id: Int32) {
    var bait_position: Vector;
    parent.this_actor.SetTemporaryAttitudeGroup('monsters', AGP_Default);
    bait_position = parent.this_entity.GetWorldPosition();
    bait_position += VecConeRand(this.flight_heading, 1, 100, 100);
    this.bait.Teleport(bait_position);
    if (((CActor)(bait)).GetDistanceFromGround(500)<100) {
      bait_position.Z += 30;
    }
    else  {
      bait_position.Z -= 10;
      
    }
    
    this.bait.Teleport(bait_position);
    parent.this_newnpc.NoticeActor((CActor)(this.bait));
    if (VecDistanceSquared(thePlayer.GetWorldPosition(), parent.this_actor.GetWorldPosition())>distance_threshold) {
      parent.RemoveTimer('FlyingAbovePlayer_intervalDefaultFunction');
      parent.AddTimer('FlyingAbovePlayer_intervalComingToPlayer', 0.5, true);
    }
    
  }
  
  timer function FlyingAbovePlayer_intervalComingToPlayer(optional dt: float, optional id: Int32) {
    this.bait.Teleport(thePlayer.GetWorldPosition());
    parent.this_newnpc.NoticeActor((CActor)(this.bait));
    if (VecDistanceSquared(thePlayer.GetWorldPosition(), parent.this_actor.GetWorldPosition())<400) {
      parent.GotoState('GryphonFightingPlayer');
    }
    
  }
  
  event OnLeaveState(nextStateName: name) {
    parent.RemoveTimer('FlyingAbovePlayer_intervalDefaultFunction');
    parent.RemoveTimer('FlyingAbovePlayer_intervalComingToPlayer');
    this.bait.Destroy();
    super.OnLeaveState(nextStateName);
  }
  
}

state WaitingForPlayer in RandomEncountersReworkedGryphonHuntEntity {
  var bloodtrail_current_position: Vector;
  
  var bloodtrail_target_position: Vector;
  
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("Gryphon - State WaitingForPlayer");
    this.WaitingForPlayer_Main();
  }
  
  entry function WaitingForPlayer_Main() {
    this.bloodtrail_target_position = parent.this_actor.GetWorldPosition();
    this.bloodtrail_current_position = thePlayer.GetWorldPosition()+VecRingRand(2, 4);
    parent.horse_corpse_near_geralt = this.placeHorseCorpse(this.bloodtrail_current_position);
    parent.horse_corpse_near_gryphon = this.placeHorseCorpse(this.bloodtrail_target_position, true);
    thePlayer.PlayVoiceset(90, "MiscBloodTrail");
    parent.AddTimer('WaitingForPlayer_drawLineOfBloodToGryphon', 0.25, true);
    parent.AddTimer('WaitingForPlayer_intervalDefaultFunction', 0.5, true);
    parent.this_newnpc.ChangeStance(NS_Normal);
    parent.this_newnpc.SetBehaviorVariable('2high', 0);
    parent.this_newnpc.SetBehaviorVariable('2low', 0);
    parent.this_newnpc.SetBehaviorVariable('2ground', 1);
    parent.this_newnpc.SetUnstoppable(true);
  }
  
  private latent function placeHorseCorpse(position: Vector, optional horse_flat_on_ground: bool): CEntity {
    var horse_template: CEntityTemplate;
    var horse_rotation: EulerAngles;
    horse_rotation = RotRand(0, 360);
    if (horse_flat_on_ground) {
      horse_rotation.Yaw = 95;
    }
    
    horse_template = (CEntityTemplate)(LoadResourceAsync("items\quest_items\q103\q103_item__horse_corpse_with_head_lying_beside_it_02.w2ent", true));
    FixZAxis(position);
    return theGame.CreateEntity(horse_template, position, horse_rotation);
  }
  
  timer function WaitingForPlayer_intervalDefaultFunction(optional dt: float, optional id: Int32) {
    parent.killNearbyEntities(parent.this_actor);
    parent.this_actor.SetTemporaryAttitudeGroup('q104_avallach_friendly_to_all', AGP_Default);
    parent.this_newnpc.ForgetAllActors();
    if (parent.this_actor.IsInCombat() && parent.this_actor.GetTarget()==thePlayer || VecDistanceSquared(thePlayer.GetWorldPosition(), parent.this_actor.GetWorldPosition())<400 || parent.this_actor.GetDistanceFromGround(1000)>3) {
      parent.GotoState('GryphonFleeingPlayer');
      return ;
    }
    
    parent.this_newnpc.ChangeStance(NS_Normal);
    parent.this_newnpc.SetBehaviorVariable('2high', 0);
    parent.this_newnpc.SetBehaviorVariable('2low', 0);
    parent.this_newnpc.SetBehaviorVariable('2ground', 1);
    parent.this_actor.ForceAIBehavior(parent.animation_slot, BTAP_Emergency);
  }
  
  timer function WaitingForPlayer_drawLineOfBloodToGryphon(optional dt: float, optional id: Int32) {
    var heading_to_target: float;
    heading_to_target = VecHeading(this.bloodtrail_target_position-this.bloodtrail_current_position);
    this.bloodtrail_current_position += VecConeRand(heading_to_target, 80, 1, 2);
    FixZAxis(this.bloodtrail_current_position);
    NLOG("line of blood to gryphon, current position: "+VecToString(this.bloodtrail_current_position)+" target position: "+VecToString(this.bloodtrail_target_position));
    parent.blood_maker.addTrackHere(this.bloodtrail_current_position);
    if (VecDistanceSquared(this.bloodtrail_current_position, this.bloodtrail_target_position)<5*5) {
      parent.RemoveTimer('WaitingForPlayer_drawLineOfBloodToGryphon');
    }
    
  }
  
  event OnLeaveState(nextStateName: name) {
    var i: int;
    parent.RemoveTimer('WaitingForPlayer_intervalDefaultFunction');
    parent.RemoveTimer('WaitingForPlayer_drawLineOfBloodToGryphon');
    for (i = 0; i<100; i += 1) {
      parent.this_actor.CancelAIBehavior(i);
    }
    
    parent.this_newnpc.SetUnstoppable(false);
    super.OnLeaveState(nextStateName);
  }
  
}

latent function flyStartFromLand(npc: CNewNPC) {
  var animation_slot: CAIPlayAnimationSlotAction;
  var ticket: SMovementAdjustmentRequestTicket;
  var movementAdjustor: CMovementAdjustor;
  var slidePos: Vector;
  var i: float;
  var duration_in_seconds: float;
  var time_per_step: float;
  var translation_per_step: Vector;
  animation_slot = new CAIPlayAnimationSlotAction in npc;
  animation_slot.OnCreated();
  animation_slot.animName = 'monster_gryphon_fly_start_from_ground';
  animation_slot.blendInTime = 1.0;
  animation_slot.blendOutTime = 1.0;
  animation_slot.slotName = 'NPC_ANIM_SLOT';
  npc.ForceAIBehavior(animation_slot, BTAP_Emergency);
  duration_in_seconds = 2.0;
  time_per_step = 0.02;
  translation_per_step = Vector(0, 0, 10/(duration_in_seconds/time_per_step));
  i = 0;
  while (i<duration_in_seconds) {
    npc.Teleport(npc.GetWorldPosition()+translation_per_step);
    i += time_per_step;
    Sleep(time_per_step);
  }
  
}

latent function flyTo(npc: CNewNPC, destination_point: Vector, destination_radius: float, optional height_from_ground: float): EBTNodeStatus {
  var traceStartPos: Vector;
  var traceEndPos: Vector;
  var traceEffect: Vector;
  var normal: Vector;
  var groundLevel: Vector;
  var should_land: bool;
  var landing_point_set: bool;
  var random: int;
  var npcPos: Vector;
  var full_distance: float;
  flyStartFromLand(npc);
  npc.ChangeStance(NS_Fly);
  npc.SetBehaviorVariable('2high', 1);
  npc.SetBehaviorVariable('2low', 0);
  npc.SetBehaviorVariable('2ground', 0);
  npcPos = npc.GetWorldPosition();
  traceStartPos = destination_point;
  traceEndPos = destination_point;
  traceStartPos.Z += 200;
  if (theGame.GetWorld().StaticTrace(traceStartPos, traceEndPos, traceEffect, normal)) {
    if (traceEffect.Z>destination_point.Z) {
      destination_point = traceEffect;
    }
    
  }
  
  destination_point.Z += MaxF(height_from_ground, 20.0);
  should_land = false;
  landing_point_set = false;
  full_distance = VecDistance(npcPos, destination_point);
  while (true) {
    npc.SetBehaviorVariable('GroundContact', 0.0);
    npc.SetBehaviorVariable('DistanceFromGround', 100);
    if (should_land) {
      if (VecDistance(npcPos, destination_point)<destination_radius) {
        return BTNS_Completed;
      }
      
    }
    else  {
      npc.SetBehaviorVariable('GroundContact', 0.0);
      
      npc.SetBehaviorVariable('DistanceFromGround', 0.0);
      
      npc.SetBehaviorVariable('FlySpeed', 0.0);
      
    }
    
    UsePathFinding(npcPos, destination_point, 2.0);
    CalculateBehaviorVariables(npc, destination_point, full_distance);
    Sleep(0.1);
    if (VecDistance(npcPos, destination_point)<10) {
      should_land = true;
    }
    
  }
  
  return BTNS_Completed;
}


function CalculateBehaviorVariables(npc: CNewNPC, dest: Vector, full_distance: float) {
  var flySpeed: float;
  var flyPitch: float;
  var flyYaw: float;
  var turnSpeedScale: float;
  var npcToDestVector: Vector;
  var npcToDestVector2: Vector;
  var npcToDestDistance: float;
  var npcToDestAngle: float;
  var npcPos: Vector;
  var npcHeadingVec: Vector;
  var normal: Vector;
  var collision: Vector;
  npcPos = npc.GetWorldPosition();
  npcHeadingVec = npc.GetHeadingVector();
  npcToDestVector = dest-npcPos;
  npcToDestVector2 = npcToDestVector;
  npcToDestVector2.Z = 0;
  npcToDestDistance = VecDistance(npcPos, dest);
  npcToDestAngle = AbsF(AngleDistance(VecHeading(dest-npcPos), VecHeading(npcHeadingVec)));
  if (npcToDestAngle>60 || npcToDestAngle<-60) {
    flySpeed = 1.f;
  }
  else  {
    flySpeed = 2.f;
    
  }
  
  turnSpeedScale = 2.75;
  flyPitch = Rad2Deg(AcosF(VecDot(VecNormalize(npcToDestVector), VecNormalize(npcToDestVector2))));
  if (npcPos.X==dest.X && npcPos.Y==dest.Y) {
    flyPitch = 90;
  }
  
  flyPitch = flyPitch/90;
  flyPitch = flyPitch*PowF(turnSpeedScale, flyPitch);
  if (flyPitch>1) {
    flyPitch = 1.f;
  }
  else if (flyPitch<-1) {
    flyPitch = -1.f;
    
  }
  
  if (dest.Z<npcPos.Z) {
    flyPitch *= -1;
  }
  
  flyYaw = AngleDistance(VecHeading(npcToDestVector), VecHeading(npcHeadingVec));
  flyYaw = flyYaw/180;
  flyYaw = flyYaw*PowF(turnSpeedScale, AbsF(flyYaw));
  if (flyYaw>1) {
    flyYaw = 1.f;
  }
  else if (flyYaw<-1) {
    flyYaw = -1.f;
    
  }
  
  if (flyYaw>-0.5 && flyYaw<0.5 && theGame.GetWorld().StaticTrace(npcPos, npcPos+npc.GetWorldForward(), collision, normal)) {
    flyYaw = -1;
  }
  
  if (flyYaw<-0.5 && theGame.GetWorld().StaticTrace(npcPos, npcPos+npc.GetWorldRight(), collision, normal)) {
    flyYaw = 1;
  }
  else if (flyYaw>0.5 && theGame.GetWorld().StaticTrace(npcPos, npcPos+(npc.GetWorldRight()*-1), collision, normal)) {
    flyYaw = -1;
    
  }
  
  npc.SetBehaviorVariable('FlyYaw', flyYaw);
  npc.SetBehaviorVariable('FlyPitch', flyPitch);
  npc.SetBehaviorVariable('FlySpeed', flySpeed);
  NLOG("flyYaw"+flyYaw+" flyPitch"+flyPitch+" flySpeed"+flySpeed);
}


function UsePathFinding(currentPosition: Vector, out targetPosition: Vector, optional predictionDist: float): bool {
  var path: array<Vector>;
  if (theGame.GetVolumePathManager().IsPathfindingNeeded(currentPosition, targetPosition)) {
    path.Clear();
    if (theGame.GetVolumePathManager().GetPath(currentPosition, targetPosition, path)) {
      targetPosition = path[1];
      return true;
    }
    
    return false;
  }
  
  return true;
}

struct HuntEntitySettings {
  var kill_threshold_distance: float;
  
  var allow_trophy_pickup_scene: bool;
  
}


statemachine class RandomEncountersReworkedHuntEntity extends CEntity {
  var master: CRandomEncounters;
  
  var entities: array<CEntity>;
  
  var bestiary_entry: RER_BestiaryEntry;
  
  var entity_settings: HuntEntitySettings;
  
  var bait_entity: CEntity;
  
  var trail_maker: RER_TrailMaker;
  
  var bait_moves_towards_player: bool;
  
  var oneliner: RER_OnelinerEntity;
  
  public function startEncounter(master: CRandomEncounters, entities: array<CEntity>, bestiary_entry: RER_BestiaryEntry, optional bait_moves_towards_player: bool) {
    this.master = master;
    this.entities = entities;
    this.bestiary_entry = bestiary_entry;
    this.bait_moves_towards_player = bait_moves_towards_player;
    this.loadSettings(master);
    this.addOneliner();
    this.GotoState('Loading');
  }
  
  private function addOneliner() {
    var first: CEntity;
    if (this.bait_moves_towards_player && !theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERonelinersAmbush')) {
      return ;
    }
    
    if (!this.bait_moves_towards_player && !theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERonelinersHunt')) {
      return ;
    }
    
    if (this.entities.Size()>0) {
      first = this.entities[0];
      this.oneliner = RER_onelinerEntity((new SUOL_TagBuilder in thePlayer).tag("font").attr("color", "#9e9e9e").text(this.bestiary_entry.toLocalizedName()), first);
      this.oneliner.setRenderDistance(50);
    }
    
  }
  
  private function loadSettings(master: CRandomEncounters) {
    this.entity_settings.kill_threshold_distance = master.settings.kill_threshold_distance;
    this.entity_settings.allow_trophy_pickup_scene = master.settings.trophy_pickup_scene;
  }
  
  public latent function clean() {
    var i: int;
    NLOG("RandomEncountersReworkedHuntEntity destroyed");
    if (this.oneliner) {
      this.oneliner.unregister();
    }
    
    for (i = 0; i<this.entities.Size(); i += 1) {
      this.killEntity(this.entities[i]);
    }
    
    trail_maker.clean();
    this.Destroy();
  }
  
  public function killEntity(entity: CEntity): bool {
    ((CActor)(entity)).Kill('RandomEncountersReworked_Entity', true);
    return this.entities.Remove(entity);
  }
  
  public function getRandomEntity(): CEntity {
    var entity: CEntity;
    entity = this.entities[RandRange(this.entities.Size())];
    return entity;
  }
  
}

state Combat in RandomEncountersReworkedHuntEntity {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("Hunt - State Combat");
    this.Combat_Main();
  }
  
  entry function Combat_Main() {
    if (parent.bait_moves_towards_player) {
      RER_tutorialTryShowAmbushed();
      this.startAmbushCutscene();
    }
    
    parent.Teleport(thePlayer.GetWorldPosition());
    this.resetEntitiesAttitudes();
    this.makeEntitiesTargetPlayer();
    this.waitUntilPlayerFinishesCombat();
    if (parent.entity_settings.allow_trophy_pickup_scene) {
      parent.master.requestOutOfCombatAction(OutOfCombatRequest_TROPHY_CUTSCENE);
    }
    
    this.Combat_goToNextState();
  }
  
  private latent function startAmbushCutscene() {
    if (isPlayerBusy()) {
      return ;
    }
    
    if (parent.master.settings.geralt_comments_enabled) {
      thePlayer.PlayVoiceset(90, "BattleCryBadSituation");
    }
    
    if (!parent.master.settings.disable_camera_scenes && parent.master.settings.enable_action_camera_scenes) {
      playAmbushCameraScene();
    }
    
  }
  
  private latent function playAmbushCameraScene() {
    var scene: RER_CameraScene;
    var camera: RER_StaticCamera;
    var look_at_position: Vector;
    scene.position_type = RER_CameraPositionType_ABSOLUTE;
    scene.position = theCamera.GetCameraPosition()+Vector(0, 0, 1);
    scene.look_at_target_type = RER_CameraTargetType_STATIC;
    look_at_position = parent.getRandomEntity().GetWorldPosition();
    scene.look_at_target_static = look_at_position+Vector(0, 0, 0);
    scene.velocity_type = RER_CameraVelocityType_FORWARD;
    scene.velocity = Vector(0.001, 0.001, 0);
    scene.duration = 0.2;
    scene.position_blending_ratio = 0.05;
    scene.rotation_blending_ratio = 0.05;
    camera = RER_getStaticCamera();
    camera.playCameraScene(scene, true);
  }
  
  private latent function resetEntitiesAttitudes() {
    var i: int;
    for (i = 0; i<parent.entities.Size(); i += 1) {
      ((CActor)(parent.entities[i])).ResetTemporaryAttitudeGroup(AGP_Default);
    }
    
  }
  
  private latent function makeEntitiesTargetPlayer() {
    var i: int;
    for (i = 0; i<parent.entities.Size(); i += 1) {
      if (((CActor)(parent.entities[i])).GetTarget()!=thePlayer && !((CActor)(parent.entities[i])).HasAttitudeTowards(thePlayer)) {
        ((CNewNPC)(parent.entities[i])).NoticeActor(thePlayer);
        ((CActor)(parent.entities[i])).SetAttitude(thePlayer, AIA_Hostile);
      }
      
    }
    
  }
  
  private function moveBaitEntityOnFirstCreature() {
    var entity: CEntity;
    if (parent.entities.Size()>0) {
      entity = parent.entities[0];
      parent.bait_entity.Teleport(entity.GetWorldPosition());
    }
    
  }
  
  latent function waitUntilPlayerFinishesCombat() {
    Sleep(3);
    while (SUH_waitUntilPlayerFinishesCombatStep(parent.entities)) {
      RER_moveCreaturesAwayIfPlayerIsInCutscene(parent.entities, 30);
      Sleep(1);
    }
    
  }
  
  latent function Combat_goToNextState() {
    if (SUH_areAllEntitiesDead(parent.entities)) {
      parent.GotoState('Ending');
    }
    else  {
      parent.GotoState('Wandering');
      
    }
    
  }
  
}

state Ending in RandomEncountersReworkedHuntEntity {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RandomEncountersReworkedHuntEntity - State Ending");
    this.Ending_main();
  }
  
  entry function Ending_main() {
    if (VecDistanceSquared(thePlayer.GetWorldPosition(), parent.GetWorldPosition())<50*50) {
      RER_tryRefillRandomContainer(parent.master);
      if (parent.bait_moves_towards_player) {
        RER_emitEncounterKilled(parent.master, EncounterType_DEFAULT);
      }
      else  {
        RER_emitEncounterKilled(parent.master, EncounterType_HUNT);
        
      }
      
    }
    else  {
      if (parent.bait_moves_towards_player) {
        RER_emitEncounterRecycled(parent.master, EncounterType_DEFAULT);
      }
      else  {
        RER_emitEncounterRecycled(parent.master, EncounterType_HUNT);
        
      }
      
      
    }
    
    parent.clean();
  }
  
}

state Loading in RandomEncountersReworkedHuntEntity {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RandomEncountersReworkedHuntEntity - State Loading");
    this.Loading_main();
  }
  
  entry function Loading_main() {
    var template: CEntityTemplate;
    var tracks_templates: array<RER_TrailMakerTrack>;
    template = (CEntityTemplate)(LoadResourceAsync("characters\npc_entities\animals\hare.w2ent", true));
    parent.bait_entity = theGame.CreateEntity(template, parent.GetWorldPosition(), parent.GetWorldRotation());
    ((CNewNPC)(parent.bait_entity)).SetGameplayVisibility(false);
    ((CNewNPC)(parent.bait_entity)).SetVisibility(false);
    ((CActor)(parent.bait_entity)).EnableCharacterCollisions(false);
    ((CActor)(parent.bait_entity)).EnableDynamicCollisions(false);
    ((CActor)(parent.bait_entity)).EnableStaticCollisions(false);
    ((CActor)(parent.bait_entity)).SetImmortalityMode(AIM_Immortal, AIC_Default);
    ((CActor)(parent.bait_entity)).AddBuffImmunity_AllNegative('RandomEncountersReworked', false);
    tracks_templates.PushBack(getTracksTemplateByCreatureType(parent.bestiary_entry.type));
    parent.trail_maker = new RER_TrailMaker in parent;
    parent.trail_maker.init(parent.master.settings.foottracks_ratio, 200, tracks_templates);
    parent.trail_maker.drawTrail(VecInterpolate(parent.GetWorldPosition(), thePlayer.GetWorldPosition(), 1.3), parent.GetWorldPosition(), 20, , , true, parent.master.settings.use_pathfinding_for_trails);
    parent.GotoState('Wandering');
  }
  
}

state Wandering in RandomEncountersReworkedHuntEntity {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RandomEncountersReworkedHuntEntity - State Wandering");
    this.Wandering_main();
  }
  
  entry function Wandering_main() {
    this.resetEntitiesActions();
    this.makeEntitiesMoveTowardsBait();
    this.resetEntitiesActions();
    parent.GotoState('Combat');
  }
  
  latent function makeEntitiesMoveTowardsBait() {
    var distance_from_player: float;
    var distance_from_bait: float;
    var current_entity: CEntity;
    var current_heading: float;
    var is_player_busy: bool;
    var i: int;
    parent.bait_entity.Teleport(parent.GetWorldPosition());
    do {
      if (SUH_areAllEntitiesDead(parent.entities)) {
        NLOG("HuntEntity - wandering state, all entities dead");
        parent.GotoState('Ending');
        break;
      }
      
      for (i = parent.entities.Size()-1; i>=0; i -= 1) {
        current_entity = parent.entities[i];
        
        is_player_busy = isPlayerInScene();
        
        distance_from_player = VecDistance(current_entity.GetWorldPosition(), thePlayer.GetWorldPosition());
        
        if (distance_from_player>parent.entity_settings.kill_threshold_distance) {
          NLOG("killing entity - threshold distance reached: "+parent.entity_settings.kill_threshold_distance);
          parent.killEntity(current_entity);
          continue;
        }
        
        
        if (distance_from_player<15 || distance_from_player<20 && ((CActor)(current_entity)).HasAttitudeTowards(thePlayer)) {
          return ;
        }
        
        
        distance_from_bait = VecDistanceSquared(current_entity.GetWorldPosition(), parent.bait_entity.GetWorldPosition());
        
        if (distance_from_bait<5*5) {
          if (is_player_busy) {
            teleportBaitEntityOnMonsters();
          }
          else  {
            this.teleportBaitEntity();
            
          }
          
        }
        
        
        if (is_player_busy) {
          ((CActor)(parent.entities[i])).SetTemporaryAttitudeGroup('q104_avallach_friendly_to_all', AGP_Default);
        }
        else if (!((CActor)(current_entity)).IsMoving()) {
          ((CActor)(parent.entities[i])).SetTemporaryAttitudeGroup('monsters', AGP_Default);
          
          ((CActor)(current_entity)).ActionCancelAll();
          
          ((CNewNPC)(current_entity)).NoticeActor((CActor)(parent.bait_entity));
          
        }
        
        
        parent.trail_maker.addTrackHere(current_entity.GetWorldPosition(), current_entity.GetWorldRotation());
      }
      
      if (parent.bait_moves_towards_player) {
        if (RER_moveCreaturesAwayIfPlayerIsInCutscene(parent.entities, 30)) {
          teleportBaitEntityOnMonsters();
        }
        else  {
          this.teleportBaitEntity();
          
        }
        
      }
      
      Sleep(0.5);
    } while (true);
    
  }
  
  private function teleportBaitEntity() {
    var new_bait_position: Vector;
    var new_bait_rotation: EulerAngles;
    if (parent.bait_moves_towards_player) {
      new_bait_position = thePlayer.GetWorldPosition();
      new_bait_rotation = parent.bait_entity.GetWorldRotation();
    }
    else  {
      new_bait_position = parent.getRandomEntity().GetWorldPosition()+VecConeRand(parent.bait_entity.GetHeading(), 90, 10, 20);
      
      new_bait_rotation = parent.bait_entity.GetWorldRotation();
      
      new_bait_rotation.Yaw += RandRange(-20, 20);
      
    }
    
    parent.bait_entity.TeleportWithRotation(new_bait_position, new_bait_rotation);
  }
  
  latent function teleportBaitEntityOnMonsters() {
    var new_bait_position: Vector;
    var new_bait_rotation: EulerAngles;
    var random_entity: CEntity;
    new_bait_position = parent.getRandomEntity().GetWorldPosition();
    new_bait_rotation = parent.bait_entity.GetWorldRotation();
    parent.bait_entity.TeleportWithRotation(new_bait_position, new_bait_rotation);
  }
  
  latent function resetEntitiesActions() {
    var i: int;
    var current_entity: CEntity;
    for (i = parent.entities.Size()-1; i>=0; i -= 1) {
      current_entity = parent.entities[i];
      
      ((CActor)(current_entity)).ActionCancelAll();
      
      ((CActor)(current_entity)).GetMovingAgentComponent().ResetMoveRequests();
      
      ((CActor)(current_entity)).GetMovingAgentComponent().SetGameplayMoveDirection(0.0);
    }
    
  }
  
}

struct HuntingGroundEntitySettings {
  var kill_threshold_distance: float;
  
  var allow_trophy_pickup_scene: bool;
  
}


statemachine class RandomEncountersReworkedHuntingGroundEntity extends CEntity {
  var master: CRandomEncounters;
  
  var entities: array<CEntity>;
  
  var bestiary_entry: RER_BestiaryEntry;
  
  var entity_settings: HuntingGroundEntitySettings;
  
  var bait_entity: CEntity;
  
  var manual_destruction: bool;
  
  var oneliner: RER_OnelinerEntity;
  
  public function startEncounter(master: CRandomEncounters, entities: array<CEntity>, bestiary_entry: RER_BestiaryEntry) {
    this.master = master;
    this.entities = entities;
    this.bestiary_entry = bestiary_entry;
    this.loadSettings(master);
    NLOG("starting RandomEncountersReworkedHuntingGroundEntity with "+entities.Size()+" "+bestiary_entry.type);
    this.addOneliner();
    this.GotoState('Loading');
  }
  
  private function addOneliner() {
    var first: CEntity;
    if (!theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERonelinersHuntingGround')) {
      return ;
    }
    
    if (this.entities.Size()>0) {
      first = this.entities[0];
      this.oneliner = RER_onelinerEntity((new SUOL_TagBuilder in thePlayer).tag("font").attr("color", "#9e9e9e").text(this.bestiary_entry.toLocalizedName()), first);
      this.oneliner.setRenderDistance(50);
    }
    
  }
  
  private function loadSettings(master: CRandomEncounters) {
    var bounty_manager: RER_BountyManager;
    var is_bounty: bool;
    var bounty_group_index: int;
    this.entity_settings.kill_threshold_distance = master.settings.kill_threshold_distance;
    this.entity_settings.allow_trophy_pickup_scene = master.settings.trophy_pickup_scene;
  }
  
  public var bounty_manager: RER_BountyManager;
  
  public var is_bounty: bool;
  
  public var bounty_group_index: int;
  
  public function activateBountyMode(bounty_manager: RER_BountyManager, group_index: int) {
    this.bounty_manager = bounty_manager;
    this.is_bounty = true;
    this.bounty_group_index = group_index;
    NLOG("activateBountyMode - "+group_index);
  }
  
  public latent function clean() {
    var i: int;
    NLOG("RandomEncountersReworkedHuntingGroundEntity destroyed");
    if (this.oneliner) {
      this.oneliner.unregister();
    }
    
    for (i = 0; i<this.entities.Size(); i += 1) {
      this.killEntity(this.entities[i]);
    }
    
    this.Destroy();
  }
  
  public function killEntity(entity: CEntity): bool {
    ((CActor)(entity)).Kill('RandomEncountersReworked_Entity', true);
    return this.entities.Remove(entity);
  }
  
  public function getRandomEntity(): CEntity {
    var entity: CEntity;
    entity = this.entities[RandRange(this.entities.Size())];
    return entity;
  }
  
}

state Combat in RandomEncountersReworkedHuntingGroundEntity {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RandomEncountersReworkedHuntingGroundEntity - State Combat");
    this.Combat_Main();
  }
  
  entry function Combat_Main() {
    SUH_resetEntitiesAttitudes(parent.entities);
    SUH_makeEntitiesTargetPlayer(parent.entities);
    while (SUH_waitUntilPlayerFinishesCombatStep(parent.entities)) {
      RER_moveCreaturesAwayIfPlayerIsInCutscene(parent.entities, 30);
      Sleep(1);
    }
    
    if (parent.entity_settings.allow_trophy_pickup_scene) {
      parent.master.requestOutOfCombatAction(OutOfCombatRequest_TROPHY_CUTSCENE);
    }
    
    this.Combat_goToNextState();
  }
  
  latent function Combat_goToNextState() {
    if (SUH_areAllEntitiesDead(parent.entities)) {
      parent.GotoState('Ending');
    }
    else  {
      parent.GotoState('Wandering');
      
    }
    
  }
  
}

state Ending in RandomEncountersReworkedHuntingGroundEntity {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RandomEncountersReworkedHuntingGroundEntity - State Ending");
    this.Ending_main();
  }
  
  entry function Ending_main() {
    var distance_from_player: float;
    distance_from_player = VecDistanceSquared2D(thePlayer.GetWorldPosition(), parent.GetWorldPosition());
    if (parent.is_bounty && distance_from_player<150*150) {
      if (parent.bounty_group_index<0) {
        parent.bounty_manager.notifyMainGroupKilled();
      }
      else  {
        parent.bounty_manager.notifySideGroupKilled(parent.bounty_group_index);
        
      }
      
    }
    
    if (VecDistanceSquared(thePlayer.GetWorldPosition(), parent.GetWorldPosition())<50*50) {
      RER_tryRefillRandomContainer(parent.master);
      RER_emitEncounterKilled(parent.master, EncounterType_HUNTINGGROUND);
    }
    else  {
      RER_emitEncounterRecycled(parent.master, EncounterType_HUNTINGGROUND);
      
    }
    
    if (!parent.manual_destruction) {
      parent.clean();
    }
    
  }
  
}

state Loading in RandomEncountersReworkedHuntingGroundEntity {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RandomEncountersReworkedHuntingGroundEntity - State Loading");
    this.Loading_main();
  }
  
  entry function Loading_main() {
    var template: CEntityTemplate;
    template = (CEntityTemplate)(LoadResourceAsync("characters\npc_entities\animals\hare.w2ent", true));
    parent.bait_entity = theGame.CreateEntity(template, parent.GetWorldPosition(), parent.GetWorldRotation());
    ((CNewNPC)(parent.bait_entity)).SetGameplayVisibility(false);
    ((CNewNPC)(parent.bait_entity)).SetVisibility(false);
    ((CActor)(parent.bait_entity)).EnableCharacterCollisions(false);
    ((CActor)(parent.bait_entity)).EnableDynamicCollisions(false);
    ((CActor)(parent.bait_entity)).EnableStaticCollisions(false);
    ((CActor)(parent.bait_entity)).SetImmortalityMode(AIM_Immortal, AIC_Default);
    ((CActor)(parent.bait_entity)).AddBuffImmunity_AllNegative('RandomEncountersReworked', false);
    parent.GotoState('Wandering');
  }
  
}

state Wandering in RandomEncountersReworkedHuntingGroundEntity {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RandomEncountersReworkedHuntingGroundEntity - State Wandering");
    this.Wandering_main();
  }
  
  entry function Wandering_main() {
    this.resetEntitiesActions();
    this.makeEntitiesMoveTowardsBait();
    this.resetEntitiesActions();
    parent.GotoState('Combat');
  }
  
  latent function makeEntitiesMoveTowardsBait() {
    var distance_from_player: float;
    var distance_from_bait: float;
    var current_entity: CEntity;
    var current_heading: float;
    var i: int;
    do {
      if (SUH_areAllEntitiesDead(parent.entities)) {
        NLOG("HuntingGroundEntity - wandering state, all entities dead");
        parent.GotoState('Ending');
        break;
      }
      
      parent.bait_entity.Teleport(parent.GetWorldPosition());
      if (!thePlayer.IsInCombat()) {
        SUH_keepCreaturesOnPoint(parent.GetWorldPosition(), 25, parent.entities);
      }
      
      for (i = parent.entities.Size()-1; i>=0; i -= 1) {
        current_entity = parent.entities[i];
        
        distance_from_player = VecDistance(current_entity.GetWorldPosition(), thePlayer.GetWorldPosition());
        
        if (!parent.is_bounty && distance_from_player>parent.entity_settings.kill_threshold_distance) {
          NLOG("killing entity - threshold distance reached: "+parent.entity_settings.kill_threshold_distance);
          parent.killEntity(current_entity);
          continue;
        }
        
        
        if (distance_from_player<15 || distance_from_player<20 && ((CActor)(current_entity)).HasAttitudeTowards(thePlayer)) {
          return ;
        }
        
        
        distance_from_bait = VecDistanceSquared(current_entity.GetWorldPosition(), parent.bait_entity.GetWorldPosition());
        
        if (distance_from_bait>20*20) {
          ((CActor)(parent.entities[i])).SetTemporaryAttitudeGroup('monsters', AGP_Default);
          ((CActor)(current_entity)).ActionCancelAll();
          ((CNewNPC)(current_entity)).NoticeActor((CActor)(parent.bait_entity));
        }
        
      }
      
      Sleep(3);
    } while (true);
    
  }
  
  function keepCreaturesOnPoint(position: Vector, radius: float) {
    var distance_from_point: float;
    var old_position: Vector;
    var new_position: Vector;
    var i: int;
    for (i = 0; i<parent.entities.Size(); i += 1) {
      old_position = parent.entities[i].GetWorldPosition();
      
      distance_from_point = VecDistanceSquared(old_position, position);
      
      if (distance_from_point>radius) {
        new_position = VecInterpolate(old_position, position, 1/radius);
        FixZAxis(new_position);
        if (new_position.Z<old_position.Z) {
          new_position.Z = old_position.Z;
        }
        
        parent.entities[i].Teleport(new_position);
      }
      
    }
    
  }
  
  latent function resetEntitiesActions() {
    var i: int;
    var current_entity: CEntity;
    for (i = parent.entities.Size()-1; i>=0; i -= 1) {
      current_entity = parent.entities[i];
      
      ((CActor)(current_entity)).ActionCancelAll();
      
      ((CActor)(current_entity)).GetMovingAgentComponent().ResetMoveRequests();
      
      ((CActor)(current_entity)).GetMovingAgentComponent().SetGameplayMoveDirection(0.0);
    }
    
  }
  
}

struct ContractEntitySettings {
  var kill_threshold_distance: float;
  
  var allow_trophies: bool;
  
  var allow_trophy_pickup_scene: bool;
  
  var enable_loot: bool;
  
}


statemachine class RER_MonsterNest extends CMonsterNestEntity {
  var master: CRandomEncounters;
  
  var entities: array<CEntity>;
  
  var entity_settings: ContractEntitySettings;
  
  var is_destroyed: bool;
  
  var bestiary_entry: RER_BestiaryEntry;
  
  var forced_bestiary_entry: bool;
  
  var forced_species: RER_SpeciesTypes;
  
  default forced_species = SpeciesTypes_NONE;
  
  var monsters_spawned_count: int;
  
  var disable_monsters_loot_threshold: int;
  
  default disable_monsters_loot_threshold = 10;
  
  var monsters_spawned_limit: int;
  
  default monsters_spawned_limit = 15;
  
  var pin_position: Vector;
  
  function startEncounter(master: CRandomEncounters) {
    this.master = master;
    this.loadSettings(master);
    this.AddTimer('intervalLifeCheck', 10.0, true);
    this.GotoState('Loading');
  }
  
  private function loadSettings(master: CRandomEncounters) {
    this.entity_settings.kill_threshold_distance = master.settings.kill_threshold_distance;
    this.entity_settings.allow_trophy_pickup_scene = master.settings.trophy_pickup_scene;
    this.entity_settings.allow_trophies = master.settings.trophies_enabled_by_encounter[EncounterType_CONTRACT];
    this.entity_settings.enable_loot = master.settings.enable_encounters_loot;
    this.disable_monsters_loot_threshold = 5;
    if (master.settings.selectedDifficulty==RER_Difficulty_RANDOM) {
      this.monsters_spawned_limit = RandRange((((int)(RER_Difficulty_HARD))+1)*4, (((int)(RER_Difficulty_EASY))+1)*4);
    }
    else  {
      this.monsters_spawned_limit = RandRange((((int)(master.settings.selectedDifficulty))+1)*4, (((int)(master.settings.selectedDifficulty))+1)*3);
      
    }
    
  }
  
  event OnSpawned(spawnData: SEntitySpawnData) {
  }
  
  event OnAreaEnter(area: CTriggerAreaComponent, activator: CComponent) {
    if (area!=((CTriggerAreaComponent)(this.GetComponent("VoiceSetTrigger"))) || !this.CanPlayVoiceSet() || this.voicesetPlayed) {
      return false;
    }
    
    SUH_makeEntitiesTargetPlayer(this.entities);
    this.l_enginetime = theGame.GetEngineTimeAsSeconds();
    if (l_enginetime>this.voicesetTime+60.0) {
      this.voicesetTime = this.l_enginetime;
      this.voicesetPlayed = true;
      this.GotoState('Talking');
    }
    else if (GetCurrentStateName()!='Spawning') {
      this.GotoState('Spawning');
      
    }
    
  }
  
  event OnFireHit(source: CGameplayEntity) {
    if (wasExploded) {
      return false;
    }
    
    GetEncounter();
    wasExploded = true;
    airDmg = false;
    this.GotoState('Explosion');
  }
  
  event OnAardHit(sign: W3AardProjectile) {
  }
  
  event OnInteraction(actionName: string, activator: CEntity) {
    if (activator!=thePlayer || !thePlayer.CanPerformPlayerAction()) {
      return false;
    }
    
    if (interactionComponent && wasExploded && interactionComponent.IsEnabled()) {
      interactionComponent.SetEnabled(false);
    }
    
    if (!PlayerHasBombActivator()) {
      GetWitcherPlayer().DisplayHudMessage(GetLocStringByKeyExt("panel_hud_message_destroy_nest_bomb_lacking"));
      messageTimestamp = theGame.GetEngineTimeAsSeconds();
      return false;
    }
    
    if (interactionComponent && interactionComponent.IsEnabled()) {
      wasExploded = true;
      GetEncounter();
      interactionComponent.SetEnabled(false);
      GotoState('SettingExplosives');
    }
    
    return true;
  }
  
  latent function getRandomNestCreatureType(master: CRandomEncounters): RER_BestiaryEntry {
    var filter: RER_SpawnRollerFilter;
    var bentry: RER_BestiaryEntry;
    var i: int;
    filter = (new RER_SpawnRollerFilter in this).init().removeEveryone();
    for (i = 0; i<CreatureMAX; i += 1) {
      if (RER_isCreatureTypeAllowedForNest(i)) {
        filter.allowCreature(i);
      }
      
    }
    
    if (this.forced_species!=SpeciesTypes_NONE) {
      for (i = 0; i<master.bestiary.entries.Size(); i += 1) {
        if (master.bestiary.entries[i].species!=this.forced_species) {
          filter.removeCreature(i);
        }
        
      }
      
    }
    
    bentry = master.bestiary.getRandomEntryFromBestiary(master, EncounterType_CONTRACT, RER_BREF_IGNORE_SETTLEMENT);
    return bentry;
  }
  
  timer function intervalLifeCheck(optional dt: float, optional id: Int32) {
    var distance_from_player: float;
    if (this.GetCurrentStateName()=='Ending') {
      return ;
    }
    
    distance_from_player = VecDistance(this.GetWorldPosition(), thePlayer.GetWorldPosition());
    if (distance_from_player>this.entity_settings.kill_threshold_distance) {
      NLOG("killing entity - threshold distance reached: "+this.entity_settings.kill_threshold_distance);
      this.endEncounter();
      return ;
    }
    
  }
  
  public function endEncounter() {
    if (this.GetCurrentStateName()!='Ending') {
      this.GotoState('Ending');
    }
    
  }
  
  public latent function clean() {
    var i: int;
    NLOG("RER_MonsterNest destroyed");
    this.RemoveTimer('intervalLifeCheck');
    for (i = 0; i<this.entities.Size(); i += 1) {
      ((CActor)(this.entities[i])).Kill('RandomEncountersReworkedContractEntity', true);
    }
    
    this.Destroy();
  }
  
}


function RER_isCreatureTypeAllowedForNest(type: CreatureType): bool {
  var output: bool;
  switch (type) {
    case CreatureENDREGA:
    case CreatureGHOUL:
    case CreatureALGHOUL:
    case CreatureNEKKER:
    case CreatureDROWNER:
    case CreatureROTFIEND:
    case CreatureWOLF:
    case CreatureHARPY:
    case CreatureSPIDER:
    case CreatureDROWNERDLC:
    case CreatureBOAR:
    case CreatureSKELWOLF:
    case CreatureSIREN:
    output = true;
    break;
    
    default:
    output = false;
    break;
  }
  return output;
}

state Ending in RER_MonsterNest {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_MonsterNest - State Ending");
    this.Ending_main();
  }
  
  entry function Ending_main() {
    Sleep(1);
    if (VecDistanceSquared(parent.GetWorldPosition(), thePlayer.GetWorldPosition())<50*50) {
      RER_tryRefillRandomContainer(parent.master);
      RER_emitEncounterKilled(parent.master, EncounterType_HUNTINGGROUND);
    }
    else  {
      RER_emitEncounterRecycled(parent.master, EncounterType_HUNTINGGROUND);
      
    }
    
    parent.clean();
  }
  
}

state Explosion in RER_MonsterNest {
  event OnEnterState(prevStateName: name) {
    NLOG("RER_MonsterNest - State EXPLOSION");
    parent.canPlayVset = false;
    Explosion();
  }
  
  entry function Explosion() {
    var wasDestroyed: bool;
    var parentEntity: CR4MapPinEntity;
    var commonMapManager: CCommonMapManager;
    var l_pos: Vector;
    commonMapManager = theGame.GetCommonMapManager();
    ProcessExplosion();
    SleepOneFrame();
    if (parent.appearanceChangeDelayAfterExplosion>0) {
      Sleep(parent.appearanceChangeDelayAfterExplosion);
    }
    
    parent.ApplyAppearance('nest_destroyed');
    if (parent.lootOnNestDestroyed) {
      l_pos = parent.GetWorldPosition();
      l_pos.Z += 0.5;
      parent.container = (W3Container)(theGame.CreateEntity(parent.lootOnNestDestroyed, l_pos, parent.GetWorldRotation()));
    }
    
    parent.SetFocusModeVisibility(0);
    if (parent.IsSetDestructionFactImmediately()) {
      FactsAdd(parent.factSetAfterSuccessfulDestruction, 1);
    }
    
    wasDestroyed = parent.HasTag('WasDestroyed');
    parent.AddTag('WasDestroyed');
    parentEntity = (CR4MapPinEntity)(parent);
    if (!wasDestroyed && !parent.HasTag('AchievementFireInTheHoleExcluded')) {
      theGame.GetGamerProfile().IncStat(ES_DestroyedNests);
    }
    
    commonMapManager.SetEntityMapPinDisabled(parent.entityName, true);
    parent.AddExp();
    if (!parent.airDmg) {
      parent.PlayEffect('fire');
    }
    else  {
      parent.PlayEffect('dust');
      
    }
    
    if (parent.nestBurnedAfter!=0) {
      Sleep(parent.nestBurnedAfter);
    }
    
    if (!parent.IsSetDestructionFactImmediately()) {
      FactsAdd(parent.factSetAfterSuccessfulDestruction, 1);
    }
    
    parent.GotoState('NestDestroyed');
  }
  
  private function ProcessExplosion() {
    ProcessExplosionEffects();
    if (parent.shouldDealDamageOnExplosion) {
      ProcessExplosionDamage();
    }
    
  }
  
  private function ProcessExplosionEffects() {
    if (parent.shouldPlayFXOnExplosion && !parent.airDmg) {
      parent.PlayEffect('explosion');
    }
    
    GCameraShake(0.5, true, parent.GetWorldPosition(), 1.0);
    parent.StopEffect('deploy');
  }
  
  private function ProcessExplosionDamage() {
    var damage: W3DamageAction;
    var entitiesInRange: array<CGameplayEntity>;
    var explosionRadius: float;
    var damageVal: float;
    var i: int;
    explosionRadius = 3.0;
    damageVal = 50.0;
    FindGameplayEntitiesInSphere(entitiesInRange, parent.GetWorldPosition(), explosionRadius, 100);
    entitiesInRange.Remove(parent);
    for (i = 0; i<entitiesInRange.Size(); i += 1) {
      if (entitiesInRange[i]==thePlayer && thePlayer.CanUseSkill(S_Perk_16)) {
        continue;
      }
      
      
      if ((CActor)(entitiesInRange[i])) {
        damage = new W3DamageAction in parent;
        damage.Initialize(parent, entitiesInRange[i], NULL, parent, EHRT_None, CPS_Undefined, false, false, false, true);
        damage.AddDamage(theGame.params.DAMAGE_NAME_FIRE, damageVal);
        damage.AddEffectInfo(EET_Burning);
        damage.AddEffectInfo(EET_Stagger);
        theGame.damageMgr.ProcessAction(damage);
        delete damage;
      }
      else  {
        entitiesInRange[i].OnFireHit(parent);
        
      }
      
    }
    
  }
  
}

state Loading in RER_MonsterNest {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_MonsterNest - State Loading");
    this.Loading_main();
  }
  
  entry function Loading_main() {
    var entities: array<CEntity>;
    if (!parent.forced_bestiary_entry) {
      parent.bestiary_entry = parent.getRandomNestCreatureType(parent.master);
      if (parent.bestiary_entry.type==CreatureARACHAS) {
        parent.monsters_spawned_limit /= 3;
      }
      
      if (parent.bestiary_entry.type==CreatureWRAITH) {
        parent.monsters_spawned_limit /= 2;
      }
      
    }
    
    entities.PushBack((CEntity)(parent));
    RER_addKillingSpreeCustomLootToEntities(parent.master.loot_manager, entities, 1.5);
    this.placeMarker();
    parent.GotoState('Spawning');
  }
  
  function placeMarker() {
    var can_show_markers: bool;
    var map_pin: SU_MapPin;
    var position: Vector;
    can_show_markers = theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERmarkersContractFirstPhase');
    if (can_show_markers) {
      position = parent.GetWorldPosition()+VecRingRand(0, 50);
      map_pin = new SU_MapPin in thePlayer;
      map_pin.tag = "RER_nest_contract_target";
      map_pin.position = position;
      map_pin.description = GetLocStringByKey("rer_mappin_regular_description");
      map_pin.label = GetLocStringByKey("rer_mappin_regular_title");
      map_pin.type = "TreasureQuest";
      map_pin.filtered_type = "TreasureQuest";
      map_pin.radius = 100;
      map_pin.region = SUH_getCurrentRegion();
      map_pin.appears_on_minimap = theGame.GetInGameConfigWrapper().GetVarValue('RERoptionalFeatures', 'RERminimapMarkerGenericObjectives');
      SUMP_addCustomPin(map_pin);
      parent.pin_position = position;
      SU_updateMinimapPins();
    }
    
  }
  
}

state NestDestroyed in RER_MonsterNest {
  event OnEnterState(prevStateName: name) {
    var commonMapManager: CCommonMapManager;
    NLOG("RER_MonsterNest - State NESTDESTROYED");
    commonMapManager = theGame.GetCommonMapManager();
    parent.StopAllEffects();
    parent.encounter.EnableEncounter(false);
    this.NestDestroyed_main();
  }
  
  entry function NestDestroyed_main() {
    parent.is_destroyed = true;
    RER_removePinsInAreaAndWithTag("RER_nest_contract_target", parent.pin_position, 50);
  }
  
}

state SettingExplosives in RER_MonsterNest {
  event OnEnterState(prevStateName: name) {
    NLOG("RER_MonsterNest - State SETTINGEXPLOSIVES");
    if (ShouldProcessTutorial('TutorialMonsterNest')) {
      FactsAdd("tut_nest_blown");
    }
    
    PlayAnimationAndSetExplosives();
  }
  
  entry function PlayAnimationAndSetExplosives() {
    var movementAdjustor: CMovementAdjustor;
    var ticket: SMovementAdjustmentRequestTicket;
    movementAdjustor = thePlayer.GetMovingAgentComponent().GetMovementAdjustor();
    ticket = movementAdjustor.CreateNewRequest('InteractionEntity');
    thePlayer.OnHolsterLeftHandItem();
    thePlayer.AddAnimEventChildCallback(parent, 'AttachBomb', 'OnAnimEvent_AttachBomb');
    thePlayer.AddAnimEventChildCallback(parent, 'DetachBomb', 'OnAnimEvent_DetachBomb');
    movementAdjustor.AdjustmentDuration(ticket, 0.5);
    if (parent.matchPlayerHeadingWithHeadingOfTheEntity) {
      movementAdjustor.RotateTowards(ticket, parent);
    }
    
    if (parent.desiredPlayerToEntityDistance>=0) {
      movementAdjustor.SlideTowards(ticket, parent, parent.desiredPlayerToEntityDistance);
    }
    
    thePlayer.PlayerStartAction(PEA_SetBomb);
    parent.BlockPlayerNestInteraction();
    Sleep(parent.settingExplosivesTime);
    parent.playerInventory.SingletonItemRemoveAmmo(parent.usedBomb, 1);
    Sleep(parent.explodeAfter);
    parent.GotoState('Explosion');
  }
  
}

state Spawning in RER_MonsterNest {
  event OnEnterState(prevStateName: name) {
    NLOG("RER_MonsterNest - State SPAWNING");
    this.Spawning_main();
  }
  
  entry function Spawning_main() {
    if (!parent.bestiary_entry) {
      parent.bestiary_entry = parent.getRandomNestCreatureType(parent.master);
    }
    
    this.spawnEntities();
    while (parent.monsters_spawned_count<parent.monsters_spawned_limit) {
      NLOG("RER_MonsterNest - spawning monster");
      Sleep(RandRange(8, 3));
      SUH_removeDeadEntities(parent.entities);
      if (!parent.voicesetPlayed && parent.entities.Size()>2) {
        continue;
      }
      
      if (parent.entities.Size()>5) {
        continue;
      }
      
      this.spawnEntities();
    }
    
  }
  
  latent function spawnEntities() {
    var entities: array<CEntity>;
    var position: Vector;
    var entity: CEntity;
    var i: int;
    if (!parent.voicesetPlayed || !getRandomPositionBehindCamera(position, 10, 5)) {
      position = parent.GetWorldPosition()+VecRingRand(0, 5);
    }
    
    entities = parent.bestiary_entry.spawn(parent.master, position, RandRange(2), , EncounterType_HUNTINGGROUND, RER_BESF_NO_PERSIST);
    for (i = 0; i<entities.Size(); i += 1) {
      parent.entities.PushBack(entities[i]);
      
      parent.monsters_spawned_count += 1;
      
      if (parent.monsters_spawned_count>parent.disable_monsters_loot_threshold) {
        ((CActor)(entities[i])).GetInventory().EnableLoot(false);
      }
      
    }
    
  }
  
}

state Talking in RER_MonsterNest {
  event OnEnterState(prevStateName: name) {
    NLOG("RER_MonsterNest - State TALKING");
    super.OnEnterState(prevStateName);
    this.Talking_main();
  }
  
  entry function Talking_main() {
    (new RER_RandomDialogBuilder in thePlayer).start().either(new REROL_more_will_spawn in this, true, 1).either(new REROL_here_is_the_nest in this, true, 1).either(new REROL_finally_the_main_nest in this, true, 1).either(new REROL_good_place_for_their_nest in this, true, 1).either(new REROL_monster_nest_best_destroyed in this, true, 1).play();
    parent.GotoState('Spawning');
  }
  
}

function RER_showCompanionIndicator(npc_tag: name, optional icon_path: string) {
  var hud: CR4ScriptedHud;
  var companionModule: CR4HudModuleCompanion;
  var npc: CNewNPC;
  npc = theGame.GetNPCByTag(npc_tag);
  if (!npc) {
    return ;
  }
  
  hud = (CR4ScriptedHud)(theGame.GetHud());
  if (hud) {
    companionModule = (CR4HudModuleCompanion)(hud.GetHudModule("CompanionModule"));
    if (companionModule) {
      companionModule.ShowCompanion(true, npc_tag, icon_path);
      if (npc.GetStat(BCS_Essence, true)<0) {
        if (theGame.GetDifficultyMode()==EDM_Hard && !npc.HasAbility('_combatFollowerHardV')) {
          npc.AddAbility('_combatFollowerHardV', false);
        }
        else if (theGame.GetDifficultyMode()==EDM_Hardcore && !npc.HasAbility('_combatFollowerHardcoreV')) {
          npc.AddAbility('_combatFollowerHardcoreV', false);
          
        }
        
      }
      else if (npc.GetStat(BCS_Vitality, true)<0) {
        if (theGame.GetDifficultyMode()==EDM_Hard && !npc.HasAbility('_combatFollowerHardE')) {
          npc.AddAbility('_combatFollowerHardE', false);
        }
        else if (theGame.GetDifficultyMode()==EDM_Hardcore && !npc.HasAbility('_combatFollowerHardcoreE')) {
          npc.AddAbility('_combatFollowerHardcoreE', false);
          
        }
        
        
      }
      
    }
    
  }
  
}


function RER_hideCompanionIndicator(npc_tag: name, optional icon_path: string) {
  var hud: CR4ScriptedHud;
  var companionModule: CR4HudModuleCompanion;
  hud = (CR4ScriptedHud)(theGame.GetHud());
  if (hud) {
    companionModule = (CR4HudModuleCompanion)(hud.GetHudModule("CompanionModule"));
    if (companionModule) {
      companionModule.ShowCompanion(false, npc_tag, icon_path);
    }
    
  }
  
}

class RER_ContractBackToCampConfirmation extends ConfirmationPopupData {
  var destination: Vector;
  
  var finished: bool;
  
  public latent function open(destination: Vector) {
    this.destination = destination;
    this.SetMessageTitle(GetLocStringByKey("rer_confirm_back_to_camp_title"));
    this.SetMessageText(GetLocStringByKey("rer_confirm_back_to_camp_description"));
    theGame.RequestMenu('PopupMenu', this);
    this.waitUntilClosed();
  }
  
  private latent function waitUntilClosed() {
    while (!this.finished) {
      SleepOneFrame();
    }
    
  }
  
  protected function OnUserAccept(): void {
    ClosePopup();
    theGame.Unpause("Popup");
    this.lootNearbyBags();
    thePlayer.Teleport(this.destination);
    this.finished = true;
  }
  
  protected function OnUserDecline(): void {
    ClosePopup();
    theGame.Unpause("Popup");
    this.finished = true;
  }
  
  private function lootNearbyBags() {
    var entities: array<CGameplayEntity>;
    var entity: CGameplayEntity;
    var idx6cbeeb7b35314bac839500090ab97a88: int;
    FindGameplayEntitiesInRange(entities, thePlayer, 25, 30, , FLAG_ExcludePlayer);
    for (idx6cbeeb7b35314bac839500090ab97a88 = 0; idx6cbeeb7b35314bac839500090ab97a88 < entities.Size(); idx6cbeeb7b35314bac839500090ab97a88 += 1) {
      entity = entities[idx6cbeeb7b35314bac839500090ab97a88];
      if ((W3Container)(entity)) {
        ((W3Container)(entity)).TakeAllItems();
      }
      
    }
  }
  
}

function copyEnemyTemplateList(list_to_copy: EnemyTemplateList): EnemyTemplateList {
  var copy: EnemyTemplateList;
  var i: int;
  copy.difficulty_factor = list_to_copy.difficulty_factor;
  for (i = 0; i<list_to_copy.templates.Size(); i += 1) {
    copy.templates.PushBack(makeEnemyTemplate(list_to_copy.templates[i].template, list_to_copy.templates[i].max, list_to_copy.templates[i].count, list_to_copy.templates[i].bestiary_entry));
  }
  
  return copy;
}

function getCreatureNameFromCreatureType(bestiary: RER_Bestiary, type: CreatureType): string {
  if (type>=CreatureMAX) {
    return GetLocStringByKey("rer_unknown");
  }
  
  return bestiary.entries[type].toLocalizedName();
}

function RER_toggleDebug(value: bool) {
  var config: CInGameConfigWrapper;
  config = theGame.GetInGameConfigWrapper();
  if (value) {
    config.ActivateScriptTag('RER_Debug');
  }
  else  {
    config.DeactivateScriptTag('RER_Debug');
    
  }
  
}

latent function fillEnemyTemplateList(enemy_template_list: EnemyTemplateList, total_number_of_enemies: int, optional use_bestiary: bool): EnemyTemplateList {
  var template_list: EnemyTemplateList;
  var selected_template_to_increment: int;
  var max_tries: int;
  var i: int;
  var manager: CWitcherJournalManager;
  var can_spawn_creature: bool;
  template_list = copyEnemyTemplateList(enemy_template_list);
  max_tries = 0;
  for (i = 0; i<template_list.templates.Size(); i += 1) {
    if (template_list.templates[i].max==0) {
      max_tries = total_number_of_enemies*2;
      break;
    }
    
    
    max_tries += template_list.templates[i].max;
  }
  
  NLOG("maximum number of tries: "+max_tries+" use bestiary = "+use_bestiary);
  if (use_bestiary) {
    manager = theGame.GetJournalManager();
    max_tries *= 2;
  }
  
  while (total_number_of_enemies>0 && max_tries>0) {
    max_tries -= 1;
    selected_template_to_increment = RandRange(template_list.templates.Size());
    NLOG("selected template: "+selected_template_to_increment);
    if (template_list.templates[selected_template_to_increment].max>0 && template_list.templates[selected_template_to_increment].count>=template_list.templates[selected_template_to_increment].max) {
      continue;
    }
    
    if (use_bestiary) {
      can_spawn_creature = bestiaryCanSpawnEnemyTemplate(template_list.templates[selected_template_to_increment], manager);
      if (!can_spawn_creature) {
        continue;
      }
      
    }
    
    NLOG("template "+selected_template_to_increment+" +1");
    template_list.templates[selected_template_to_increment].count += 1;
    total_number_of_enemies -= 1;
  }
  
  return template_list;
}

function RER_flagEnabled(flag: int, value: int): bool {
  return (flag&value)!=0;
}


function RER_maskFlag(flag: int, mask: int): int {
  return flag&mask;
}


function RER_setFlag(flag: int, value: int, should_add: bool): int {
  if (should_add) {
    return flag|value;
  }
  
  return flag;
}


function RER_flag(value: int, should_add: bool): int {
  if (should_add) {
    return value;
  }
  
  return 0;
}

function getCreatureHeight(entity: CActor): float {
  return ((CMovingPhysicalAgentComponent)(entity.GetMovingAgentComponent())).GetCapsuleHeight();
}

function getGroundPosition(out input_position: Vector, optional personal_space: float, optional radius: float): bool {
  var found_viable_position: bool;
  var collision_normal: Vector;
  var max_height_check: float;
  var output_position: Vector;
  var point_z: float;
  var attempts: int;
  attempts = 10;
  output_position = input_position;
  personal_space = MaxF(personal_space, 1.0);
  max_height_check = 30.0;
  if (radius==0) {
    radius = 10.0;
  }
  
  do {
    attempts -= 1;
    theGame.GetWorld().NavigationComputeZ(output_position, output_position.Z-max_height_check, output_position.Z+max_height_check, point_z);
    output_position.Z = point_z;
    if (!theGame.GetWorld().NavigationFindSafeSpot(output_position, personal_space, radius, output_position)) {
      continue;
    }
    
    if (output_position.Z<theGame.GetWorld().GetWaterLevel(output_position, true)) {
      continue;
    }
    
    found_viable_position = true;
    break;
  } while (attempts>0);
  
  if (found_viable_position) {
    input_position = output_position;
    return true;
  }
  
  return false;
}

function getGroupPositions(initial_position: Vector, count: int, density: float): array<Vector> {
  var s: float;
  var r: float;
  var x: float;
  var y: float;
  var pos_fin: Vector;
  var output_positions: array<Vector>;
  var i: int;
  var sign: int;
  pos_fin.Z = initial_position.Z;
  s = count/density;
  r = SqrtF(s/Pi());
  for (i = 0; i<count; i += 1) {
    x = RandF()*r;
    
    y = RandF()*(r-x);
    
    if (RandRange(2)) {
      sign = 1;
    }
    else  {
      sign = -1;
      
    }
    
    
    pos_fin.X = initial_position.X+sign*x;
    
    if (RandRange(2)) {
      sign = 1;
    }
    else  {
      sign = -1;
      
    }
    
    
    pos_fin.Y = initial_position.Y+sign*y;
    
    if (!getGroundPosition(pos_fin)) {
      pos_fin = initial_position;
    }
    
    
    output_positions.PushBack(pos_fin);
  }
  
  return output_positions;
}

latent function getTracksTemplateByCreatureType(create_type: CreatureType): RER_TrailMakerTrack {
  var track: RER_TrailMakerTrack;
  track = RER_TrailMakerTrack();
  switch (create_type) {
    case CreatureBARGHEST:
    case CreatureNIGHTWRAITH:
    case CreatureNOONWRAITH:
    case CreatureWRAITH:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueNightwraith';
    return track;
    break;
    
    case CreatureHUMAN:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\generic_footprints_clue.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueHuman';
    break;
    
    case CreatureDROWNER:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueDrowner';
    break;
    
    case CreatureDROWNERDLC:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueDrowner';
    break;
    
    case CreatureROTFIEND:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueRotfiend';
    break;
    
    case CreatureNEKKER:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueNekker';
    break;
    
    case CreatureGHOUL:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueGhoul';
    break;
    
    case CreatureALGHOUL:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueAlghoul';
    break;
    
    case CreatureFIEND:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueFiend';
    break;
    
    case CreatureCHORT:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueChort';
    break;
    
    case CreatureWEREWOLF:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueWerewolf';
    break;
    
    case CreatureLESHEN:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueLeshen';
    break;
    
    case CreatureKATAKAN:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueKatakan';
    break;
    
    case CreatureEKIMMARA:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueEkimmara';
    break;
    
    case CreatureELEMENTAL:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueElemental';
    break;
    
    case CreatureGOLEM:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueGolem';
    break;
    
    case CreatureGIANT:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueGiant';
    break;
    
    case CreatureCYCLOP:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueCyclop';
    break;
    
    case CreatureGRYPHON:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueGryphon';
    break;
    
    case CreatureWYVERN:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueWyvern';
    break;
    
    case CreatureCOCKATRICE:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueCockatrice';
    break;
    
    case CreatureBASILISK:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueBasilisk';
    break;
    
    case CreatureFORKTAIL:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueForktail';
    break;
    
    case CreatureWIGHT:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueWight';
    break;
    
    case CreatureSHARLEY:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueSharley';
    break;
    
    case CreatureHAG:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueHag';
    break;
    
    case CreatureFOGLET:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueFoglet';
    break;
    
    case CreatureTROLL:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueTroll';
    break;
    
    case CreatureBRUXA:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueBruxa';
    break;
    
    case CreatureDETLAFF:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueDetlaff';
    break;
    
    case CreatureGARKAIN:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueGarkain';
    break;
    
    case CreatureFLEDER:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueFleder';
    break;
    
    case CreatureGARGOYLE:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueGargoyle';
    break;
    
    case CreatureKIKIMORE:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh102_arachas_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueKikimore';
    break;
    
    case CreatureCENTIPEDE:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh102_arachas_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueCentipede';
    break;
    
    case CreatureBERSERKER:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh102_arachas_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueBerserker';
    break;
    
    case CreatureWOLF:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueWolf';
    break;
    
    case CreatureBEAR:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueBear';
    break;
    
    case CreatureBOAR:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueBoar';
    break;
    
    case CreaturePANTHER:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueBoar';
    break;
    
    case CreatureSPIDER:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueBoar';
    break;
    
    case CreatureWILDHUNT:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueWildhunt';
    break;
    
    case CreatureARACHAS:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh102_arachas_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueArachas';
    break;
    
    case CreatureHARPY:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueHarpy';
    break;
    
    case CreatureSIREN:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueSiren';
    break;
    
    case CreatureENDREGA:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh102_arachas_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueEndrega';
    break;
    
    case CreatureECHINOPS:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh102_arachas_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueEchinops';
    break;
    
    case CreatureDRACOLIZARD:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClueDracolizard';
    break;
    
    default:
    track.template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\tracks\mh202_nekker_tracks.w2ent", true));
    track.monster_clue_type = 'RER_MonsterClue';
    break;
  }
  return track;
}

function isPlayerBusy(): bool {
  return thePlayer.IsInInterior() || thePlayer.IsInCombat() || thePlayer.IsUsingBoat() || thePlayer.IsSwimming() || isPlayerInScene();
}


function isPlayerInScene(): bool {
  return thePlayer.IsInNonGameplayCutscene() || thePlayer.IsInGameplayScene() || (!RER_isCustomPlayerCharacter() && !thePlayer.IsActionAllowed(EIAB_DrawWeapon)) || thePlayer.IsCiri() || theGame.IsDialogOrCutscenePlaying() || theGame.IsCurrentlyPlayingNonGameplayScene() || theGame.IsFading() || theGame.IsBlackscreen() || thePlayer.IsInFistFightMiniGame();
}


function RER_isCustomPlayerCharacter(): bool {
  return FactsQuerySum("nr_player_type")==5;
}

function lootTrophiesInRadius(): bool {
  var entities: array<CGameplayEntity>;
  var items_guids: array<SItemUniqueId>;
  var looted_a_trophy: bool;
  var i: int;
  var guid_used_for_notification: SItemUniqueId;
  looted_a_trophy = false;
  NLOG("searching lootbag nearby");
  FindGameplayEntitiesInRange(entities, thePlayer, 25, 30, , FLAG_ExcludePlayer);
  for (i = 0; i<entities.Size(); i += 1) {
    if (((W3Container)(entities[i]))) {
      NLOG("lootbag - giving all RER_Trophy to player");
      items_guids = ((W3Container)(entities[i])).GetInventory().GetItemsByTag('RER_Trophy');
      looted_a_trophy = looted_a_trophy || items_guids.Size()>0;
      if (items_guids.Size()>0) {
        guid_used_for_notification = items_guids[0];
      }
      
      NLOG("lootbag - found "+items_guids.Size()+" trophies");
      ((W3Container)(entities[i])).GetInventory().GiveItemsTo(thePlayer.GetInventory(), items_guids);
    }
    
  }
  
  return looted_a_trophy;
}

function RER_modPowerIsEncounterSystemEnabled(mod_power: float): bool {
  return mod_power>=0.1;
}


function RER_modPowerIsStaticEncounterSystemEnabled(mod_power: float): bool {
  return RER_modPowerIsEncounterSystemEnabled(mod_power);
}


function RER_modPowerIsContractSystemEnabled(mod_power: float): bool {
  return mod_power>=0.2;
}


function RER_modPowerIsBountySystemEnabled(mod_power: float): bool {
  return mod_power>=0.3;
}


function RER_modPowerIsEventSystemEnabled(mod_power: float): bool {
  return mod_power>=0.4;
}

function RER_moveCreaturesAwayIfPlayerIsInCutscene(entities: array<CEntity>, radius: float): bool {
  var player_position: Vector;
  var squared_distance: float;
  var squared_radius: float;
  var position: Vector;
  var i: int;
  if (!isPlayerInScene()) {
    return false;
  }
  
  squared_radius *= radius;
  player_position = thePlayer.GetWorldPosition();
  for (i = 0; i<entities.Size(); i += 1) {
    squared_distance = VecDistanceSquared2D(player_position, entities[i].GetWorldPosition());
    
    if (squared_distance<squared_radius) {
      if (!getRandomPositionBehindCamera(position, radius)) {
        SUH_keepCreaturesOutsidePoint(thePlayer.GetWorldPosition(), 30, entities);
        return true;
      }
      
      for (i = 0; i<entities.Size(); i += 1) {
        entities[i].Teleport(position);
      }
      
      return true;
    }
    
  }
  
  return false;
}

class RER_PopupData extends BookPopupFeedback {
  public function GetGFxData(parentFlashValueStorage: CScriptedFlashValueStorage): CScriptedFlashObject {
    var objResult: CScriptedFlashObject;
    objResult = super.GetGFxData(parentFlashValueStorage);
    objResult.SetMemberFlashString("iconPath", "img://icons/inventory/scrolls/scroll2.dds");
    return objResult;
  }
  
  public function SetupOverlayRef(target: CR4MenuPopup): void {
    super.SetupOverlayRef(target);
    PopupRef.GetMenuFlash().GetChildFlashSprite("background").SetAlpha(100.0);
  }
  
}


function RER_openPopup(title: string, message: string): bool {
  var popup_data: RER_PopupData;
  if (isPlayerBusy()) {
    return false;
  }
  
  popup_data = new RER_PopupData in thePlayer;
  popup_data.SetMessageTitle(title);
  popup_data.SetMessageText(message);
  popup_data.PauseGame = true;
  popup_data.ScreenPosX = 1100.0/1920.0;
  popup_data.ScreenPosY = 155.0/1080.0;
  if (RER_playerUsesVladimirUI()) {
    popup_data.ScreenPosX = 400/1920.0;
  }
  
  theGame.RequestMenu('PopupMenu', popup_data);
  return true;
}

function getRandomPositionBehindCamera(out initial_pos: Vector, optional distance: float, optional minimum_distance: float, optional attempts: int): bool {
  var player_position: Vector;
  var point_z: float;
  var attempts_left: int;
  if (minimum_distance==0.0) {
    minimum_distance = 20.0;
  }
  
  if (distance==0.0) {
    distance = 40;
  }
  else if (distance<minimum_distance) {
    distance = minimum_distance;
    
  }
  
  player_position = thePlayer.GetWorldPosition();
  attempts_left = Max(attempts, 3);
  for (attempts_left = attempts_left; attempts_left>0; attempts_left -= 1) {
    initial_pos = player_position+VecConeRand(theCamera.GetCameraHeading(), 270, minimum_distance*-1, distance*-1);
    
    if (getGroundPosition(initial_pos)) {
      NLOG(initial_pos.X+" "+initial_pos.Y+" "+initial_pos.Z);
      if (initial_pos.X==0 || initial_pos.Y==0 || initial_pos.Z==0) {
        return false;
      }
      
      return true;
    }
    
  }
  
  return false;
}


function getRandomPositionAroundPlayer(out initial_pos: Vector, optional distance: float, optional minimum_distance: float, optional attempts: int): bool {
  var player_position: Vector;
  var point_z: float;
  var attempts_left: int;
  if (minimum_distance==0.0) {
    minimum_distance = 20.0;
  }
  
  if (distance==0.0) {
    distance = 40;
  }
  else if (distance<minimum_distance) {
    distance = minimum_distance;
    
  }
  
  player_position = thePlayer.GetWorldPosition();
  attempts_left = Max(attempts, 3);
  for (attempts_left = attempts_left; attempts_left>0; attempts_left -= 1) {
    initial_pos = player_position+VecRingRand(minimum_distance, distance);
    
    if (getGroundPosition(initial_pos)) {
      NLOG(initial_pos.X+" "+initial_pos.Y+" "+initial_pos.Z);
      if (initial_pos.X==0 || initial_pos.Y==0 || initial_pos.Z==0) {
        return false;
      }
      
      return true;
    }
    
  }
  
  return false;
}

class RER_DialogData {
  var dialog_id: int;
  
  var dialog_duration: float;
  
  var wait_until_end: bool;
  
}


class RER_DialogDataExample extends RER_DialogData {
  default dialog_id = 380546;
  
  default dialog_duration = 1.5;
  
}


class RER_RandomDialogBuilder {
  var sections: array<RandomDialogSection>;
  
  var current_section: RandomDialogSection;
  
  var talking_actor: CActor;
  
  function then(optional pause_after: float): RER_RandomDialogBuilder {
    this.current_section.pause_after = pause_after;
    this.sections.PushBack(this.current_section);
    this.current_section = new RandomDialogSection in this;
    return this;
  }
  
  function start(): RER_RandomDialogBuilder {
    this.current_section = new RandomDialogSection in this;
    return this;
  }
  
  function dialog(data: RER_DialogData, wait: bool): RER_RandomDialogBuilder {
    return this.either(data, wait, 1).then();
  }
  
  function either(data: RER_DialogData, wait: bool, chance: float): RER_RandomDialogBuilder {
    data.wait_until_end = wait;
    this.current_section.dialogs.PushBack(data);
    this.current_section.chances.PushBack(chance);
    return this;
  }
  
  latent function play(optional actor: CActor, optional with_camera: bool, optional interlocutor: CActor) {
    var i: int;
    var camera: RER_StaticCamera;
    if (actor) {
      this.talking_actor = actor;
    }
    else  {
      this.talking_actor = thePlayer;
      
    }
    
    this.then();
    if (with_camera) {
      camera = this.teleportCameraToLookAtTalkingActor(interlocutor);
    }
    
    for (i = 0; i<this.sections.Size(); i += 1) {
      this.playSection(i);
    }
    
    if (with_camera) {
      camera.Stop();
    }
    
  }
  
  private latent function teleportCameraToLookAtTalkingActor(optional interlocutor: CActor): RER_StaticCamera {
    var other_entity_position: Vector;
    var talking_actor_position: Vector;
    var camera: RER_StaticCamera;
    var position: Vector;
    var rotation: EulerAngles;
    var roll: int;
    var i: int;
    camera = RER_getStaticCamera();
    camera.setFov(17);
    camera.FocusOn((CNode)(this.talking_actor));
    talking_actor_position = this.talking_actor.GetBoneWorldPosition('head');
    if (interlocutor) {
      position = talking_actor_position;
      other_entity_position = interlocutor.GetBoneWorldPosition('head');
      position = VecInterpolate(talking_actor_position, other_entity_position, 2);
      position += VecFromHeading(this.talking_actor.GetHeading()+90)*Vector(0.6, 0.6, 0.001);
    }
    
    rotation = VecToRotation(talking_actor_position-position);
    rotation.Pitch *= -1;
    camera.TeleportWithRotation(position, rotation);
    camera.Run();
    camera = RER_getStaticCamera();
    roll = RandRange(20);
    if (roll<8) {
      NDEBUG("slow slide forward");
      camera.activationDuration = 20;
      camera.setFov(17);
      position += VecFromHeading(this.talking_actor.GetHeading()+180)*Vector(0.6, 0.6, 0.001);
      rotation = VecToRotation(talking_actor_position-position);
      camera.TeleportWithRotation(position, rotation);
      camera.Run();
    }
    else if (roll<10) {
      NDEBUG("slow slide to the right");
      
      camera.activationDuration = 20;
      
      camera.setFov(15);
      
      position += VecFromHeading(this.talking_actor.GetHeading()+90)*Vector(0.6, 0.6, 0.001);
      
      rotation = VecToRotation(talking_actor_position-position);
      
      camera.TeleportWithRotation(position, rotation);
      
      camera.Run();
      
    }
    else if (roll<12) {
      NDEBUG("slow slide to the left");
      
      camera.activationDuration = 20;
      
      camera.setFov(17);
      
      position += VecFromHeading(this.talking_actor.GetHeading()-90)*Vector(1.2, 1.2, 0.001);
      
      rotation = VecToRotation(talking_actor_position-position);
      
      camera.TeleportWithRotation(position, rotation);
      
      camera.Run();
      
    }
    
    return camera;
  }
  
  private latent function playSection(index: int) {
    var total: float;
    var k: int;
    for (k = 0; k<this.sections[index].chances.Size(); k += 1) {
      total += this.sections[index].chances[k];
    }
    
    for (k = 0; k<this.sections[index].chances.Size(); k += 1) {
      if (RandRangeF(total)<this.sections[index].chances[k]) {
        break;
      }
      
      
      total -= this.sections[index].chances[k];
    }
    
    if (!isPlayerInScene()) {
      this.talking_actor.PlayLine(this.sections[index].dialogs[k].dialog_id, true);
      if (this.sections[index].dialogs[k].wait_until_end) {
        this.talking_actor.WaitForEndOfSpeach();
      }
      
    }
    
    if (this.sections[index].pause_after>0) {
      Sleep(this.sections[index].pause_after);
    }
    
  }
  
}


class RandomDialogSection {
  var dialogs: array<RER_DialogData>;
  
  var chances: array<float>;
  
  var pause_after: float;
  
}

enum RER_LevelScaling {
  RER_LevelScaling_Automatic = 0,
  RER_LevelScaling_Level = 1,
  RER_LevelScaling_Playtime = 2,
}


function getRandomLevelBasedOnSettings(settings: RE_Settings): int {
  var player_level: int;
  var max_level_allowed: int;
  var min_level_allowed: int;
  var level: int;
  player_level = RER_getPlayerLevel();
  if (settings.max_level_allowed>=settings.min_level_allowed) {
    max_level_allowed = settings.max_level_allowed;
    min_level_allowed = settings.min_level_allowed;
  }
  else  {
    max_level_allowed = settings.min_level_allowed;
    
    min_level_allowed = settings.max_level_allowed;
    
  }
  
  level = RandRange(player_level+max_level_allowed, player_level+min_level_allowed);
  NLOG("random creature level = "+level);
  return Max(level, 1);
}


function RER_getPlayerLevel(): int {
  if (RER_playerUsesEnhancedEditionRedux() || RER_getPlayerScaling()==RER_LevelScaling_Playtime) {
    return GameTimeHours(theGame.CalculateTimePlayed())/3;
  }
  
  return thePlayer.GetLevel();
}


function RER_getPlayerScaling(): RER_LevelScaling {
  return StringToInt(theGame.GetInGameConfigWrapper().GetVarValue('RERmain', 'RERlevelScaling'));
}


function RER_detectAbnormalLevelChanges() {
  if (RER_getPlayerScaling()!=RER_LevelScaling_Automatic) {
    return ;
  }
  
  if (!RER_hasPlayerLevelChangedAbnormally()) {
    return ;
  }
  
  NTUTO(GetLocStringByKey('option_rer_level_scaling'), GetLocStringByKey('rer_level_scaling_no_level_detected'));
}


function RER_hasPlayerLevelChangedAbnormally(): bool {
  var previous_level: int;
  var current_level: int;
  previous_level = RER_getPlayerLevelFactValue();
  current_level = thePlayer.GetLevel();
  RER_setPlayerLevelFactValue(current_level);
  if (previous_level<=0) {
    return false;
  }
  
  if (current_level<previous_level) {
    return true;
  }
  
  return current_level-previous_level>=2;
}

function shouldAbortCreatureSpawn(settings: RE_Settings, rExtra: CModRExtra, bestiary: RER_Bestiary): bool {
  var current_state: CName;
  var is_meditating: bool;
  var current_zone: EREZone;
  current_state = thePlayer.GetCurrentStateName();
  is_meditating = current_state=='Meditation' && current_state=='MeditationWaiting';
  current_zone = rExtra.getCustomZone(thePlayer.GetWorldPosition());
  return is_meditating || current_zone==REZ_NOSPAWN || current_zone==REZ_CITY && !settings.allow_big_city_spawns || isPlayerBusy() || rExtra.isPlayerInSettlement() && !bestiary.doesAllowCitySpawns() || RER_isPlayerNearQuestMarker();
}


function RER_isPlayerNearQuestMarker(): bool {
  var player_position: Vector;
  var area_map_pins: array<SAreaMapPinInfo>;
  var can_cancel: bool;
  var i: int;
  var local_map_pins: array<SCommonMapPinInstance>;
  var k: int;
  player_position = thePlayer.GetWorldPosition();
  can_cancel = theGame.GetInGameConfigWrapper().GetVarValue('RERencountersGeneral', 'RERcancelSpawnsWhenNearQuestMarkers');
  if (!can_cancel) {
    NLOG("isNearQuestMarker(): settings off, leaving early.");
    return false;
  }
  
  area_map_pins = theGame.GetCommonMapManager().GetAreaMapPins();
  for (i = 0; i<area_map_pins.Size(); i += 1) {
    local_map_pins = theGame.GetCommonMapManager().GetMapPinInstances(area_map_pins[i].worldPath);
    
    
    for (k = 0; k<local_map_pins.Size(); k += 1) {
      if (!theGame.GetCommonMapManager().IsQuestPinType(local_map_pins[k].type)) {
        continue;
      }
      
      
      if (VecDistanceSquared2D(player_position, local_map_pins[k].position)<15*15) {
        NLOG("isNearQuestMarker(): near quest marker.");
        return true;
      }
      
    }
    
  }
  
  NLOG("isNearQuestMarker(): no quest marker nearby.");
  return false;
}

function upperCaseFirstLetter(text: string): string {
  var first_char: string;
  first_char = StrLeft(text, 1);
  return StrReplace(text, first_char, StrUpper(first_char));
}

statemachine class RER_HordeManager {
  var master: CRandomEncounters;
  
  var requests: array<RER_HordeRequest>;
  
  public function init(master: CRandomEncounters) {
    this.master = master;
    this.GotoState('Waiting');
  }
  
  public function sendRequest(request: RER_HordeRequest) {
    this.requests.PushBack(request);
    if (this.GetCurrentStateName()!='Processing') {
      this.GotoState('Processing');
    }
    
  }
  
  public function clearRequests() {
    this.requests.Clear();
  }
  
}

class RER_HordeRequest {
  var counters_per_creature_types: array<int>;
  
  var entities: array<CEntity>;
  
  var spawning_flags: RER_BestiaryEntrySpawnFlag;
  
  default spawning_flags = RER_BESF_NO_PERSIST;
  
  public function init() {
    var i: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      this.counters_per_creature_types.PushBack(0);
    }
    
  }
  
  public function setCreatureCounter(creature: CreatureType, count: int) {
    this.counters_per_creature_types[creature] = count;
  }
  
  public latent function onComplete(master: CRandomEncounters) {
    NLOG("RER_HordeRequest - onComplete");
  }
  
}

state Processing in RER_HordeManager {
  var failed_attempts: int;
  
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_HordeManager - Processing");
    this.Processing_main();
  }
  
  entry function Processing_main() {
    var bestiary_entry: RER_BestiaryEntry;
    var creature_to_spawn: CreatureType;
    var number_of_requests: int;
    var old_number_of_requests: int;
    var total_of_creatures_to_spawn: float;
    var dead_entities: float;
    var i: int;
    while (true) {
      Sleep(RandRange(5, 10));
      number_of_requests = parent.requests.Size();
      if (old_number_of_requests!=number_of_requests) {
        total_of_creatures_to_spawn = this.getCreaturesCountToSpawnFromRequests(parent.requests);
      }
      
      old_number_of_requests = number_of_requests;
      if (number_of_requests<=0) {
        Sleep(2);
        parent.GotoState('Waiting');
        return ;
      }
      
      if (isPlayerInScene()) {
        continue;
      }
      
      for (i = 0; i<number_of_requests; i += 1) {
        creature_to_spawn = this.getFirstCreatureWithPositiveCounter(parent.requests[i]);
        
        if (i==0 && creature_to_spawn!=CreatureNONE) {
          if (RandRange(100)>95) {
            (new RER_RandomDialogBuilder in thePlayer).start().either(new REROL_and_one_more in thePlayer, true, 0.5).either(new REROL_another_one in thePlayer, true, 0.5).play();
          }
          
        }
        
        
        dead_entities += SUH_removeDeadEntities(parent.requests[i].entities);
        
        SUH_makeEntitiesTargetPlayer(parent.requests[i].entities);
        
        bestiary_entry = parent.master.bestiary.getEntry(parent.master, creature_to_spawn);
        
        if (creature_to_spawn==CreatureNONE && SUH_areAllEntitiesDead(parent.requests[i].entities)) {
          parent.requests[i].onComplete(parent.master);
          parent.requests.EraseFast(i);
          i -= 1;
          number_of_requests -= 1;
        }
        
        
        this.spawnMonsterFromRequest(parent.requests[i], creature_to_spawn);
        
        if (this.failed_attempts>5) {
          (new RER_RandomDialogBuilder in thePlayer).start().either(new REROL_not_a_single_monster in thePlayer, true, 1).play();
          parent.clearRequests();
        }
        
      }
      
    }
    
  }
  
  latent function spawnMonsterFromRequest(request: RER_HordeRequest, creature_to_spawn: CreatureType) {
    var bestiary_entry: RER_BestiaryEntry;
    var position: Vector;
    var entities: array<CEntity>;
    var count: int;
    var i: int;
    if (!getRandomPositionAroundPlayer(position, 30, 5)) {
      this.failed_attempts += 1;
      return ;
    }
    
    this.failed_attempts = 0;
    bestiary_entry = parent.master.bestiary.getEntry(parent.master, creature_to_spawn);
    count = Min(request.counters_per_creature_types[creature_to_spawn], RandRange(3, 1));
    entities = bestiary_entry.spawn(parent.master, position, count, , EncounterType_CONTRACT, request.spawning_flags);
    for (i = 0; i<entities.Size(); i += 1) {
      request.entities.PushBack(entities[i]);
      
      request.counters_per_creature_types[creature_to_spawn] -= 1;
    }
    
  }
  
  function getFirstCreatureWithPositiveCounter(request: RER_HordeRequest): CreatureType {
    var i: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      if (request.counters_per_creature_types[i]>0) {
        return i;
      }
      
    }
    
    return CreatureNONE;
  }
  
  function getCreaturesCountToSpawnFromRequest(request: RER_HordeRequest): int {
    var count: int;
    var i: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      count += request.counters_per_creature_types[i];
    }
    
    return count;
  }
  
  function getCreaturesCountToSpawnFromRequests(requests: array<RER_HordeRequest>): int {
    var count: int;
    var i: int;
    for (i = 0; i<requests.Size(); i += 1) {
      count += this.getCreaturesCountToSpawnFromRequest(requests[i]);
    }
    
    return count;
  }
  
}

state Waiting in RER_HordeManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_HordeManager - Waiting");
    if (previous_state_name=='Processing') {
      this.Waiting_main();
    }
    
  }
  
  entry function Waiting_main() {
    (new RER_RandomDialogBuilder in thePlayer).start().either(new REROL_enough_for_now in thePlayer, true, 0.5).either(new REROL_thats_enough in thePlayer, true, 0.5).play();
  }
  
}

statemachine class RER_LootManager {
  var master: CRandomEncounters;
  
  var loot_by_category: array<array<array<name>>>;
  
  function init(master: CRandomEncounters): RER_LootManager {
    this.master = master;
    this.GotoState('Loading');
    return this;
  }
  
  function getLootByRarityForCategory(category: RER_LootCategory): array<array<name>> {
    return this.loot_by_category[category];
  }
  
  function getLootByCategoryAndRarity(category: RER_LootCategory, rarity: RER_LootRarity): array<name> {
    var loot_by_rarity: array<array<name>>;
    loot_by_rarity = this.getLootByRarityForCategory(category);
    return loot_by_rarity[rarity];
  }
  
  public function addLoot(category: RER_LootCategory, rarity: RER_LootRarity, item_name: name, optional origin: name) {
    var addons: array<RER_BaseAddon>;
    var addon: RER_BaseAddon;
    var idxe2cb193aeb7b45cfb2e3c312688a34b0: int;
    addons = master.addon_manager.getRegisteredAddons();
    for (idxe2cb193aeb7b45cfb2e3c312688a34b0 = 0; idxe2cb193aeb7b45cfb2e3c312688a34b0 < addons.Size(); idxe2cb193aeb7b45cfb2e3c312688a34b0 += 1) {
      addon = addons[idxe2cb193aeb7b45cfb2e3c312688a34b0];
      if (!addon.canAddLoot(category, rarity, item_name, origin)) {
        return ;
      }
      
    }
    this.loot_by_category[category][rarity].PushBack(item_name);
  }
  
  public function removeLoot(category: RER_LootCategory, rarity: RER_LootRarity, item_name: name) {
    this.loot_by_category[category][rarity].Remove(item_name);
  }
  
  public function roll(chance_multiplier: float, optional rng: RandomNumberGenerator, optional category: RER_LootCategory): array<name> {
    var output_item_names: array<name>;
    var loot_by_rarity: array<array<name>>;
    var config: CInGameConfigWrapper;
    var amount_of_rolls: int;
    var items_per_proc: int;
    var chance_common: int;
    var chance_uncommon: int;
    var chance_rare: int;
    var chance_exotic: int;
    var roll_index: int;
    var i: int;
    NLOG("roll(chance_multiplier: "+chance_multiplier+", rng, category:"+category);
    if (!rng) {
      rng = (new RandomNumberGenerator in this).useSeed(false);
    }
    
    if (category==LootCategory_None && !this.getRandomCategory(rng, category)) {
      NLOG("roll(), could not get random category");
      return output_item_names;
    }
    
    NLOG("roll(), random category = "+category);
    loot_by_rarity = this.loot_by_category[category];
    config = theGame.GetInGameConfigWrapper();
    chance_multiplier *= StringToFloat(config.GetVarValue('RERrewardsGeneral', 'RERlootGlobalChanceMultiplier'));
    if (category==LootCategory_Gear) {
      amount_of_rolls = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootGearRollsAmount'));
      items_per_proc = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootGearItemsPerProc'));
      chance_common = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootGearRarityChanceCommon'));
      chance_uncommon = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootGearRarityChanceUncommon'));
      chance_rare = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootGearRarityChanceRare'));
      chance_exotic = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootGearRarityChanceExotic'));
    }
    else if (category==LootCategory_Materials) {
      amount_of_rolls = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootMaterialsRollsAmount'));
      
      items_per_proc = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootMaterialsItemsPerProc'));
      
      chance_common = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootMaterialsRarityChanceCommon'));
      
      chance_uncommon = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootMaterialsRarityChanceUncommon'));
      
      chance_rare = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootMaterialsRarityChanceRare'));
      
      chance_exotic = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootMaterialsRarityChanceExotic'));
      
    }
    else if (category==LootCategory_Consumables) {
      amount_of_rolls = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootConsumablesRollsAmount'));
      
      items_per_proc = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootConsumablesItemsPerProc'));
      
      chance_common = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootConsumablesRarityChanceCommon'));
      
      chance_uncommon = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootConsumablesRarityChanceUncommon'));
      
      chance_rare = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootConsumablesRarityChanceRare'));
      
      chance_exotic = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootConsumablesRarityChanceExotic'));
      
    }
    else if (category==LootCategory_Valuables) {
      amount_of_rolls = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootValuablesRollsAmount'));
      
      items_per_proc = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootValuablesItemsPerProc'));
      
      chance_common = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootValuablesRarityChanceCommon'));
      
      chance_uncommon = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootValuablesRarityChanceUncommon'));
      
      chance_rare = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootValuablesRarityChanceRare'));
      
      chance_exotic = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootValuablesRarityChanceExotic'));
      
    }
    else  {
      NDEBUG("RER Error: RER_LootManager::roll(rng), unhandled category type = "+category);
      
      return output_item_names;
      
    }
    
    NLOG("roll(), amount_of_rolls = "+amount_of_rolls);
    NLOG("roll(), items_per_proc = "+items_per_proc);
    NLOG("roll(), chance_common = "+chance_common);
    NLOG("roll(), chance_uncommon = "+chance_uncommon);
    NLOG("roll(), chance_rare = "+chance_rare);
    NLOG("roll(), chance_exotic = "+chance_exotic);
    NLOG("roll(), loot_by_rarity.Size() = "+loot_by_rarity.Size());
    NLOG("roll(), loot_by_rarity[LootRarity_Common].Size() = "+loot_by_rarity[LootRarity_Common].Size());
    NLOG("roll(), loot_by_rarity[LootRarity_Uncommon].Size() = "+loot_by_rarity[LootRarity_Uncommon].Size());
    NLOG("roll(), loot_by_rarity[LootRarity_Rare].Size() = "+loot_by_rarity[LootRarity_Rare].Size());
    NLOG("roll(), loot_by_rarity[LootRarity_Exotic].Size() = "+loot_by_rarity[LootRarity_Exotic].Size());
    NLOG("roll(), this.loot_by_category.Size() = "+this.loot_by_category.Size());
    while (amount_of_rolls>0) {
      roll_index = 0;
      amount_of_rolls -= 1;
      if (rng.next()<chance_common*0.01*chance_multiplier) {
        i = items_per_proc;
        while (i) {
          i -= 1;
          roll_index = (int)(rng.nextRange(loot_by_rarity[LootRarity_Common].Size(), 0));
          output_item_names.PushBack(loot_by_rarity[LootRarity_Common][roll_index]);
        }
        
      }
      
      if (rng.next()<chance_uncommon*0.01*chance_multiplier) {
        i = items_per_proc;
        while (i) {
          i -= 1;
          roll_index = (int)(rng.nextRange(loot_by_rarity[LootRarity_Uncommon].Size(), 0));
          output_item_names.PushBack(loot_by_rarity[LootRarity_Uncommon][roll_index]);
        }
        
      }
      
      if (rng.next()<chance_rare*0.01*chance_multiplier) {
        i = items_per_proc;
        while (i) {
          i -= 1;
          roll_index = (int)(rng.nextRange(loot_by_rarity[LootRarity_Rare].Size(), 0));
          output_item_names.PushBack(loot_by_rarity[LootRarity_Rare][roll_index]);
        }
        
      }
      
      if (rng.next()<chance_exotic*0.01*chance_multiplier) {
        i = items_per_proc;
        while (i) {
          i -= 1;
          roll_index = (int)(rng.nextRange(loot_by_rarity[LootRarity_Exotic].Size(), 0));
          output_item_names.PushBack(loot_by_rarity[LootRarity_Exotic][roll_index]);
        }
        
      }
      
    }
    
    return output_item_names;
  }
  
  public function rollAndGiveItemsTo(inventory: CInventoryComponent, multiplier: float, optional rng: RandomNumberGenerator, optional category: RER_LootCategory) {
    var item_names: array<name>;
    var message: string;
    var item: name;
    var idxf7fd0d46f5c14875bda9c30d5f34dbb7: int;
    var idx37c890b7945143e895b3403bc0fc0e79: int;
    item_names = this.roll(multiplier, rng, category);
    message = "rollAndGiveItemsTo(), Received items:";
    for (idxf7fd0d46f5c14875bda9c30d5f34dbb7 = 0; idxf7fd0d46f5c14875bda9c30d5f34dbb7 < item_names.Size(); idxf7fd0d46f5c14875bda9c30d5f34dbb7 += 1) {
      item = item_names[idxf7fd0d46f5c14875bda9c30d5f34dbb7];
      message += " "+item+", ";
    }
    NLOG(message);
    for (idx37c890b7945143e895b3403bc0fc0e79 = 0; idx37c890b7945143e895b3403bc0fc0e79 < item_names.Size(); idx37c890b7945143e895b3403bc0fc0e79 += 1) {
      item = item_names[idx37c890b7945143e895b3403bc0fc0e79];
      inventory.AddAnItem(item);
    }
  }
  
  private function getRandomCategory(rng: RandomNumberGenerator, out category: RER_LootCategory): bool {
    var config: CInGameConfigWrapper;
    var gear: int;
    var materials: int;
    var consumables: int;
    var valuables: int;
    var total: int;
    var roll: int;
    config = theGame.GetInGameConfigWrapper();
    gear = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootGearRatio'));
    materials = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootMaterialsRatio'));
    consumables = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootConsumablesRatio'));
    valuables = StringToInt(config.GetVarValue('RERrewardsGeneral', 'RERlootValuablesRatio'));
    total = gear+materials+consumables+valuables;
    NLOG("getRandomCategory(), total = "+total);
    if (total<=0) {
      return false;
    }
    
    roll = (int)(rng.nextRange((float)(total), 0));
    NLOG("getRandomCategory(), gear = "+gear);
    NLOG("getRandomCategory(), materials = "+materials);
    NLOG("getRandomCategory(), consumables = "+consumables);
    NLOG("getRandomCategory(), valuables = "+valuables);
    NLOG("getRandomCategory(), roll = "+roll);
    if (roll<gear && gear>0) {
      category = LootCategory_Gear;
      return true;
    }
    
    roll -= gear;
    if (roll<materials && materials>0) {
      category = LootCategory_Materials;
      return true;
    }
    
    roll -= materials;
    if (roll<consumables && consumables>0) {
      category = LootCategory_Consumables;
      return true;
    }
    
    if (valuables>0) {
      category = LootCategory_Valuables;
      return true;
    }
    
    return false;
  }
  
}

enum RER_LootCategory {
  LootCategory_None = 0,
  LootCategory_Gear = 1,
  LootCategory_Materials = 2,
  LootCategory_Consumables = 3,
  LootCategory_Valuables = 4,
}


enum RER_LootRarity {
  LootRarity_Common = 0,
  LootRarity_Uncommon = 1,
  LootRarity_Rare = 2,
  LootRarity_Exotic = 3,
}

state Loading in RER_LootManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_LootManager - Entering state LOADING");
    this.startLoading();
  }
  
  entry function startLoading() {
    this.loadItems();
    parent.GotoState('Waiting');
  }
  
  latent function loadItems() {
    var rarity_amount: int;
    parent.loot_by_category.Grow(EnumGetMax('RER_LootCategory')+1);
    rarity_amount = EnumGetMax('RER_LootRarity')+1;
    parent.loot_by_category[LootCategory_Gear].Grow(rarity_amount);
    parent.loot_by_category[LootCategory_Materials].Grow(rarity_amount);
    parent.loot_by_category[LootCategory_Consumables].Grow(rarity_amount);
    parent.loot_by_category[LootCategory_Valuables].Grow(rarity_amount);
    this.loadGear();
    this.loadMaterials();
    this.loadConsumables();
    this.loadValuables();
  }
  
  private latent function loadGear() {
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Short sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Short sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Short Steel Sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Wooden sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Short sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Short sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Short Steel Sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Long Steel Sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Rusty No Mans Land sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'No Mans Land sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'No Mans Land sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'No Mans Land sword 3');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'No Mans Land sword 4');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Rusty Nilfgaardian sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Nilfgaardian sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Nilfgaardian sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Nilfgaardian sword 3');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Nilfgaardian sword 4');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Rusty Novigraadan sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Novigraadan sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Novigraadan sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Inquisitor sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Inquisitor sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Rusty Skellige sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Skellige sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Skellige sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Skellige sword 4');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Scoiatael sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Scoiatael sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Gnomish sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Gnomish sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Scoiatael sword 3');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Scoiatael sword 4');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Novigraadan sword 3');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Novigraadan sword 4');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Gloves 01');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Heavy gloves 01');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Boots 01');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Heavy boots 01');
    parent.addLoot(LootCategory_Gear, LootRarity_Common, 'Boots 012');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'W_Axe01');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'W_Axe02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'W_Axe03');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'W_Axe04');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'W_Mace01');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'W_Mace02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'W_Pickaxe');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'W_Poker');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'NPC Short Steel Sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'q302_Mace');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Light armor 01');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Light armor 02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Light armor 03');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Light armor 04');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Light armor 06');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Medium armor 01');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Medium armor 02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'q108 Medium armor 10');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Heavy armor 01');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Heavy armor 02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Nilfgaardian Casual Suit 01');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Nilfgaardian Casual Suit 02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Nilfgaardian Casual Suit 03');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Skellige Casual Suit 01');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Skellige Casual Suit 02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'sq108_heavy_armor');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Wild Hunt sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Wild Hunt sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Wild Hunt sword 3');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Wild Hunt sword 4');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Silver sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Silver sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Silver sword 3');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Elven silver sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Elven silver sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Dwarven silver sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Dwarven silver sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Gnomish silver sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Gnomish silver sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Gnomish silver sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Dwarven sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Dwarven sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Harpoon Bolt');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Bait Bolt');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Tracking Bolt');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Blunt Bolt');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Broadhead Bolt');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Target Point Bolt');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Split Bolt');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Explosive Bolt');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Heavy pants 02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Heavy boots 01');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Heavy boots 02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Heavy boots 03');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Heavy gloves 01');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Heavy gloves 02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Heavy gloves 02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Gloves 02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Boots 02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Boots 03');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Boots 022');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Boots 032');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Boots 04');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Heavy boots 02');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Heavy boots 03');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Heavy boots 04');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Nilfgaardian casual shoes');
    parent.addLoot(LootCategory_Gear, LootRarity_Uncommon, 'Skellige casual shoes');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Light armor 07');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Light armor 08');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Light armor 09');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Medium armor 03');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Medium armor 04');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Medium armor 05');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Medium armor 07');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Medium armor 10');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy armor 03');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy armor 04');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy armor 05');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Medium armor 11');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Silver sword 4');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Silver sword 5');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Silver sword 6');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Silver sword 7');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Silver sword 8');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'W_Axe05');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'W_Axe06');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Split Bolt Legendary');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Target Point Bolt Legendary');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Broadhead Bolt Legendary');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Blunt Bolt Legendary');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Explosive Bolt Legendary');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy pants 03');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy pants 04');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy boots 04');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy boots 05');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy boots 06');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy boots 07');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy boots 08');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy gloves 03');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy gloves 04');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Beauclair elegant pants');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Guard Lvl1 Pants 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Guard Lvl1 Pants 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Guard Lvl1 A Pants 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Guard Lvl1 A Pants 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Guard Lvl2 Pants 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Guard Lvl2 Pants 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Guard Lvl2 A Pants 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Guard Lvl2 A Pants 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Knight Geralt Pants 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Knight Geralt Pants 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Knight Geralt A Pants 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Knight Geralt A Pants 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Toussaint Pants 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Ofir Sabre 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Ofir Sabre 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Hakland Sabre');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Burning Rose Sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Burning Rose Sword B');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Burning Rose Gloves');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Burning Rose Gloves B');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Thief Gloves');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Thief Gloves B');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Thief Gloves Y');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Thief Gloves No Medallion');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Thief Pants');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Thief Pants B');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Thief Pants Y');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Thief Pants No Medallion');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Ofir Pants');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Ofir Pants B');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Geralt Kontusz');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Geralt Kontusz R');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Ofir Armor');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Ofir Armor B');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Thief Armor');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Thief Armor B');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Thief Armor Y');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Thief Armor No Medallion');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Burning Rose Armor');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Burning Rose Armor B');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Gloves 03');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Gloves 04');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy gloves 03');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy gloves 04');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy boots 05');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy boots 06');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy boots 07');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Heavy boots 08');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Boots 06');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Boots 07');
    parent.addLoot(LootCategory_Gear, LootRarity_Rare, 'Boots 05');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Angivare');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Arbitrator');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Ardaenye');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Barbersurgeon');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Beannshie');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Blackunicorn');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Caerme');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Cheesecutter');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Dyaebl');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Deireadh');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Vynbleidd');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Gwyhyr');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Forgottenvransword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Harvall');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Hjalmar_Short_Steel_Sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Karabela');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Princessxenthiasword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Robustswordofdolblathanna');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Ashrune');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Longclaw');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Daystar');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Devine');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Bloedeaedd');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Inis');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Gwestog');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Abarad');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Wolf');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Cleaver');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Dancer');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Headtaker');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Mourner');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Ultimatum');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Caroline');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Lune');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Gloryofthenorth');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Torlara');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'WitcherSilverWolf');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Addandeith');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Moonblade');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Aerondight');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Bloodsword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Deithwen');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Fate');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Gynvaelaedd');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Naevdeseidhe');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Bladeofys');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Zerrikanterment');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Anathema');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Roseofaelirenn');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Reachofthedamned');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Azurewrath');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Deargdeith');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Arainne');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Havcaaren');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Loathen');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Gynvael');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Anth');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Weeper');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Virgin');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Negotiator');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Harpy');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Tlareg');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Breathofthenorth');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Torzirael');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Shiadhal armor');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Thyssen armor');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Oathbreaker armor');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Relic Heavy 3 armor');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Zireael armor');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Shadaal armor');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Light armor 01r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Light armor 02r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Light armor 03r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Light armor 04r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Light armor 06r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Light armor 07r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Light armor 08r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Light armor 09r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Medium armor 01r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Medium armor 02r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Medium armor 03r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Medium armor 04r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Medium armor 05r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Medium armor 07r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Medium armor 10r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Medium armor 11r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Heavy armor 01r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Heavy armor 02r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Heavy armor 03r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Heavy armor 04r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Heavy armor 05r');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Guard Lvl1 steel sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Guard Lvl1 steel sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Guard lvl1 steel sword 3 Autogen');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Guard Lvl2 steel sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Guard Lvl2 steel sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Squire steel sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Squire steel sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Squire steel sword 3');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Knights steel sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Knights steel sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Toussaint steel sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Unique steel sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Hanza steel sword 0');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Hanza steel sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Hanza steel sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Gwent steel sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'mq7001 Toussaint steel sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'mq7007 Elven Sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'mq7011 Cianfanelli steel sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'sq701 Geralt of Rivia sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'sq701 Ravix of Fourhorn sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'q702 vampire steel sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'q704 vampire steel sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Unique silver sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'EP2 Silver sword 1');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'EP2 Silver sword 1R');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'EP2 Silver sword 2');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'EP2 Silver sword 3');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'EP2 Silver sword 3R');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Serpent Silver Sword 1 Autogen');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'q704 vampire silver sword');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'Olgierd Sabre');
    parent.addLoot(LootCategory_Gear, LootRarity_Exotic, 'PC Caretaker Shovel');
  }
  
  private latent function loadMaterials() {
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Cotton');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Thread');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'String');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Linen');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Silk');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Oil');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Leather straps');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Leather squares');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Fur square');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Leather');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Hardened leather');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Chitin scale');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Endriag chitin plates');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Wax');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Aether');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Bear fat');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Coal');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Calcium equum');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Dog tallow');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Ducal water');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Hydragenum');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Lunar shards');
    if (!RER_playerUsesEnhancedEditionRedux()) {
      parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Nigredo');
    }
    
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Optima mater');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Phosphorus');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Quebrith');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Quicksilver solution');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Saltpetre');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Stammelfords dust');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Sulfur');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Vermilion');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Vitriol');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Wine stone');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Glass');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Powdered pearl');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Black pearl dust');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Lead ore');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Runestone lesser');
    parent.addLoot(LootCategory_Materials, LootRarity_Common, 'Glyph infusion lesser');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Glyph infusion greater');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Alchemical paste');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Alchemists powder');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Albedo');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Blasting powder');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Silver ingot');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Meteorite ore');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Meteorite ingot');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Glowing ore');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Glowing ingot');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Dwimeryte ingot');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Whetstone');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Whetstone elven');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Whetstone dwarven');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Whetstone gnomish');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Gold ore');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Dark iron ore');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Dark iron ingot');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Dark iron plate');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Monstrous brain');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Drowner brain');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Monstrous blood');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Ghoul blood');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Nekker blood');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Specter dust');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Nekker eye');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Monstrous claw');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Nekker claw');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Alghoul claw');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Harpy egg');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Harpy talon');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Allspice root');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Arenaria');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Balisse fruit');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Beggartick blossoms');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Berbercane fruit');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Bison Grass');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Bloodmoss');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Blowbill');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Bryonia');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Celandine');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Cortinarius');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Crows eye');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Ergot seeds');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Fools parsley leaves');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Ginatia petals');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Green mold');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Han');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Hellebore petals');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Honeysuckle');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Hop umbels');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Hornwort');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Longrube');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Mandrake root');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Mistletoe');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Moleyarrow');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Nostrix');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Pigskin puffball');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Pringrape');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Ranogrin');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Ribleaf');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Sewant mushrooms');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Verbena');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'White myrtle');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Wolfsbane');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Buckthorn');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Dragon scales');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Dark iron ore');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Dark iron ingot');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Dark iron plate');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Runestone greater');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Draconide leather');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Winter cherry');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Holy basil');
    parent.addLoot(LootCategory_Materials, LootRarity_Uncommon, 'Blue lotus');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Fifth essence');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Rebis');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Rubedo');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous brain');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Drowner brain');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous blood');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Ghoul blood');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Nekker blood');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Rotfiend blood');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Leshy resin');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Greater Rotfiend blood');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous bone');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Alghoul bone marrow');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous dust');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Gargoyle dust');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous ear');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Grave Hag ear');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous egg');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Harpy egg');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Endriag embryo');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Cockatrice egg');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Gryphon egg');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Wyvern egg');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous essence');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Crystalized essence');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Elemental essence');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Nightwraith dark essence');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Noonwraith light essence');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Water essence');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Wraith essence');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous eye');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Arachas eyes');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Erynie eye');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Cyclops eye');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Fiend eye');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous feather');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Harpy feathers');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Gryphon feathers');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous hair');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Lamia lock of hair');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Nightwraiths hair');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous heart');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Nekker heart');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Endriag heart');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Gargoyle heart');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Golem heart');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous hide');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Necrophage skin');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Troll skin');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Ekimma epidermis');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Berserker pelt');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Czart hide');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous liver');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Cave Troll liver');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Nekker warrior liver');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous plate');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Basilisk plate');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Forktail plate');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Wyvern plate');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous saliva');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Vampire saliva');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Werewolf saliva');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous tongue');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Drowned dead tongue');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Monstrous tooth');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Cockatrice maw');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Fogling teeth');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Hag teeth');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Water Hag teeth');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Vampire fang');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Venom extract');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Arachas venom');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Basilisk venom');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Siren vocal cords');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Amber dust');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Amber fossil');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Amber');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Amber flawless');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Amethyst dust');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Amethyst');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Amethyst flawless');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Diamond dust');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Diamond');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Diamond flawless');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Emerald dust');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Emerald');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Emerald flawless');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Ruby dust');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Ruby');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Ruby flawless');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Sapphire dust');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Sapphire');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Sapphire flawless');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Infused dust');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Infused shard');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Infused crystal');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Draconide infused leather');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Nickel mineral');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Nickel ore');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Copper mineral');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Azurite mineral');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Malachite mineral');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Copper ore');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Cupronickel ore');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Copper ingot');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Dwimeryte enriched ingot');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Green gold mineral');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Green gold ore');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Green gold ingot');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Dwimeryte enriched ore');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Orichalcum mineral');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Orichalcum ore');
    parent.addLoot(LootCategory_Materials, LootRarity_Rare, 'Orichalcum ingot');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Greater mutagen red');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Greater mutagen green');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Greater mutagen blue');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Mutagen red');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Mutagen green');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Mutagen blue');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Lesser mutagen red');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Lesser mutagen green');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Lesser mutagen blue');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Katakan mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Arachas mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Cockatrice mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Volcanic Gryphon mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Gryphon mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Water Hag mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Nightwraith mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Ekimma mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Czart mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Fogling 1 mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Wyvern mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Doppler mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Troll mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Noonwraith mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Succubus mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Fogling 2 mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Fiend mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Forktail mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Grave Hag mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Wraith mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Dao mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Lamia mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Ancient Leshy mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Basilisk mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Werewolf mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Nekker Warrior mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Leshy mutagen');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Acid extract');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Centipede discharge');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Kikimore discharge');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Vampire blood');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Monstrous carapace');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Sharley dust');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Wight ear');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Barghest essence');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Wight hair');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Sharley heart');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Monstrous pincer');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Centipede mandible');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Dracolizard plate');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Monstrous spore');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Monstrous stomach');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Wight stomach');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Monstrous vine');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Archespore tendril');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Archespore juice');
    parent.addLoot(LootCategory_Materials, LootRarity_Exotic, 'Monstrous wing');
  }
  
  private latent function loadConsumables() {
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Empty bottle');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Alcohest');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Baked apple');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Blueberries');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Dijkstra Dry');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Apple');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Bell pepper');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Burned bread');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Cucumber');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Honeycomb');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Burned bun');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Butter Bandalura');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Candy');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Cheese');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Fried meat');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Chicken');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Chicken leg');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Raw meat');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Cows milk');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Goats milk');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Dried fruit');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Dried fruit and nuts');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Egg');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Fish');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Fried fish');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Gutted fish');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Grapes');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Mushroom');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Mutton curry');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Mutton leg');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Olive');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Onion');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Pear');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Pepper');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Plum');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Pork');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Grilled pork');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Potatoes');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Chips');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Raspberries');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Strawberries');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Toffee');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Vinegar');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Apple juice');
    parent.addLoot(LootCategory_Consumables, LootRarity_Common, 'Bottled water');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Bun');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Bread');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Banana');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Kaedwenian Stout');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Nilfgaardian Lemon');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Redanian Herbal');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Redanian Lager');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Rivian Kriek');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Viziman Champion');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Chicken sandwich');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Grilled chicken sandwich');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Ham sandwich');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Very good honey');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Roasted chicken');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Roasted chicken leg');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Fondue');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Baked potato');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Raspberry juice');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Free roasted chicken leg');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Free nilfgaardian lemon');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Dumpling');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Free nilfgaardian lemon');
    parent.addLoot(LootCategory_Consumables, LootRarity_Uncommon, 'Dumpling');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Cherry Cordial');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Mahakam Spirit');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Dwarven spirit');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Local pepper vodka');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Cherry cordia');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Temerian Rye');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'White Gull 1');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Bourgogne chardonnay');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Chateau mont valjean');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Bourgogne pinot noir');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Saint mathieu rouge');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Duke nicolas chardonnay');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Uncle toms exquisite blanc');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Chevalier adam pinot blanc reserve');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Prince john merlot');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Count var ochmann shiraz');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Chateau de konrad cabernet');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Geralt de rivia');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'White Wolf');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Butcher of Blaviken');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Pheasant gutted');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Tarte tatin');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Ratatouille');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Baguette camembert');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Crossaint honey');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Herb toasts');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Brioche');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Flamiche');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Camembert');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Chocolate souffle');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Pate chicken livers');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Confit de canard');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Baguette fish paste');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Fish tarte');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Boeuf bourguignon');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Rillettes porc');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Onion soup');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Ham roasted');
    parent.addLoot(LootCategory_Consumables, LootRarity_Rare, 'Ginger Bread');
    parent.addLoot(LootCategory_Consumables, LootRarity_Exotic, 'Erveluce');
    parent.addLoot(LootCategory_Consumables, LootRarity_Exotic, 'Est Est');
    parent.addLoot(LootCategory_Consumables, LootRarity_Exotic, 'Mettina Rose');
    parent.addLoot(LootCategory_Consumables, LootRarity_Exotic, 'Mandrake cordial');
    parent.addLoot(LootCategory_Consumables, LootRarity_Exotic, 'Beauclair White');
  }
  
  private latent function loadValuables() {
    parent.addLoot(LootCategory_Valuables, LootRarity_Common, 'Pearl');
    parent.addLoot(LootCategory_Valuables, LootRarity_Common, 'Black pearl');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Silver mug');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Silver platter');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Silver casket');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Silver plate');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Gold candelabra');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Gold ring');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Gold ruby ring');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Gold pearl necklace');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Golden mug');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Golden platter');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Golden casket');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Silver amber ring');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Silver sapphire ring');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Silver emerald ring');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Silver emerald necklace');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Silver amber necklace');
    parent.addLoot(LootCategory_Valuables, LootRarity_Uncommon, 'Silver ruby necklace');
    parent.addLoot(LootCategory_Valuables, LootRarity_Rare, 'Emerald');
    parent.addLoot(LootCategory_Valuables, LootRarity_Rare, 'Amethyst');
    parent.addLoot(LootCategory_Valuables, LootRarity_Rare, 'Diamond');
    parent.addLoot(LootCategory_Valuables, LootRarity_Rare, 'Amber');
    parent.addLoot(LootCategory_Valuables, LootRarity_Rare, 'Ruby');
    parent.addLoot(LootCategory_Valuables, LootRarity_Rare, 'Sapphire');
    parent.addLoot(LootCategory_Valuables, LootRarity_Rare, 'Amber');
    parent.addLoot(LootCategory_Valuables, LootRarity_Rare, 'Ruby');
    parent.addLoot(LootCategory_Valuables, LootRarity_Rare, 'Sapphire');
    parent.addLoot(LootCategory_Valuables, LootRarity_Exotic, 'Gold diamond ring');
    parent.addLoot(LootCategory_Valuables, LootRarity_Exotic, 'Gold diamond necklace');
    parent.addLoot(LootCategory_Valuables, LootRarity_Exotic, 'Gold sapphire necklace');
    parent.addLoot(LootCategory_Valuables, LootRarity_Exotic, 'Gold sapphire ring');
    parent.addLoot(LootCategory_Valuables, LootRarity_Exotic, 'Green gold ruby ring');
    parent.addLoot(LootCategory_Valuables, LootRarity_Exotic, 'Green gold sapphire ring');
    parent.addLoot(LootCategory_Valuables, LootRarity_Exotic, 'Green gold emerald ring');
    parent.addLoot(LootCategory_Valuables, LootRarity_Exotic, 'Green gold diamond ring');
    parent.addLoot(LootCategory_Valuables, LootRarity_Exotic, 'Green gold amber necklace');
    parent.addLoot(LootCategory_Valuables, LootRarity_Exotic, 'Green gold ruby necklace');
    parent.addLoot(LootCategory_Valuables, LootRarity_Exotic, 'Green gold sapphire necklace');
    parent.addLoot(LootCategory_Valuables, LootRarity_Exotic, 'Green gold emerald necklace');
    parent.addLoot(LootCategory_Valuables, LootRarity_Exotic, 'Green gold diamond necklace');
  }
  
}

state Waiting in RER_LootManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_LootManager - Entering state Waiting");
  }
  
}

state Loading in CRandomEncounters {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("Entering state LOADING");
    this.startLoading();
  }
  
  entry function startLoading() {
    parent.bounty_manager.bounty_master_manager.init(parent.bounty_manager);
    parent.static_encounter_manager.init(parent);
    RER_addNoticeboardInjectors();
    parent.refreshEcosystemFrequencyMultiplier();
    Sleep(10);
    this.takeControlOfEntities();
    parent.static_encounter_manager.startSpawning();
    SU_updateMinimapPins();
    parent.addon_manager.init(parent);
    parent.GotoState('Waiting');
  }
  
  private latent function takeControlOfEntities() {
    var rer_entity: RandomEncountersReworkedHuntingGroundEntity;
    var rer_entity_template: CEntityTemplate;
    var surrounding_entities: array<CGameplayEntity>;
    var entity_group: array<CEntity>;
    var entities: array<CEntity>;
    var entity: CEntity;
    var i: int;
    var k: int;
    NLOG("takeControlOfEntities()");
    theGame.GetEntitiesByTag('RandomEncountersReworked_Entity', entities);
    for (i = 0; i<entities.Size(); i += 1) {
      entity = entities[i];
      
      if (entity.HasTag('RandomEncountersReworked_ContractCreature')) {
        continue;
      }
      
      
      ((CNewNPC)(entity)).SetLevel(getRandomLevelBasedOnSettings(parent.settings));
      
      entity.RemoveTag('RER_controlled');
    }
    
    rer_entity_template = (CEntityTemplate)(LoadResourceAsync("dlc\modtemplates\randomencounterreworkeddlc\data\rer_hunting_ground_entity.w2ent", true));
    for (i = 0; i<entities.Size(); i += 1) {
      entity = entities[i];
      
      if (entity.HasTag('RER_controlled') || entity.HasTag('RandomEncountersReworked_ContractCreature')) {
        continue;
      }
      
      
      surrounding_entities.Clear();
      
      FindGameplayEntitiesInRange(surrounding_entities, entity, 20, 20, 'RandomEncountersReworked_Entity', FLAG_ExcludePlayer, thePlayer, 'CNewNPC');
      
      entity_group.Clear();
      
      for (k = 0; k<surrounding_entities.Size(); k += 1) {
        if (entity.HasTag('RER_controlled')) {
          continue;
        }
        
        
        entity_group.PushBack(surrounding_entities[k]);
        
        surrounding_entities[k].AddTag('RER_controlled');
      }
      
      
      if (entity_group.Size()>0) {
        rer_entity = (RandomEncountersReworkedHuntingGroundEntity)(theGame.CreateEntity(rer_entity_template, entity.GetWorldPosition(), entity.GetWorldRotation()));
        rer_entity.startEncounter(parent, entity_group, parent.bestiary.entries[parent.bestiary.getCreatureTypeFromEntity(entity)]);
        NLOG("created a HuntingGround with "+entity_group.Size()+" RER entities");
      }
      
    }
    
    for (i = 0; i<entities.Size(); i += 1) {
      entities[i].RemoveTag('RER_controlled');
    }
    
    NLOG("found "+entities.Size()+" RER entities");
  }
  
}


class SU_CustomPinRemoverPredicateFromRER extends SU_PredicateInterfaceRemovePin {
  function predicate(pin: SU_MapPin): bool {
    return StrStartsWith(pin.tag, "RER_");
  }
  
}


class SU_CustomPinRemovePredicateFromRERAndRegion extends SU_PredicateInterfaceRemovePin {
  var starts_with: string;
  
  default starts_with = "RER_";
  
  var position: Vector;
  
  var radius: float;
  
  default radius = 50;
  
  function predicate(pin: SU_MapPin): bool {
    return StrStartsWith(pin.tag, this.starts_with) && VecDistanceSquared2D(this.position, pin.position)<this.radius*this.radius;
  }
  
}


function RER_removePinsInAreaAndWithTag(tag_start: string, center: Vector, radius: float) {
  var predicate: SU_CustomPinRemovePredicateFromRERAndRegion;
  predicate = new SU_CustomPinRemovePredicateFromRERAndRegion in thePlayer;
  predicate.position = center;
  predicate.radius = radius;
  predicate.starts_with = tag_start;
  SU_removeCustomPinByPredicate(predicate);
}

state Spawning in CRandomEncounters {
  private var is_spawn_forced: bool;
  
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    this.is_spawn_forced = previous_state_name=='SpawningForced';
    NLOG("Entering state SPAWNING");
    triggerCreaturesSpawn();
  }
  
  entry function triggerCreaturesSpawn() {
    var picked_encounter_type: EncounterType;
    NLOG("creatures spawning triggered");
    picked_encounter_type = this.getRandomEncounterType();
    if (!parent.settings.is_enabled || !RER_modPowerIsEncounterSystemEnabled(parent.getModPower()) || !this.is_spawn_forced && shouldAbortCreatureSpawn(parent.settings, parent.rExtra, parent.bestiary)) {
      parent.GotoState('SpawningCancelled');
      return ;
    }
    
    NLOG("picked encounter type: "+picked_encounter_type);
    makeGroupComposition(picked_encounter_type, parent);
    parent.static_encounter_manager.startSpawning();
    parent.GotoState('Waiting');
  }
  
  function getRandomEncounterType(): EncounterType {
    var monster_ambush_chance: int;
    var monster_hunt_chance: int;
    var monster_contract_chance: int;
    var monster_hunting_ground_chance: int;
    var max_roll: int;
    var roll: int;
    if (theGame.envMgr.IsNight()) {
      monster_ambush_chance = parent.settings.all_monster_ambush_chance_night;
      monster_hunt_chance = parent.settings.all_monster_hunt_chance_night;
      monster_hunting_ground_chance = parent.settings.all_monster_hunting_ground_chance_night;
    }
    else  {
      monster_ambush_chance = parent.settings.all_monster_ambush_chance_day;
      
      monster_hunt_chance = parent.settings.all_monster_hunt_chance_day;
      
      monster_hunting_ground_chance = parent.settings.all_monster_hunting_ground_chance_day;
      
    }
    
    max_roll = monster_hunt_chance+monster_ambush_chance+monster_hunting_ground_chance;
    roll = RandRange(max_roll);
    if (roll<monster_hunt_chance) {
      return EncounterType_HUNT;
    }
    
    roll -= monster_hunt_chance;
    if (roll<monster_hunting_ground_chance) {
      return EncounterType_HUNTINGGROUND;
    }
    
    return EncounterType_DEFAULT;
  }
  
}

state SpawningCancelled in CRandomEncounters {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("entering state SPAWNING-CANCELLED");
    RER_emitEncounterCancelled(parent);
    parent.GotoState('Waiting');
  }
  
}

state SpawningDelayed in CRandomEncounters {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("entering state SPAWNING-DELAYED");
    parent.GotoState('Waiting');
  }
  
}

state SpawningForced in CRandomEncounters {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("entering state SPAWNING-FORCED");
    parent.GotoState('Spawning');
  }
  
}

state Waiting in CRandomEncounters {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("Entering state WAITING");
    parent.ticks_before_spawn = this.calculateRandomTicksBeforeSpawn();
    if (previous_state_name=='SpawningCancelled') {
      parent.ticks_before_spawn = parent.ticks_before_spawn/3;
    }
    
    if (parent.rExtra.isPlayerInSettlement()) {
      parent.ticks_before_spawn = (int)((parent.ticks_before_spawn*parent.settings.settlement_delay_multiplier));
    }
    
    NLOG("waiting "+parent.ticks_before_spawn+" ticks");
    this.startWaiting();
  }
  
  entry function startWaiting() {
    var time_before_updating_frequency_multiplier: float;
    var ticks: float;
    parent.refreshEcosystemFrequencyMultiplier();
    parent.refreshModPower();
    time_before_updating_frequency_multiplier = 30;
    NLOG("ecosystem_frequency_multiplier = "+parent.ecosystem_frequency_multiplier);
    while (parent.ticks_before_spawn>=0) {
      ticks = 5*parent.ecosystem_frequency_multiplier*parent.getModPower();
      parent.ticks_before_spawn -= ticks;
      time_before_updating_frequency_multiplier -= ticks;
      if (time_before_updating_frequency_multiplier<=0) {
        parent.refreshEcosystemFrequencyMultiplier();
        NLOG("ecosystem_frequency_multiplier = "+parent.ecosystem_frequency_multiplier);
        RER_detectAbnormalLevelChanges();
      }
      
      Sleep(5);
    }
    
    parent.GotoState('Spawning');
  }
  
  function calculateRandomTicksBeforeSpawn(): int {
    if (theGame.envMgr.IsNight()) {
      return RandRange(parent.settings.customNightMin, parent.settings.customNightMax)+parent.settings.additional_delay_per_player_level*RER_getPlayerLevel();
    }
    
    return RandRange(parent.settings.customDayMin, parent.settings.customDayMax)+parent.settings.additional_delay_per_player_level*RER_getPlayerLevel();
  }
  
}

state Initialising in CRandomEncounters {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("Entering state Initialising");
    this.startInitialising();
  }
  
  entry function startInitialising() {
    var is_enabled: bool;
    var version: float;
    NLOG("Delaying RER loading start:");
    while (theGame.IsLoadingScreenVideoPlaying()) {
      Sleep(1);
    }
    
    NLOG(" - Loading screen video ended");
    while (isPlayerBusy()) {
      Sleep(0.5);
    }
    
    NLOG(" - Player no longer busy");
    Sleep(0.5);
    is_enabled = theGame.GetInGameConfigWrapper().GetVarValue('RERmain', 'RERmodEnabled');
    version = StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('RERmain', 'RERmodVersion'));
    if (!is_enabled && version>0) {
      return ;
    }
    
    if (parent.settings.shouldResetRERSettings(theGame.GetInGameConfigWrapper())) {
      this.displayPresetChoiceDialogeMenu();
    }
    
    this.removeAllRerMapPins();
    this.updateSettings();
    RER_loadStorageCollection(parent);
    parent.refreshModPower();
    parent.spawn_roller.fill_arrays();
    parent.bestiary.init();
    parent.bestiary.loadSettings();
    parent.settings.loadXMLSettings();
    parent.resources.load_resources();
    parent.events_manager.init(parent);
    parent.events_manager.start();
    parent.ecosystem_manager.init(parent);
    parent.bounty_manager.init(parent);
    parent.horde_manager.init(parent);
    parent.contract_manager.init(parent);
    parent.loot_manager.init(parent);
    RER_addTrackerGlossary();
    RER_tutorialTryShowStarted();
    NLOG("ecosystem areas storage count = "+parent.storages.ecosystem.ecosystem_areas.Size());
    RER_toggleDebug(true);
    parent.GotoState('Loading');
  }
  
  latent function updateSettings() {
    var config: CInGameConfigWrapper;
    var constants: RER_Constants;
    var current_version: float;
    var message: string;
    config = theGame.GetInGameConfigWrapper();
    constants = RER_Constants();
    current_version = StringToFloat(config.GetVarValue('RERmain', 'RERmodVersion'));
    if (current_version<2.07) {
      config.ApplyGroupPreset('RERcontracts', 0);
      current_version = 2.07;
    }
    
    if (current_version<2.08) {
      NDEBUG("[RER] The mod was updated to v2.8: the Contract System settings were reset to support the new reputation system");
      config.ApplyGroupPreset('RERcontracts', 0);
      current_version = 2.08;
    }
    
    if (current_version<2.09) {
      NDEBUG("[RER] The mod was updated to v2.9: the Contract System settings were reset to support updated distance settings");
      config.ApplyGroupPreset('RERcontracts', 0);
      parent.storages.bounty.current_bounty.is_active = false;
      current_version = 2.09;
    }
    
    if (current_version<2.11) {
      NDEBUG("[RER] The mod was updated to v2.11");
      current_version = 2.11;
    }
    
    if (current_version<2.12) {
      message += "You just updated the Random Encounters Reworked mod to the v2.12, the loot update.<br/><br/>";
      message += "All of your reward settings were reset following the update. ";
      message += "To simplify and streamline the loot coming from the mod, all of the old rewards were removed and replaced ";
      message += "with a central and generic system. This system called the Loot Manager offers four loot categories:";
      message += "<br/> - Gear";
      message += "<br/> - Materials";
      message += "<br/> - Consumables";
      message += "<br/> - Valuables";
      message += "<br/>And for each category it offers four loot rarities: ";
      message += "<br/> - Common";
      message += "<br/> - Uncommon";
      message += "<br/> - Rare";
      message += "<br/> - Exotic";
      message += "<br/><br/>Now every time RER wants to add loot to something, it sends a call to the loot manager which will ";
      message += "give it a list of items based on the settings you set in the menu, and this for every feature in the mod.";
      NTUTO("RER v2.12 - The loot update", message);
      config.ApplyGroupPreset('RERrewardsGeneral', 0);
      config.ApplyGroupPreset('RERcontainerRefill', 0);
      config.ApplyGroupPreset('RERkillingSpreeCustomLoot', 0);
      config.ApplyGroupPreset('RERmonsterTrophies', 0);
      config.ApplyGroupPreset('RERcontracts', 0);
      current_version = 2.12;
    }
    
    if (current_version<2.13) {
      config.ApplyGroupPreset('RERmonsterTrophies', 0);
      if (RER_playerUsesEnhancedEditionRedux()) {
        config.SetVarValue('RERmonsterTrophies', 'RERtrophyMasterBuyingPrice', 30);
      }
      
      current_version = 2.13;
    }
    
    if (current_version<3.0) {
      current_version = 3.0;
      config.ApplyGroupPreset('RERtutorials', 0);
    }
    
    if (current_version<3.01) {
      current_version = 3.01;
      message += "Random Encounters Reworked was updated to the v3.1 - The Next-Gen update";
      message += "<br/>A new settings was enabled automatically: disable encounter spawns when near quest markers.";
      message += "If you wish to turn it off, you can find the toggle at the bottom of the Encounters System, General menu";
      NTUTO("RER v3.1 - Next-Gen update", message);
      config.SetVarValue('RERmonsterTrophies', 'RERtrophyMasterBuyingPrice', 1);
      config.ApplyGroupPreset('RERtutorials', 0);
    }
    
    if (current_version<3.02) {
      current_version = 3.02;
      message += "Random Encounters Reworked was updated to the v3.2";
      message += "<br/>This version brings two major changes:";
      message += "<br/><br/>"+RER_yellowFont("Standalone 3D markers")+" for the various things spawned by the mod "+"were added. You can toggle them ON or OFF in the "+RER_yellowFont("Optional Features")+" menu.";
      message += "<br/><br/>"+RER_yellowFont("Contract rewards streamlining")+", the random nature of Tokens of Gratitude "+"plus the need to find the bounty master to sell them was frustrating. "+"A new option (that is enabled by default) was added to the Contracts menu to give crowns directly instead "+"of tokens. If you prefer the Tokens way of getting reward, this solution was streamlined to no longer "+"scale with your current reputation but instead scale linearly with the contract's difficulty: 1 plus "+"an additional token every 7 Contract levels";
      NTUTO("RER v3.2 - 3D Markers & Contract rewards", message);
      config.SetVarValue('RERoptionalFeatures', 'RERonelinersBountyMainTarget', 1);
      config.SetVarValue('RERoptionalFeatures', 'RERonelinersContract', 1);
      config.SetVarValue('RERoptionalFeatures', 'RERonelinersBountyMaster', 1);
      config.SetVarValue('RERmonsterCrowns', 'RERcrownsContract', 40);
      config.SetVarValue('RERcontracts', 'RERcontractsRewardOption', 0);
    }
    
    if (current_version<3.03) {
      current_version = 3.03;
      config.SetVarValue('RERcontracts', 'RERcontractsDeathReputationLossAmount', 1);
      NTUTO("RER v3.3", "The mod was successfully updated to v3.3");
    }
    
    if (current_version<3.04) {
      current_version = 3.04;
      config.SetVarValue('RERmain', 'RERlevelScaling', 0);
      config.ApplyGroupPreset('RERcontracts', 0);
      NTUTO("RER v3.4", "The mod was successfully updated to v3.4");
    }
    
    config.SetVarValue('RERmain', 'RERmodVersion', constants.version);
    theGame.SaveUserSettings();
  }
  
  latent function displayPresetChoiceDialogeMenu() {
    var choices: array<SSceneChoice>;
    var manager: RER_PresetManager;
    var response: SSceneChoice;
    manager = new RER_PresetManager in this;
    manager.master = parent;
    choices = manager.getChoiceList();
    while (isPlayerBusy()) {
      Sleep(5);
    }
    
    Sleep(5);
    (new RER_RandomDialogBuilder in thePlayer).start().dialog(new REROL_whoa_in_for_one_helluva_ride in thePlayer, true).play();
    response = SU_setDialogChoicesAndWaitForResponse(choices);
    SU_closeDialogChoiceInterface();
    manager.GotoState(response.playGoChunk);
    while (!manager.done) {
      SleepOneFrame();
    }
    
    (new RER_RandomDialogBuilder in thePlayer).start().dialog(new REROL_ready_to_go_now in thePlayer, true).play();
    theGame.SaveUserSettings();
  }
  
  private function removeAllRerMapPins() {
    SU_removeCustomPinByPredicate(new SU_CustomPinRemoverPredicateFromRER in parent);
  }
  
}

state EnhancedEdition in RER_PresetManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_PresetManager - state EnhancedEdition");
    this.EnhancedEdition_applySettings();
  }
  
  entry function EnhancedEdition_applySettings() {
    var wrapper: CInGameConfigWrapper;
    var value: float;
    wrapper = theGame.GetInGameConfigWrapper();
    parent.master.settings.resetRERSettings(wrapper);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersAmbushDay', 'Katakans', 0.5);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersAmbushDay', 'Ekimmaras', 0.5);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersAmbushDay', 'Bruxae', 0.1);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersAmbushDay', 'Fleders', 0.1);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersAmbushDay', 'Garkains', 0.1);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersAmbushNight', 'Katakans', 0.6);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersAmbushNight', 'Ekimmaras', 0.6);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersAmbushNight', 'Bruxae', 0.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersAmbushNight', 'Fleders', 0.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersAmbushNight', 'Garkains', 0.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersContractDay', 'Katakans', 0.5);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersContractDay', 'Ekimmaras', 0.5);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersContractDay', 'Bruxae', 0.1);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersContractDay', 'Fleders', 0.1);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersContractDay', 'Garkains', 0.1);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersContractNight', 'Katakans', 0.6);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersContractNight', 'Ekimmaras', 0.6);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersContractNight', 'Bruxae', 0.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersContractNight', 'Fleders', 0.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersContractNight', 'Garkains', 0.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntDay', 'Katakans', 0.5);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntDay', 'Ekimmaras', 0.5);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntDay', 'Bruxae', 0.1);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntDay', 'Fleders', 0.1);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntDay', 'Garkains', 0.1);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntNight', 'Katakans', 0.6);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntNight', 'Ekimmaras', 0.6);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntNight', 'Bruxae', 0.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntNight', 'Fleders', 0.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntNight', 'Garkains', 0.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntingGroundDay', 'Katakans', 0.5);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntingGroundDay', 'Ekimmaras', 0.5);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntingGroundDay', 'Bruxae', 0.1);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntingGroundDay', 'Fleders', 0.1);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntingGroundDay', 'Garkains', 0.1);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntingGroundNight', 'Katakans', 0.6);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntingGroundNight', 'Ekimmaras', 0.6);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntingGroundNight', 'Bruxae', 0.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntingGroundNight', 'Fleders', 0.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersHuntingGroundNight', 'Garkains', 0.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersGeneral', 'customdFrequencyLow', 1.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersGeneral', 'customdFrequencyHigh', 1.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersGeneral', 'customnFrequencyLow', 1.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERencountersGeneral', 'customnFrequencyHigh', 1.2);
    this.wrapperMultiplyFloatValue(wrapper, 'RERevents', 'eventFightNoise', 0.8);
    this.wrapperMultiplyFloatValue(wrapper, 'RERevents', 'eventMeditationAmbush', 0.8);
    this.wrapperMultiplyFloatValue(wrapper, 'RERmonsterTrophies', 'RERtrophyMasterBuyingPrice', 0.65);
    theGame.SaveUserSettings();
    parent.done = true;
  }
  
  function wrapperMultiplyFloatValue(wrapper: CInGameConfigWrapper, menu: name, value: name, multiplier: float) {
    var fvalue: float;
    fvalue = StringToFloat(wrapper.GetVarValue(menu, value));
    wrapper.SetVarValue(menu, value, fvalue*multiplier);
  }
  
}

state Exit in RER_PresetManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_PresetManager - state Exit");
    this.Exit_applySettings();
  }
  
  entry function Exit_applySettings() {
    parent.done = true;
  }
  
}

statemachine class RER_PresetManager {
  public var done: bool;
  
  public var master: CRandomEncounters;
  
  public function getPresetList(): array<RER_Preset> {
    var output: array<RER_Preset>;
    output.PushBack(RER_Preset("rer_dialog_preset_vanilla", 'Vanilla'));
    output.PushBack(RER_Preset("rer_dialog_preset_enhanced_edition", 'EnhancedEdition'));
    output.PushBack(RER_Preset("rer_dialog_preset_exit_do_nothing", 'Exit'));
    return output;
  }
  
  public function getChoiceList(): array<SSceneChoice> {
    var presets: array<RER_Preset>;
    var choices: array<SSceneChoice>;
    var i: int;
    presets = this.getPresetList();
    for (i = 0; i<presets.Size(); i += 1) {
      choices.PushBack(SSceneChoice(GetLocStringByKey(presets[i].dialog_string_key), false, false, false, DialogAction_GAME_DAGGER, presets[i].state_name));
    }
    
    return choices;
  }
  
}


struct RER_Preset {
  var dialog_string_key: string;
  
  var state_name: name;
  
}

state Vanilla in RER_PresetManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_PresetManager - state Vanilla");
    this.Vanilla_applySettings();
  }
  
  entry function Vanilla_applySettings() {
    parent.master.settings.resetRERSettings(theGame.GetInGameConfigWrapper());
    parent.done = true;
  }
  
}

enum RER_PlaceholderStaticEncounterType {
  RER_PSET_LearnFromEcosystem = 0,
  RER_PSET_CopyNearbyCreature = 1,
}


class RER_PlaceholderStaticEncounter extends RER_StaticEncounter {
  public var placeholder_type: RER_PlaceholderStaticEncounterType;
  
  public var picked_creature_type: CreatureType;
  
  default picked_creature_type = CreatureNONE;
  
  private var ignore_creature_check: bool;
  
  public function init(ignore_creature_check: bool, position: Vector, radius: float, type: RER_StaticEncounterType, placeholder_type: RER_PlaceholderStaticEncounterType): RER_PlaceholderStaticEncounter {
    this.ignore_creature_check = ignore_creature_check;
    this.position = position;
    this.type = type;
    this.radius = radius;
    this.region_constraint = RER_RegionConstraint_NONE;
    this.placeholder_type = placeholder_type;
    return this;
  }
  
  private function areThereEntitiesWithSameTemplate(entities: array<CGameplayEntity>): bool {
    var hashed_name: string;
    var actor: CActor;
    var i: int;
    if (this.ignore_creature_check) {
      return false;
    }
    
    for (i = 0; i<entities.Size(); i += 1) {
      actor = (CActor)(entities[i]);
      
      if (actor) {
        if (actor.IsMonster()) {
          return true;
        }
        
      }
      
    }
    
    return false;
  }
  
  public latent function getBestiaryEntry(master: CRandomEncounters): RER_BestiaryEntry {
    var constants: RER_ConstantCreatureTypes;
    var filter: RER_SpawnRollerFilter;
    var output: RER_BestiaryEntry;
    constants = RER_ConstantCreatureTypes();
    filter = (new RER_SpawnRollerFilter in this).init();
    if (this.type==StaticEncounterType_SMALL) {
      filter.setOffsets(constants.large_creature_begin, constants.large_creature_max, 0);
    }
    else  {
      filter.setOffsets(constants.large_creature_begin, constants.large_creature_max, 0);
      
    }
    
    if (this.placeholder_type==RER_PSET_LearnFromEcosystem) {
      output = master.bestiary.getRandomEntryFromBestiary(master, EncounterType_HUNTINGGROUND, RER_flag(RER_BREF_IGNORE_SETTLEMENT, true), filter);
      return output;
    }
    else if (this.placeholder_type==RER_PSET_CopyNearbyCreature) {
      if (this.picked_creature_type==CreatureNONE) {
        this.picked_creature_type = this.findRandomNearbyHostileCreatureType(master);
      }
      
      
      if (this.picked_creature_type==CreatureNONE) {
        output = master.bestiary.getRandomEntryFromBestiary(master, EncounterType_HUNTINGGROUND, RER_flag(RER_BREF_IGNORE_SETTLEMENT, true), filter);
        return output;
      }
      
      
      output = master.bestiary.getEntry(master, this.picked_creature_type);
      
      return output;
      
    }
    
    NDEBUG("RER warning: RER_PlaceholderStaticEncounter::getBestiaryEntry(), returning RER_BestiaryEntryNull.");
    return new RER_BestiaryEntryNull in master;
  }
  
  private function findRandomNearbyHostileCreatureType(master: CRandomEncounters): CreatureType {
    var possible_types: array<CreatureType>;
    var entities: array<CGameplayEntity>;
    var current_type: CreatureType;
    var current_entity: CEntity;
    var i: int;
    FindGameplayEntitiesCloseToPoint(entities, this.position, this.radius+20, 1*((int)(this.radius)), , FLAG_ExcludePlayer|FLAG_OnlyAliveActors|FLAG_Attitude_Hostile, thePlayer, 'CNewNPC');
    for (i = 0; i<entities.Size(); i += 1) {
      current_entity = (CEntity)(entities[i]);
      
      if (current_entity) {
        current_type = master.bestiary.getCreatureTypeFromReadableName(current_entity.GetReadableName());
        if (current_type==CreatureNONE) {
          continue;
        }
        
        possible_types.PushBack(current_type);
      }
      
    }
    
    i = possible_types.Size();
    if (i<=0) {
      return CreatureNONE;
    }
    
    i = RandRange(i, 0);
    return possible_types[i];
  }
  
}


function RER_placeholderStaticEncounterCanSpawnAtPosition(position: Vector, rng: RandomNumberGenerator, playthrough_seed: int): bool {
  var seed: int;
  rng.useSeed(true).setSeed((int)((playthrough_seed+position.X+position.Y+position.Z)));
  return rng.nextRange(100, 0)>20;
}

class RER_StaticEncounter {
  var bestiary_entry: RER_BestiaryEntry;
  
  var position: Vector;
  
  var region_constraint: RER_RegionConstraint;
  
  var type: RER_StaticEncounterType;
  
  default type = StaticEncounterType_SMALL;
  
  var radius: float;
  
  default radius = 0.01;
  
  public latent function getBestiaryEntry(master: CRandomEncounters): RER_BestiaryEntry {
    return this.bestiary_entry;
  }
  
  public function isInRegion(region: string): bool {
    if (this.region_constraint==RER_RegionConstraint_NO_VELEN && (region=="no_mans_land" || region=="novigrad") || this.region_constraint==RER_RegionConstraint_NO_SKELLIGE && (region=="skellige" || region=="kaer_morhen") || this.region_constraint==RER_RegionConstraint_NO_TOUSSAINT && region=="bob" || this.region_constraint==RER_RegionConstraint_NO_WHITEORCHARD && region=="prolog_village" || this.region_constraint==RER_RegionConstraint_ONLY_TOUSSAINT && region!="bob" || this.region_constraint==RER_RegionConstraint_ONLY_WHITEORCHARD && region!="prolog_village" || this.region_constraint==RER_RegionConstraint_ONLY_SKELLIGE && region!="skellige" && region!="kaer_morhen" || this.region_constraint==RER_RegionConstraint_ONLY_VELEN && region!="no_mans_land" && region!="novigrad") {
      return false;
    }
    
    return true;
  }
  
  public function canSpawn(player_position: Vector, small_chance: float, large_chance: float, max_distance: float, current_region: string): bool {
    var entities: array<CGameplayEntity>;
    var radius: float;
    var i: int;
    if (!this.isInRegion(current_region)) {
      return false;
    }
    
    if (!this.rollSpawningChance(small_chance, large_chance)) {
      return false;
    }
    
    radius = this.radius*this.radius;
    if (VecDistanceSquared2D(player_position, this.position)>max_distance*max_distance) {
      return false;
    }
    
    radius = MinF(this.radius*this.radius*2, max_distance*0.5);
    if (VecDistanceSquared2D(player_position, this.position)<radius) {
      return false;
    }
    
    FindGameplayEntitiesCloseToPoint(entities, this.position, this.radius+20, (int)(1*(this.radius)), , , , 'CNewNPC');
    if (areThereEntitiesWithSameTemplate(entities)) {
      return false;
    }
    
    NLOG("StaticEncounter can spawn");
    return true;
  }
  
  private function areThereEntitiesWithSameTemplate(entities: array<CGameplayEntity>): bool {
    var hashed_name: string;
    var i: int;
    for (i = 0; i<entities.Size(); i += 1) {
      hashed_name = entities[i].GetReadableName();
      
      if (this.isTemplateInEntry(hashed_name)) {
        NLOG("StaticEncounter already spawned");
        return true;
      }
      
    }
    
    return false;
  }
  
  private function isTemplateInEntry(template: string): bool {
    var i: int;
    for (i = 0; i<this.bestiary_entry.template_list.templates.Size(); i += 1) {
      if (this.bestiary_entry.template_list.templates[i].template==template) {
        return true;
      }
      
    }
    
    return false;
  }
  
  public function getSpawningPosition(): Vector {
    var max_attempt_count: int;
    var current_spawn_position: Vector;
    var i: int;
    max_attempt_count = 10;
    for (i = 0; i<max_attempt_count; i += 1) {
      current_spawn_position = this.position+VecRingRand(0, this.radius);
      
      if (getGroundPosition(current_spawn_position, , this.radius)) {
        return current_spawn_position;
      }
      
    }
    
    return this.position;
  }
  
  private function rollSpawningChance(small_chance: float, large_chance: float): bool {
    var spawn_chance: float;
    if (this.type==StaticEncounterType_LARGE) {
      spawn_chance = large_chance;
    }
    else  {
      spawn_chance = small_chance;
      
    }
    
    if (RandRangeF(100)<spawn_chance) {
      return true;
    }
    
    return false;
  }
  
}

statemachine class RER_StaticEncounterManager {
  var master: CRandomEncounters;
  
  var static_encounters: array<RER_StaticEncounter>;
  
  public latent function init(master: CRandomEncounters) {
    this.master = master;
  }
  
  public function registerStaticEncounter(master: CRandomEncounters, encounter: RER_StaticEncounter) {
    this.static_encounters.PushBack(encounter);
  }
  
  public function getOrStorePlaceholderStaticEncounterForPosition(position: Vector): RER_PlaceholderStaticEncounter {
    var placeholder_type: RER_PlaceholderStaticEncounterType;
    var new_placeholder: RER_PlaceholderStaticEncounter;
    var size: RER_StaticEncounterType;
    var i: int;
    for (i = 0; i<this.master.storages.general.placeholder_static_encounters.Size(); i += 1) {
      if (this.master.storages.general.placeholder_static_encounters[i].position.X!=position.X || this.master.storages.general.placeholder_static_encounters[i].position.Y!=position.Y) {
        continue;
      }
      
      
      return this.master.storages.general.placeholder_static_encounters[i];
    }
    
    size = StaticEncounterType_SMALL;
    if (RandRange(100, 0)<20) {
      size = StaticEncounterType_LARGE;
    }
    
    placeholder_type = RER_PSET_LearnFromEcosystem;
    if (RandRange(100, 0)<50) {
      placeholder_type = RER_PSET_CopyNearbyCreature;
    }
    
    new_placeholder = (new RER_PlaceholderStaticEncounter in this.master).init(false, position, 20, size, placeholder_type);
    this.master.storages.general.placeholder_static_encounters.PushBack(new_placeholder);
    this.master.storages.general.save();
    return new_placeholder;
  }
  
  public latent function startSpawning() {
  }
  
  private latent function registerStaticEncounters() {
  }
  
}


enum RER_StaticEncounterType {
  StaticEncounterType_SMALL = 0,
  StaticEncounterType_LARGE = 1,
}


latent function RER_registerStaticEncounter(master: CRandomEncounters, type: CreatureType, position: Vector, constraint: RER_RegionConstraint, radius: float, encounter_type: RER_StaticEncounterType) {
  var new_static_encounter: RER_StaticEncounter;
  new_static_encounter = new RER_StaticEncounter in master;
  new_static_encounter.bestiary_entry = master.bestiary.getEntry(master, type);
  new_static_encounter.position = position;
  new_static_encounter.region_constraint = constraint;
  new_static_encounter.radius = radius;
  new_static_encounter.type = encounter_type;
  master.static_encounter_manager.registerStaticEncounter(master, new_static_encounter);
}


latent function RER_registerPlaceholderStaticEncounter(master: CRandomEncounters, placeholder_type: RER_PlaceholderStaticEncounterType, position: Vector, constraint: RER_RegionConstraint, radius: float, encounter_type: RER_StaticEncounterType) {
  var new_static_encounter: RER_PlaceholderStaticEncounter;
  new_static_encounter = new RER_PlaceholderStaticEncounter in master;
  new_static_encounter.position = position;
  new_static_encounter.region_constraint = constraint;
  new_static_encounter.radius = radius;
  new_static_encounter.type = encounter_type;
  master.static_encounter_manager.registerStaticEncounter(master, new_static_encounter);
}


latent function RER_registerStaticEncountersLucOliver(master: CRandomEncounters) {
  RER_registerStaticEncounter(master, CreatureHAG, Vector(-417, 246, -0.1), RER_RegionConstraint_ONLY_WHITEORCHARD, 20, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureNOONWRAITH, Vector(-165, -104, 6.6), RER_RegionConstraint_ONLY_WHITEORCHARD, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureGHOUL, Vector(-92, -330, 32), RER_RegionConstraint_ONLY_WHITEORCHARD, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(32, -269, 13.3), RER_RegionConstraint_ONLY_WHITEORCHARD, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureDROWNER, Vector(120, -220, 0.5), RER_RegionConstraint_ONLY_WHITEORCHARD, 20, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureBEAR, Vector(92, -138, 4.2), RER_RegionConstraint_ONLY_WHITEORCHARD, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(137, 38, 1.1), RER_RegionConstraint_ONLY_WHITEORCHARD, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureWRAITH, Vector(-78, 295, 4), RER_RegionConstraint_ONLY_WHITEORCHARD, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureGHOUL, Vector(73, 285, 8.3), RER_RegionConstraint_ONLY_WHITEORCHARD, 20, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureBARGHEST, Vector(142, 326, 14.4), RER_RegionConstraint_ONLY_WHITEORCHARD, 20, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(406, 211, 15.2), RER_RegionConstraint_ONLY_WHITEORCHARD, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHAG, Vector(421, 191, -0.3), RER_RegionConstraint_ONLY_WHITEORCHARD, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureCHORT, Vector(311, 49, 0.2), RER_RegionConstraint_ONLY_WHITEORCHARD, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureDROWNER, Vector(360, -375, 0), RER_RegionConstraint_ONLY_VELEN, 50, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(620, -477, 0.9), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureALGHOUL, Vector(796, 490, 13.4), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureTROLL, Vector(1889, 47, 41.8), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureHAG, Vector(1487, 1132, -0.3), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureLESHEN, Vector(235, 1509, 19), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureFORKTAIL, Vector(103, 892, 7.7), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureBASILISK, Vector(-90, 1487, 9.3), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(1060, -305, 6), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHARPY, Vector(-98, 603, 11.1), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureWYVERN, Vector(1329, -326, 50), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureGHOUL, Vector(-218, 380, 15.4), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureDROWNER, Vector(375, 1963, 1), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureFIEND, Vector(1995, -643, 0), RER_RegionConstraint_ONLY_VELEN, 25, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureWRAITH, Vector(-447, -77, 10), RER_RegionConstraint_ONLY_VELEN, 15, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureENDREGA, Vector(512, 1232, 11.3), RER_RegionConstraint_ONLY_VELEN, 25, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHAG, Vector(-450, -440, 0), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureARACHAS, Vector(797, 2318, 7), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureFOGLET, Vector(529, -117, -7.9), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureNEKKER, Vector(161, -108, 5.4), RER_RegionConstraint_ONLY_VELEN, 20, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureBARGHEST, Vector(667, 150, 4.5), RER_RegionConstraint_ONLY_VELEN, 20, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHAG, Vector(1335, 524, 5.3), RER_RegionConstraint_ONLY_VELEN, 20, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureROTFIEND, Vector(350, 980, 1.5), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureELEMENTAL, Vector(2430, 977, 39.4), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureALGHOUL, Vector(1055, -1, 48.2), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureENDREGA, Vector(748, 902, 2.4), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureENDREGA, Vector(1627, -11, 13.2), RER_RegionConstraint_ONLY_VELEN, 15, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureGHOUL, Vector(1462, -850, 29.5), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureARACHAS, Vector(-92, 31, 10.3), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(625, 1403, 1.8), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureWYVERN, Vector(-255, 863, 30.8), RER_RegionConstraint_ONLY_VELEN, 15, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureARACHAS, Vector(1070, -638, 0.4), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureLESHEN, Vector(1268, -166, 58.4), RER_RegionConstraint_ONLY_VELEN, 30, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureGRYPHON, Vector(-162, -1117, 16.4), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureWRAITH, Vector(-213, -971, 7.8), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureBARGHEST, Vector(634, -909, 9.1), RER_RegionConstraint_ONLY_VELEN, 15, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureGARGOYLE, Vector(191, -1271, 3.3), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(1570, 1375, 3.3), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureWEREWOLF, Vector(1178, 2117, 1.7), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureNOONWRAITH, Vector(1529, 1928, 5.7), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureNIGHTWRAITH, Vector(2070, 925, 0.1), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureBEAR, Vector(671, 689, 81), RER_RegionConstraint_ONLY_SKELLIGE, 40, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureNIGHTWRAITH, Vector(589, 127, 40.1), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(436, 67, 37.7), RER_RegionConstraint_ONLY_SKELLIGE, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureCYCLOP, Vector(517, 429, 55.4), RER_RegionConstraint_ONLY_SKELLIGE, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureTROLL, Vector(430, 361, 44.6), RER_RegionConstraint_ONLY_SKELLIGE, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureDROWNER, Vector(751, -149, 31.2), RER_RegionConstraint_ONLY_SKELLIGE, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureEKIMMARA, Vector(866, 168, 66), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureELEMENTAL, Vector(1171, 187, 89.1), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureENDREGA, Vector(901, 328, 86.7), RER_RegionConstraint_ONLY_SKELLIGE, 15, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureKATAKAN, Vector(713, 482, 146.2), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(-791, 210, 10.2), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureNEKKER, Vector(-415, -244, 42.3), RER_RegionConstraint_ONLY_SKELLIGE, 20, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureLESHEN, Vector(-107, -223, 49), RER_RegionConstraint_ONLY_SKELLIGE, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureALGHOUL, Vector(93, 373, 18.4), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureCYCLOP, Vector(313, -467, 10.2), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureEKIMMARA, Vector(390, 738, 106.6), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureCYCLOP, Vector(1024, 712, 1.6), RER_RegionConstraint_ONLY_SKELLIGE, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureKATAKAN, Vector(1231, 27, 2), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureNOONWRAITH, Vector(-56, -1228, 5.2), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureBERSERKER, Vector(1278, 1980, 29.50), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHAG, Vector(1600, 1873, 5.7), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureWEREWOLF, Vector(-12, -514, 66), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureCYCLOP, Vector(-608, -617, 5.2), RER_RegionConstraint_ONLY_SKELLIGE, 20, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureHARPY, Vector(107, -686, 90.6), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureFOGLET, Vector(995, -146, 18.4), RER_RegionConstraint_ONLY_SKELLIGE, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureDROWNER, Vector(1116, -283, 1), RER_RegionConstraint_ONLY_SKELLIGE, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureBERSERKER, Vector(-1416, 1510, 24.3), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureCOCKATRICE, Vector(-1925, 1045, 7.7), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureDRACOLIZARD, Vector(-1534, 1176, 7.6), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureBERSERKER, Vector(1679, -1805, 8.8), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureFIEND, Vector(1998, -1990, 12.9), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureNEKKER, Vector(2509, 154, 21.3), RER_RegionConstraint_ONLY_SKELLIGE, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureSKELTROLL, Vector(2238, 85, 48.3), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureSIREN, Vector(2603, -196, 8.1), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(2711, -26, 30.6), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureSKELTROLL, Vector(2853, 50, 40.1), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureFORKTAIL, Vector(353, 1559, 8.5), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureCOCKATRICE, Vector(148, 2097, 7.2), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureHARPY, Vector(-508, 2115, 6.6), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureGRYPHON, Vector(-954, 1967, 7.2), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureARACHAS, Vector(-833, 2049, 1.3), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureGRYPHON, Vector(-218, -1962, 7.5), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureTROLL, Vector(-1770, -1898, 35.5), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureNEKKER, Vector(-1781, -1998, 1.4), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureBERSERKER, Vector(-2603, 1599, 25.1), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureGOLEM, Vector(1664, 2560, 40.5), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureALGHOUL, Vector(1536, 2612, 27.4), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureWEREWOLF, Vector(1249, 2534, 11, 6), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureLESHEN, Vector(2716, 1725, 30.5), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureGRYPHON, Vector(2570, 1585, 53.7), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureSPIDER, Vector(2055, 2331, 20.2), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureSPIDER, Vector(2305, 1996, 25.3), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureDRACOLIZARD, Vector(1087, -853, 45), RER_RegionConstraint_ONLY_TOUSSAINT, 15, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureBRUXA, Vector(777, -681, 41.8), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureSPIDER, Vector(-829, 4, 4.4), RER_RegionConstraint_ONLY_TOUSSAINT, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureECHINOPS, Vector(-180, -816, 18.3), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureDRACOLIZARD, Vector(1055, -601, 80), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureECHINOPS, Vector(127, -1492, 5.7), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureBARGHEST, Vector(525, -1833, 71.4), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureDROWNERDLC, Vector(-228, -1788, 43.4), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureGRYPHON, Vector(-10, -363, 31.7), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureNOONWRAITH, Vector(-446, -279, 1), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureNIGHTWRAITH, Vector(-446, -269, 1), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureDROWNERDLC, Vector(-853, -739, 61.1), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureWEREWOLF, Vector(-1206, -938, 116.6), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureBRUXA, Vector(-1195, -841, 117.2), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureDRACOLIZARD, Vector(-868, -466, 57), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureBARGHEST, Vector(-1000, -266, 14.1), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureSKELTROLL, Vector(-746, -74, 0), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureLESHEN, Vector(-780, -228, 6.7), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureDROWNERDLC, Vector(-853, -739, 61.1), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureWIGHT, Vector(-229, 375, 8.3), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureCENTIPEDE, Vector(-472, 5, 1.6), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureDROWNERDLC, Vector(-380, 192, 0), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureFIEND, Vector(-339, 480, 1.5), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureCYCLOP, Vector(-57, 481, 13.8), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureCENTIPEDE, Vector(164, 224, 1.5), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureWIGHT, Vector(-106, -184, 23.4), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureBASILISK, Vector(-69, -65, 10), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureTROLL, Vector(281, -13, 0.5), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureBARGHEST, Vector(49, -817, 6.3), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureCENTIPEDE, Vector(200, -742, 0.3), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureDROWNERDLC, Vector(531, -264, 12.1), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureBRUXA, Vector(439, -215, 1.1), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureECHINOPS, Vector(273, -2136, 63.3), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureWEREWOLF, Vector(678, -69, 7.1), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureCENTIPEDE, Vector(-1, -1989, 78.8), RER_RegionConstraint_ONLY_TOUSSAINT, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureWEREWOLF, Vector(473, -1559, 26.4), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureFLEDER, Vector(732, -1603, 14.3), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureKATAKAN, Vector(736, -1601, 13.9), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureEKIMMARA, Vector(736, -1393, 13), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureGARKAIN, Vector(728, -1596, 13.9), RER_RegionConstraint_ONLY_TOUSSAINT, 5, StaticEncounterType_LARGE);
}


latent function RER_registerStaticEncountersAeltoth(master: CRandomEncounters) {
  RER_registerStaticEncounter(master, CreatureDROWNER, Vector(360, -375, 0), RER_RegionConstraint_ONLY_VELEN, 50, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(620, -477, 0.9), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureENDREGA, Vector(730, -500, 11), RER_RegionConstraint_ONLY_VELEN, 50, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(1060, -305, 6), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureFORKTAIL, Vector(1310, -373, 22), RER_RegionConstraint_ONLY_VELEN, 50, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureWYVERN, Vector(1329, -326, 43), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureBEAR, Vector(990, -189, 15), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureENDREGA, Vector(1060, 1057, 7), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHARPY, Vector(-200, 795, 31), RER_RegionConstraint_ONLY_VELEN, 25, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureWYVERN, Vector(-286, 920, 14), RER_RegionConstraint_ONLY_VELEN, 25, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureBASILISK, Vector(-240, 565, 11), RER_RegionConstraint_ONLY_VELEN, 50, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureROTFIEND, Vector(530, 956, 1), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHAG, Vector(530, 956, 1), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureENDREGA, Vector(567, 1246, 9), RER_RegionConstraint_ONLY_VELEN, 15, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureGRYPHON, Vector(604, 1200, 12), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureDROWNER, Vector(375, 1963, 1), RER_RegionConstraint_ONLY_VELEN, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureROTFIEND, Vector(350, 980, 1.5), RER_RegionConstraint_ONLY_VELEN, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHAG, Vector(350, 980, 1.5), RER_RegionConstraint_ONLY_VELEN, 20, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureWEREWOLF, Vector(638, -644, 2.5), RER_RegionConstraint_ONLY_VELEN, 20, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureGHOUL, Vector(-24, 284, 1.5), RER_RegionConstraint_ONLY_WHITEORCHARD, 20, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(22, -264, 13), RER_RegionConstraint_ONLY_WHITEORCHARD, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureDROWNER, Vector(117, -208, -0.7), RER_RegionConstraint_ONLY_WHITEORCHARD, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureBEAR, Vector(88, -136, 4.25), RER_RegionConstraint_ONLY_WHITEORCHARD, 5, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(400, 208, 15), RER_RegionConstraint_ONLY_WHITEORCHARD, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureGHOUL, Vector(552, 186, 20), RER_RegionConstraint_ONLY_WHITEORCHARD, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureKIKIMORE, Vector(138, 348, 14), RER_RegionConstraint_ONLY_WHITEORCHARD, 20, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureNIGHTWRAITH, Vector(378, 173, 22), RER_RegionConstraint_ONLY_SKELLIGE, 15, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureFIEND, Vector(1995, -643, 0), RER_RegionConstraint_ONLY_VELEN, 25, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureWRAITH, Vector(-447, -77, 10), RER_RegionConstraint_ONLY_VELEN, 15, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureCOCKATRICE, Vector(-90, -848, 6), RER_RegionConstraint_ONLY_VELEN, 40, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureKATAKAN, Vector(1956, 32, 43), RER_RegionConstraint_ONLY_VELEN, 20, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureKATAKAN, Vector(58, 487, 10.45), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureTROLL, Vector(140, 393, 23), RER_RegionConstraint_ONLY_SKELLIGE, 5, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureFORKTAIL, Vector(11, 237, 39), RER_RegionConstraint_ONLY_SKELLIGE, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureCYCLOP, Vector(420, 188, 64), RER_RegionConstraint_ONLY_SKELLIGE, 20, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureHAG, Vector(88, 167, 0), RER_RegionConstraint_ONLY_SKELLIGE, 20, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureHARPY, Vector(645, 320, 87), RER_RegionConstraint_ONLY_SKELLIGE, 50, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureFIEND, Vector(737, 560, 155), RER_RegionConstraint_ONLY_SKELLIGE, 30, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureCYCLOP, Vector(1064, 570, 1), RER_RegionConstraint_ONLY_SKELLIGE, 50, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureARACHAS, Vector(978, 720, 18), RER_RegionConstraint_ONLY_SKELLIGE, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureBEAR, Vector(671, 689, 81), RER_RegionConstraint_ONLY_SKELLIGE, 40, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureLESHEN, Vector(546, 591, 63), RER_RegionConstraint_ONLY_SKELLIGE, 55, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureTROLL, Vector(426, 377, 44), RER_RegionConstraint_ONLY_SKELLIGE, 20, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureHAG, Vector(-99, -525, 63), RER_RegionConstraint_ONLY_SKELLIGE, 40, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureDROWNER, Vector(-99, -525, 63), RER_RegionConstraint_ONLY_SKELLIGE, 40, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureNEKKER, Vector(-99, -525, 63), RER_RegionConstraint_ONLY_SKELLIGE, 60, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(-10, -517, 66), RER_RegionConstraint_ONLY_SKELLIGE, 10, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureENDREGA, Vector(-450, -512, 38), RER_RegionConstraint_ONLY_SKELLIGE, 60, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureNIGHTWRAITH, Vector(588, 142, 35), RER_RegionConstraint_ONLY_SKELLIGE, 10, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureDROWNER, Vector(750, -149, 31), RER_RegionConstraint_ONLY_SKELLIGE, 4, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureCHORT, Vector(792, -529, 78), RER_RegionConstraint_ONLY_SKELLIGE, 4, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureSIREN, Vector(387, -1161, 0), RER_RegionConstraint_ONLY_SKELLIGE, 20, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureHUMAN, Vector(432, -3, 34), RER_RegionConstraint_ONLY_SKELLIGE, 100, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureCYCLOP, Vector(-624, -617, 5), RER_RegionConstraint_ONLY_SKELLIGE, 100, StaticEncounterType_LARGE);
  RER_registerStaticEncounter(master, CreatureHAG, Vector(-1489, 1248, 0), RER_RegionConstraint_ONLY_SKELLIGE, 30, StaticEncounterType_SMALL);
  RER_registerStaticEncounter(master, CreatureWYVERN, Vector(-1536, 1175, 0), RER_RegionConstraint_ONLY_SKELLIGE, 30, StaticEncounterType_LARGE);
}

state Spawning in RER_StaticEncounterManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_StaticEncounterManager - state Spawning");
    this.Spawning_main();
  }
  
  entry function Spawning_main() {
    this.spawnStaticEncounters(parent.master);
    parent.GotoState('Waiting');
  }
  
  public latent function spawnStaticEncounters(master: CRandomEncounters) {
    var player_position: Vector;
    var current_region: string;
    var max_distance: float;
    var large_chance: float;
    var small_chance: float;
    var has_spawned: bool;
    var i: int;
    if (isPlayerBusy()) {
      return ;
    }
    
    Sleep(10);
    current_region = AreaTypeToName(theGame.GetCommonMapManager().GetCurrentArea());
    max_distance = StringToFloat(theGame.GetInGameConfigWrapper().GetVarValue('RERencountersGeneral', 'killThresholdDistance'));
    if (small_chance+large_chance<=0) {
      return ;
    }
    
    player_position = thePlayer.GetWorldPosition();
    for (i = 0; i<parent.static_encounters.Size(); i += 1) {
      has_spawned = this.trySpawnStaticEncounter(master, parent.static_encounters[i], player_position, max_distance, small_chance, large_chance, current_region);
      
      SleepOneFrame();
    }
    
  }
  
  private latent function trySpawnStaticEncounter(master: CRandomEncounters, encounter: RER_StaticEncounter, player_position: Vector, max_distance: float, small_chance: float, large_chance: float, current_region: string): bool {
    var composition: CreatureHuntingGroundComposition;
    if (!encounter.canSpawn(player_position, small_chance, large_chance, max_distance, current_region)) {
      return false;
    }
    
    composition = new CreatureHuntingGroundComposition in master;
    composition.init(master.settings);
    composition.setBestiaryEntry(encounter.getBestiaryEntry(master)).setSpawnPosition(encounter.getSpawningPosition()).spawn(master);
    return true;
  }
  
  private latent function spawnPlaceholderStaticEncounters(master: CRandomEncounters, player_position: Vector, max_distance: float, small_chance: float, large_chance: float, current_region: string) {
    var placeholder_static_encounter: RER_PlaceholderStaticEncounter;
    var rng: RandomNumberGenerator;
    var positions: array<Vector>;
    var current_position: Vector;
    var can_spawn: bool;
    var i: int;
    positions = this.getNearbyPointOfInterests(player_position, max_distance);
    rng = new RandomNumberGenerator in this;
    NLOG("spawnPlaceholderStaticEncounters(), found "+positions.Size()+" available point of interests for placeholder static encounters");
    for (i = 0; i<positions.Size(); i += 1) {
      SleepOneFrame();
      
      current_position = positions[i];
      
      can_spawn = RER_placeholderStaticEncounterCanSpawnAtPosition(current_position, rng, master.storages.general.playthrough_seed);
      
      if (!can_spawn) {
        continue;
      }
      
      
      NLOG("spawnPlaceholderStaticEncounters(), placeholder static encounter can spawn at "+VecToString(current_position));
      
      placeholder_static_encounter = parent.getOrStorePlaceholderStaticEncounterForPosition(current_position);
      
      this.trySpawnStaticEncounter(master, placeholder_static_encounter, player_position, max_distance, small_chance, large_chance, current_region);
    }
    
    parent.master.storages.general.save();
  }
  
  private function getNearbyPointOfInterests(player_position: Vector, max_distance: float): array<Vector> {
    var point_of_interests: array<SEntityMapPinInfo>;
    var entities: array<CGameplayEntity>;
    var current_position: Vector;
    var current_distance: float;
    var output: array<Vector>;
    var i: int;
    FindGameplayEntitiesInRange(entities, thePlayer, max_distance, 500, 'RER_contractPointOfInterest');
    for (i = 0; i<entities.Size(); i += 1) {
      output.PushBack(entities[i].GetWorldPosition());
    }
    
    point_of_interests = getPointOfInterests();
    for (i = 0; i<point_of_interests.Size(); i += 1) {
      current_position = point_of_interests[i].entityPosition;
      
      current_distance = VecDistanceSquared2D(player_position, current_position);
      
      if (current_distance>max_distance) {
        continue;
      }
      
      
      output.PushBack(current_position);
    }
    
    return output;
  }
  
  private function getPointOfInterests(): array<SEntityMapPinInfo> {
    var output: array<SEntityMapPinInfo>;
    var all_pins: array<SEntityMapPinInfo>;
    var i: int;
    all_pins = theGame.GetCommonMapManager().GetEntityMapPins(theGame.GetWorld().GetDepotPath());
    for (i = 0; i<all_pins.Size(); i += 1) {
      if (all_pins[i].entityType=='MonsterNest' || all_pins[i].entityType=='InfestedVineyard' || all_pins[i].entityType=='BanditCamp' || all_pins[i].entityType=='BanditCampfire' || all_pins[i].entityType=='BossAndTreasure' || all_pins[i].entityType=='RescuingTown' || all_pins[i].entityType=='DungeonCrawl' || all_pins[i].entityType=='Hideout' || all_pins[i].entityType=='Plegmund' || all_pins[i].entityType=='KnightErrant' || all_pins[i].entityType=='WineContract' || all_pins[i].entityType=='SignalingStake' || all_pins[i].entityType=='MonsterNest' || all_pins[i].entityType=='TreasureHuntMappin' || all_pins[i].entityType=='PointOfInterestMappin' || all_pins[i].entityType=='MonsterNestDisabled' || all_pins[i].entityType=='InfestedVineyardDisabled' || all_pins[i].entityType=='BanditCampDisabled' || all_pins[i].entityType=='BanditCampfireDisabled' || all_pins[i].entityType=='BossAndTreasureDisabled' || all_pins[i].entityType=='RescuingTownDisabled' || all_pins[i].entityType=='DungeonCrawlDisabled' || all_pins[i].entityType=='HideoutDisabled' || all_pins[i].entityType=='PlegmundDisabled' || all_pins[i].entityType=='KnightErrantDisabled' || all_pins[i].entityType=='WineContractDisabled' || all_pins[i].entityType=='SignalingStakeDisabled' || all_pins[i].entityType=='MonsterNestDisabled' || all_pins[i].entityType=='TreasureHuntMappinDisabled' || all_pins[i].entityType=='PointOfInterestMappinDisabled' || all_pins[i].entityType=='PointOfInterestMappinDisabled') {
        output.PushBack(all_pins[i]);
      }
      
    }
    
    return output;
  }
  
}

state Waiting in RER_StaticEncounterManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_StaticEncounterManager - state WAITING");
  }
  
}

abstract class RER_BaseStorage {
  public function save(): bool {
    NLOG("RER_BaseStorage::save()");
    return true;
  }
  
}

class RER_BountyStorage extends RER_BaseStorage {
  var whiteorchard_level: int;
  
  var velen_level: int;
  
  var skellige_level: int;
  
  var toussaint_level: int;
  
  var kaermorhen_level: int;
  
  var unknown_level: int;
  
  var current_bounty: RER_Bounty;
  
}

class RER_StorageCollection {
  var general: RER_GeneralStorage;
  
  var ecosystem: RER_EcosystemStorage;
  
  var bounty: RER_BountyStorage;
  
  var contract: RER_ContractStorage;
  
  var tracker: RER_TrackerStorage;
  
}


function RER_loadStorageCollection(master: CRandomEncounters) {
  if (!master.storages) {
    NLOG("RER_loadStorageCollection() - Instantiating new storage collection");
    master.storages = new RER_StorageCollection in master;
  }
  
  if (!master.storages.general) {
    NLOG("RER_loadStorageCollection() - Instantiating new RER_GeneralStorage");
    master.storages.general = new RER_GeneralStorage in master.storages;
  }
  
  if (!master.storages.ecosystem) {
    NLOG("RER_loadStorageCollection() - Instantiating new RER_EcosystemStorage");
    master.storages.ecosystem = new RER_EcosystemStorage in master.storages;
  }
  
  if (!master.storages.bounty) {
    NLOG("RER_loadStorageCollection() - Instantiating RER_BountyStorage");
    master.storages.bounty = new RER_BountyStorage in master.storages;
  }
  
  if (!master.storages.contract) {
    NLOG("RER_loadStorageCollection() - Instantiating new RER_ContractStorage");
    master.storages.contract = new RER_ContractStorage in master.storages;
  }
  
  if (!master.storages.tracker) {
    NLOG("RER_loadStorageCollection() - Instantiating new RER_TrackerStorage");
    master.storages.tracker = new RER_TrackerStorage in master.storages;
  }
  
  master.storages.tracker.init();
}

class RER_ContractStorage extends RER_BaseStorage {
  var completed_contracts: array<RER_ContractSeedFactory>;
  
  var active_contract: RER_ContractSeedFactory;
  
  var killed_targets: array<bool>;
  
  var has_ongoing_contract: bool;
  
}

class RER_EcosystemStorage extends RER_BaseStorage {
  public var ecosystem_areas: array<EcosystemArea>;
  
}

class RER_GeneralStorage extends RER_BaseStorage {
  var playthrough_seed: int;
  
  var placeholder_static_encounters: array<RER_PlaceholderStaticEncounter>;
  
}

class RER_TrackerStorage extends RER_BaseStorage {
  var encounters_spawned: array<int>;
  
  var encounters_killed: array<int>;
  
  var encounters_recycled: array<int>;
  
  var encounters_cancelled: int;
  
  var creatures_spawned: array<int>;
  
  public function init() {
    var i: int;
    if (this.encounters_spawned.Size()<=0) {
      for (i = 0; i<EncounterType_MAX; i += 1) {
        this.encounters_spawned.PushBack(0);
      }
      
    }
    
    if (this.encounters_killed.Size()<=0) {
      for (i = 0; i<EncounterType_MAX; i += 1) {
        this.encounters_killed.PushBack(0);
      }
      
    }
    
    if (this.encounters_recycled.Size()<=0) {
      for (i = 0; i<EncounterType_MAX; i += 1) {
        this.encounters_recycled.PushBack(0);
      }
      
    }
    
    if (this.creatures_spawned.Size()<=0) {
      for (i = 0; i<CreatureMAX; i += 1) {
        this.creatures_spawned.PushBack(0);
      }
      
    }
    
  }
  
}


function RER_getTrackerStorage(): RER_TrackerStorage {
  var master: CRandomEncounters;
  if (!getRandomEncounters(master)) {
    NLOG("RER_getTrackerStorage(), returning NULL");
    return NULL;
  }
  
  NLOG("RER_getTrackerStorage(), returning tracker storage");
  return master.storages.tracker;
}


function RER_emitEncounterSpawned(master: CRandomEncounters, encounter: EncounterType) {
  var storage: RER_TrackerStorage;
  storage = master.storages.tracker;
  if (storage) {
    storage.encounters_spawned[encounter] += 1;
  }
  
}


function RER_emitEncounterKilled(master: CRandomEncounters, encounter: EncounterType) {
  var storage: RER_TrackerStorage;
  storage = master.storages.tracker;
  if (storage) {
    storage.encounters_killed[encounter] += 1;
  }
  
}


function RER_emitEncounterRecycled(master: CRandomEncounters, encounter: EncounterType) {
  var storage: RER_TrackerStorage;
  storage = master.storages.tracker;
  if (storage) {
    storage.encounters_recycled[encounter] += 1;
  }
  
}


function RER_emitEncounterCancelled(master: CRandomEncounters) {
  var storage: RER_TrackerStorage;
  storage = master.storages.tracker;
  if (storage) {
    storage.encounters_cancelled += 1;
  }
  
}


function RER_emitCreatureSpawned(master: CRandomEncounters, type: CreatureType, count: int) {
  var storage: RER_TrackerStorage;
  storage = master.storages.tracker;
  if (storage) {
    storage.creatures_spawned[type] += count;
  }
  
}

abstract class RER_EventsListener {
  public var active: bool;
  
  public var is_ready: bool;
  
  default is_ready = false;
  
  public latent function onReady(manager: RER_EventsManager) {
    this.active = true;
    this.loadSettings();
  }
  
  public latent function onInterval(was_spawn_already_triggered: bool, master: CRandomEncounters, delta: float, chance_scale: float): bool {
    return was_spawn_already_triggered;
  }
  
  public latent function loadSettings() {
  }
  
}

statemachine class RER_EventsManager extends CEntity {
  public var listeners: array<RER_EventsListener>;
  
  public function addListener(listener: RER_EventsListener) {
    var master: CRandomEncounters;
    this.listeners.PushBack(listener);
  }
  
  public var master: CRandomEncounters;
  
  public function init(master: CRandomEncounters) {
    var internal_cooldown: float;
    var delay: float;
    var chance_scale: float;
    this.master = master;
    this.addListener(new RER_ListenerFightNoise in this);
    this.addListener(new RER_ListenerBloodNecrophages in this);
    this.addListener(new RER_ListenerFillCreaturesGroup in this);
    this.addListener(new RER_ListenerBodiesNecrophages in this);
    this.addListener(new RER_ListenerEntersSwamp in this);
    this.addListener(new RER_ListenerMeditationAmbush in this);
    this.addListener(new RER_ListenerEcosystemKills in this);
  }
  
  public var internal_cooldown: float;
  
  public var delay: float;
  
  public var chance_scale: float;
  
  public function start() {
    NLOG("RER_EventsManager - start()");
    this.delay = this.master.settings.event_system_interval;
    if (this.delay>0) {
      this.GotoState('Starting');
    }
    
  }
  
}

class RER_ListenerBloodNecrophages extends RER_EventsListener {
  var time_before_other_spawn: float;
  
  default time_before_other_spawn = 0;
  
  var trigger_chance: float;
  
  private var already_spawned_this_combat: bool;
  
  public latent function loadSettings() {
    var inGameConfigWrapper: CInGameConfigWrapper;
    inGameConfigWrapper = theGame.GetInGameConfigWrapper();
    this.trigger_chance = StringToFloat(inGameConfigWrapper.GetVarValue('RERevents', 'eventBloodNecrophages'));
    this.active = this.trigger_chance>0;
  }
  
  public latent function onInterval(was_spawn_already_triggered: bool, master: CRandomEncounters, delta: float, chance_scale: float): bool {
    var type: CreatureType;
    var is_in_combat: bool;
    var health_missing_perc: float;
    is_in_combat = thePlayer.IsInCombat();
    if (is_in_combat && (was_spawn_already_triggered || this.already_spawned_this_combat)) {
      this.already_spawned_this_combat = true;
      return false;
    }
    
    if (this.time_before_other_spawn>0) {
      time_before_other_spawn -= delta;
      return false;
    }
    
    this.already_spawned_this_combat = false;
    health_missing_perc = 1-thePlayer.GetHealthPercents();
    if (RandRangeF(100)<this.trigger_chance*chance_scale*health_missing_perc) {
      if (shouldAbortCreatureSpawn(master.settings, master.rExtra, master.bestiary)) {
        NLOG("RER_ListenerBloodNecrophages - cancelled");
        return false;
      }
      
      type = this.getRandomNecrophageType(master);
      createRandomCreatureAmbush(master, type);
      this.time_before_other_spawn += master.events_manager.internal_cooldown;
      NLOG("RER_ListenerBloodNecrophages - spawn triggered type = "+type);
      return true;
    }
    
    return false;
  }
  
  private latent function getRandomNecrophageType(master: CRandomEncounters): CreatureType {
    var spawn_roller: SpawnRoller;
    var creatures_preferences: RER_CreaturePreferences;
    var i: int;
    var can_spawn_creature: bool;
    var manager: CWitcherJournalManager;
    var roll: SpawnRoller_Roll;
    spawn_roller = new SpawnRoller in this;
    spawn_roller.fill_arrays();
    creatures_preferences = new RER_CreaturePreferences in this;
    creatures_preferences.setIsNight(theGame.envMgr.IsNight()).setExternalFactorsCoefficient(master.settings.external_factors_coefficient).setIsNearWater(master.rExtra.IsPlayerNearWater()).setIsInForest(master.rExtra.IsPlayerInForest()).setIsInSwamp(master.rExtra.IsPlayerInSwamp()).setIsInCity(master.rExtra.isPlayerInSettlement() || master.rExtra.getCustomZone(thePlayer.GetWorldPosition())==REZ_CITY).setCurrentRegion(AreaTypeToName(theGame.GetCommonMapManager().GetCurrentArea()));
    creatures_preferences.reset();
    master.bestiary.entries[CreatureGHOUL].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureALGHOUL].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureDROWNER].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureDROWNERDLC].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureROTFIEND].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureWEREWOLF].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureEKIMMARA].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureKATAKAN].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureHAG].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureFOGLET].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureBRUXA].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureFLEDER].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureGARKAIN].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureDETLAFF].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    if (master.settings.only_known_bestiary_creatures) {
      manager = theGame.GetJournalManager();
      for (i = 0; i<CreatureMAX; i += 1) {
        can_spawn_creature = bestiaryCanSpawnEnemyTemplateList(master.bestiary.entries[i].template_list, manager);
        
        if (!can_spawn_creature) {
          spawn_roller.setCreatureCounter(i, 0);
        }
        
      }
      
    }
    
    roll = spawn_roller.rollCreatures(master.ecosystem_manager);
    return roll.roll;
  }
  
}

class RER_ListenerBodiesNecrophages extends RER_EventsListener {
  var time_before_other_spawn: float;
  
  default time_before_other_spawn = 0;
  
  var trigger_chance: float;
  
  var already_spawned_this_combat: bool;
  
  public latent function loadSettings() {
    var inGameConfigWrapper: CInGameConfigWrapper;
    inGameConfigWrapper = theGame.GetInGameConfigWrapper();
    this.trigger_chance = StringToFloat(inGameConfigWrapper.GetVarValue('RERevents', 'eventBodiesNecrophages'));
    this.active = this.trigger_chance>0;
  }
  
  public latent function onInterval(was_spawn_already_triggered: bool, master: CRandomEncounters, delta: float, chance_scale: float): bool {
    var type: CreatureType;
    var is_in_combat: bool;
    is_in_combat = thePlayer.IsInCombat();
    if (is_in_combat && (was_spawn_already_triggered || this.already_spawned_this_combat)) {
      this.already_spawned_this_combat = true;
      return false;
    }
    
    if (this.time_before_other_spawn>0) {
      time_before_other_spawn -= delta;
      return false;
    }
    
    this.already_spawned_this_combat = false;
    if (this.areThereRemainsNearby() && RandRangeF(100)<this.trigger_chance*chance_scale) {
      if (shouldAbortCreatureSpawn(master.settings, master.rExtra, master.bestiary)) {
        NLOG("RER_ListenerBodiesNecrophages - cancelled");
        return false;
      }
      
      type = this.getRandomNecrophageType(master);
      createRandomCreatureAmbush(master, type);
      this.time_before_other_spawn += master.events_manager.internal_cooldown;
      NLOG("RER_ListenerBodiesNecrophages - spawn triggered type = "+type);
      return true;
    }
    
    return false;
  }
  
  private function areThereRemainsNearby(): bool {
    var entities: array<CGameplayEntity>;
    var i: int;
    FindGameplayEntitiesInRange(entities, thePlayer, 25, 30, , FLAG_ExcludePlayer, , 'W3ActorRemains');
    return entities.Size()>0;
  }
  
  private latent function getRandomNecrophageType(master: CRandomEncounters): CreatureType {
    var spawn_roller: SpawnRoller;
    var creatures_preferences: RER_CreaturePreferences;
    var i: int;
    var can_spawn_creature: bool;
    var manager: CWitcherJournalManager;
    var roll: SpawnRoller_Roll;
    spawn_roller = new SpawnRoller in this;
    spawn_roller.fill_arrays();
    creatures_preferences = new RER_CreaturePreferences in this;
    creatures_preferences.setIsNight(theGame.envMgr.IsNight()).setExternalFactorsCoefficient(master.settings.external_factors_coefficient).setIsNearWater(master.rExtra.IsPlayerNearWater()).setIsInForest(master.rExtra.IsPlayerInForest()).setIsInSwamp(master.rExtra.IsPlayerInSwamp()).setIsInCity(master.rExtra.isPlayerInSettlement() || master.rExtra.getCustomZone(thePlayer.GetWorldPosition())==REZ_CITY).setCurrentRegion(AreaTypeToName(theGame.GetCommonMapManager().GetCurrentArea()));
    creatures_preferences.reset();
    master.bestiary.entries[CreatureGHOUL].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureALGHOUL].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureDROWNER].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureDROWNERDLC].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureROTFIEND].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureWEREWOLF].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureHAG].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureFOGLET].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureGARKAIN].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    if (master.settings.only_known_bestiary_creatures) {
      manager = theGame.GetJournalManager();
      for (i = 0; i<CreatureMAX; i += 1) {
        can_spawn_creature = bestiaryCanSpawnEnemyTemplateList(master.bestiary.entries[i].template_list, manager);
        
        if (!can_spawn_creature) {
          spawn_roller.setCreatureCounter(i, 0);
        }
        
      }
      
    }
    
    roll = spawn_roller.rollCreatures(master.ecosystem_manager);
    return roll.roll;
  }
  
}

class RER_ListenerEcosystemKills extends RER_EventsListener {
  var time_before_next_checkup: float;
  
  default time_before_next_checkup = 0;
  
  var was_player_in_combat: bool;
  
  var last_checkup: array<CreatureType>;
  
  public latent function loadSettings() {
    this.active = true;
  }
  
  public latent function onInterval(was_spawn_already_triggered: bool, master: CRandomEncounters, delta: float, chance_scale: float): bool {
    var is_player_in_combat: bool;
    var new_checkup: array<CreatureType>;
    var checkup_difference: array<int>;
    if (this.time_before_next_checkup>0) {
      time_before_next_checkup -= delta;
      return false;
    }
    
    is_player_in_combat = thePlayer.IsInCombat();
    if (!is_player_in_combat && !this.was_player_in_combat) {
      return false;
    }
    
    new_checkup = this.getCreatureTypesAroundPlayer(master);
    NLOG("last checkup:");
    this.debugShowCheckup(this.last_checkup);
    NLOG("new checkup:");
    this.debugShowCheckup(new_checkup);
    checkup_difference = getDifferenceBetweenCheckups(this.last_checkup, new_checkup);
    this.notifyEcosystemManager(master, checkup_difference);
    this.last_checkup = new_checkup;
    this.was_player_in_combat = is_player_in_combat;
    this.time_before_next_checkup += 5;
    return false;
  }
  
  private latent function getCreatureTypesAroundPlayer(master: CRandomEncounters): array<CreatureType> {
    var entities: array<CGameplayEntity>;
    var output: array<CreatureType>;
    var current_type: CreatureType;
    var i: int;
    FindGameplayEntitiesInRange(entities, thePlayer, 25, 10, , FLAG_Attitude_Hostile+FLAG_ExcludePlayer+FLAG_OnlyAliveActors+FLAG_OnlyActors, thePlayer, 'CNewNPC');
    for (i = 0; i<entities.Size(); i += 1) {
      if (((CNewNPC)(entities[i])) && ((CNewNPC)(entities[i])).GetNPCType()!=ENGT_Enemy) {
        continue;
      }
      
      
      if (((CNewNPC)(entities[i])).GetTarget()!=thePlayer) {
        continue;
      }
      
      
      NLOG("getCreatureTypesAroundPlayer, found one creature");
      
      current_type = master.bestiary.getCreatureTypeFromEntity((CEntity)(entities[i]));
      
      NLOG("getCreatureTypesAroundPlayer, found one creature, current type = "+current_type);
      
      if (current_type<CreatureMAX) {
        output.PushBack(current_type);
      }
      
    }
    
    return output;
  }
  
  private function getDifferenceBetweenCheckups(before: array<CreatureType>, after: array<CreatureType>): array<int> {
    var i: int;
    var differences: array<int>;
    for (i = 0; i<CreatureMAX; i += 1) {
      differences.PushBack(0);
    }
    
    for (i = 0; i<before.Size(); i += 1) {
      differences[before[i]] += 1;
    }
    
    for (i = 0; i<after.Size(); i += 1) {
      differences[before[i]] -= 1;
    }
    
    return differences;
  }
  
  private function notifyEcosystemManager(master: CRandomEncounters, differences: array<int>) {
    var power_changes: array<float>;
    var i: int;
    for (i = 0; i<CreatureMAX; i += 1) {
      if (differences[i]>0) {
        RER_tutorialTryShowEcosystem();
        master.ecosystem_manager.updatePowerForCreatureInCurrentEcosystemAreas(i, differences[i]*-1, thePlayer.GetWorldPosition());
      }
      
    }
    
  }
  
  private function debugShowCheckup(checkup: array<CreatureType>) {
    var i: int;
    for (i = 0; i<checkup.Size(); i += 1) {
      NLOG("checkup creature "+checkup[i]);
    }
    
  }
  
}

class RER_ListenerEntersSwamp extends RER_EventsListener {
  var was_in_swamp_last_run: bool;
  
  var type: CreatureType;
  
  var trigger_chance: float;
  
  public latent function loadSettings() {
    var inGameConfigWrapper: CInGameConfigWrapper;
    inGameConfigWrapper = theGame.GetInGameConfigWrapper();
    this.trigger_chance = StringToFloat(inGameConfigWrapper.GetVarValue('RERevents', 'eventEntersSwamp'));
    this.active = this.trigger_chance>0;
  }
  
  public latent function onInterval(was_spawn_already_triggered: bool, master: CRandomEncounters, delta: float, chance_scale: float): bool {
    var is_in_swamp_now: bool;
    if (was_spawn_already_triggered) {
      return false;
    }
    
    is_in_swamp_now = master.rExtra.IsPlayerInSwamp();
    if (is_in_swamp_now && !was_in_swamp_last_run && RandRangeF(100)<this.trigger_chance*chance_scale) {
      type = this.getRandomSwampCreatureType(master);
      NLOG("RER_ListenerEntersSwamp - swamp ambush triggered, "+type);
      createRandomCreatureAmbush(master, type);
      return true;
    }
    
    return false;
  }
  
  private latent function getRandomSwampCreatureType(master: CRandomEncounters): CreatureType {
    var spawn_roller: SpawnRoller;
    var creatures_preferences: RER_CreaturePreferences;
    var i: int;
    var can_spawn_creature: bool;
    var manager: CWitcherJournalManager;
    var roll: SpawnRoller_Roll;
    spawn_roller = new SpawnRoller in this;
    spawn_roller.fill_arrays();
    creatures_preferences = new RER_CreaturePreferences in this;
    creatures_preferences.setIsNight(theGame.envMgr.IsNight()).setExternalFactorsCoefficient(master.settings.external_factors_coefficient).setIsNearWater(master.rExtra.IsPlayerNearWater()).setIsInForest(master.rExtra.IsPlayerInForest()).setIsInSwamp(master.rExtra.IsPlayerInSwamp()).setIsInCity(master.rExtra.isPlayerInSettlement() || master.rExtra.getCustomZone(thePlayer.GetWorldPosition())==REZ_CITY);
    creatures_preferences.reset();
    master.bestiary.entries[CreatureDROWNER].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureDROWNERDLC].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureROTFIEND].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureWEREWOLF].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureHAG].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    master.bestiary.entries[CreatureFOGLET].setCreaturePreferences(creatures_preferences, EncounterType_DEFAULT).fillSpawnRoller(spawn_roller);
    if (master.settings.only_known_bestiary_creatures) {
      manager = theGame.GetJournalManager();
      for (i = 0; i<CreatureMAX; i += 1) {
        can_spawn_creature = bestiaryCanSpawnEnemyTemplateList(master.bestiary.entries[i].template_list, manager);
        
        if (!can_spawn_creature) {
          spawn_roller.setCreatureCounter(i, 0);
        }
        
      }
      
    }
    
    roll = spawn_roller.rollCreatures(master.ecosystem_manager);
    return roll.roll;
  }
  
}

class RER_ListenerFightNoise extends RER_EventsListener {
  private var already_spawned_this_combat: bool;
  
  var time_before_other_spawn: float;
  
  default time_before_other_spawn = 0;
  
  var trigger_chance: float;
  
  public latent function loadSettings() {
    var inGameConfigWrapper: CInGameConfigWrapper;
    inGameConfigWrapper = theGame.GetInGameConfigWrapper();
    this.trigger_chance = StringToFloat(inGameConfigWrapper.GetVarValue('RERevents', 'eventFightNoise'));
    this.active = this.trigger_chance>0;
  }
  
  public latent function onInterval(was_spawn_already_triggered: bool, master: CRandomEncounters, delta: float, chance_scale: float): bool {
    var is_in_combat: bool;
    is_in_combat = thePlayer.IsInCombat();
    if (is_in_combat && (was_spawn_already_triggered || this.already_spawned_this_combat)) {
      this.already_spawned_this_combat = true;
      return false;
    }
    
    if (this.time_before_other_spawn>0) {
      time_before_other_spawn -= delta;
      return false;
    }
    
    this.already_spawned_this_combat = false;
    if (is_in_combat && RandRangeF(100)<this.trigger_chance*chance_scale) {
      NLOG("RER_ListenerFightNoise - triggered");
      if (shouldAbortCreatureSpawn(master.settings, master.rExtra, master.bestiary)) {
        NLOG("RER_ListenerFightNoise - cancelled");
        return false;
      }
      
      this.already_spawned_this_combat = is_in_combat;
      this.time_before_other_spawn += master.events_manager.internal_cooldown;
      createRandomCreatureAmbush(master, CreatureNONE);
      return true;
    }
    
    return false;
  }
  
}

class RER_ListenerFillCreaturesGroup extends RER_EventsListener {
  var time_before_other_spawn: float;
  
  default time_before_other_spawn = 0;
  
  var trigger_chance: float;
  
  var can_duplicate_creatures_in_combat: bool;
  
  public latent function loadSettings() {
    var inGameConfigWrapper: CInGameConfigWrapper;
    inGameConfigWrapper = theGame.GetInGameConfigWrapper();
    this.trigger_chance = StringToFloat(inGameConfigWrapper.GetVarValue('RERevents', 'eventFillCreaturesGroup'));
    this.can_duplicate_creatures_in_combat = inGameConfigWrapper.GetVarValue('RERevents', 'eventFillCreaturesGroupAllowCombat');
    this.active = this.trigger_chance>0;
  }
  
  public latent function onInterval(was_spawn_already_triggered: bool, master: CRandomEncounters, delta: float, chance_scale: float): bool {
    var random_entity_to_duplicate: CNewNPC;
    var creature_height: float;
    if (was_spawn_already_triggered) {
      NLOG("RER_ListenerFillCreaturesGroup - spawn already triggered");
      return false;
    }
    
    if (this.time_before_other_spawn>0) {
      NLOG("RER_ListenerFillCreaturesGroup - delay between spawns");
      time_before_other_spawn -= delta;
      return false;
    }
    
    if (!this.getRandomNearbyEntity(random_entity_to_duplicate)) {
      return false;
    }
    
    if (RandRangeF(100)<this.trigger_chance*chance_scale) {
      creature_height = getCreatureHeight(random_entity_to_duplicate)*0.6;
      if (creature_height>1 && RandRangeF(creature_height)<1) {
        return false;
      }
      
      NLOG("RER_ListenerFillCreaturesGroup - duplicateRandomNearbyEntity");
      this.duplicateEntity(master, random_entity_to_duplicate);
      this.time_before_other_spawn += master.events_manager.internal_cooldown;
      return false;
    }
    
    return false;
  }
  
  private function getRandomNearbyEntity(out entity: CNewNPC): bool {
    var entities: array<CGameplayEntity>;
    var picked_npc_list: array<CNewNPC>;
    var picked_npc_index: int;
    var i: int;
    var picked_npc: CNewNPC;
    var boss_tag: name;
    var player_position: Vector;
    player_position = thePlayer.GetWorldPosition();
    FindGameplayEntitiesInRange(entities, thePlayer, 300, 100, , FLAG_Attitude_Hostile+FLAG_ExcludePlayer+FLAG_OnlyAliveActors, thePlayer, 'CNewNPC');
    boss_tag = thePlayer.GetBossTag();
    for (i = 0; i<entities.Size(); i += 1) {
      if (((CNewNPC)(entities[i])) && ((CNewNPC)(entities[i])).GetNPCType()==ENGT_Enemy && (this.can_duplicate_creatures_in_combat || !((CNewNPC)(entities[i])).IsInCombat()) && !((CNewNPC)(entities[i])).HasTag(boss_tag) && VecDistanceSquared2D(player_position, entities[i].GetWorldPosition())>30*30) {
        picked_npc_list.PushBack((CNewNPC)(entities[i]));
      }
      
    }
    
    if (picked_npc_list.Size()==0) {
      return false;
    }
    
    picked_npc_index = RandRange(picked_npc_list.Size());
    entity = picked_npc_list[picked_npc_index];
    return true;
  }
  
  private latent function duplicateEntity(master: CRandomEncounters, entity: CNewNPC) {
    var entity_template: CEntityTemplate;
    var created_entity: CEntity;
    var tags_array: array<name>;
    tags_array.PushBack('RandomEncountersReworked_Entity');
    NLOG("duplicating = "+StrAfterFirst(entity.ToString(), "::"));
    entity_template = (CEntityTemplate)(LoadResourceAsync(StrAfterFirst(entity.ToString(), "::"), true));
    created_entity = theGame.CreateEntity(entity_template, entity.GetWorldPosition(), entity.GetWorldRotation(), , , , , tags_array);
    ((CNewNPC)(created_entity)).SetLevel(getRandomLevelBasedOnSettings(master.settings));
  }
  
}

class RER_ListenerMeditationAmbush extends RER_EventsListener {
  var trigger_chance: float;
  
  public latent function loadSettings() {
    var inGameConfigWrapper: CInGameConfigWrapper;
    var time_before_other_spawn: float;
    var time_spent_meditating: int;
    var last_meditation_time: GameTime;
    inGameConfigWrapper = theGame.GetInGameConfigWrapper();
    this.trigger_chance = StringToFloat(inGameConfigWrapper.GetVarValue('RERevents', 'eventMeditationAmbush'));
    this.active = this.trigger_chance>0;
  }
  
  var time_before_other_spawn: float;
  
  default time_before_other_spawn = 0;
  
  var time_spent_meditating: int;
  
  var last_meditation_time: GameTime;
  
  public latent function onInterval(was_spawn_already_triggered: bool, master: CRandomEncounters, delta: float, chance_scale: float): bool {
    var current_state: CName;
    var is_meditating: bool;
    if (was_spawn_already_triggered) {
      return false;
    }
    
    current_state = thePlayer.GetCurrentStateName();
    is_meditating = current_state=='Meditation' || current_state=='MeditationWaiting';
    if (!is_meditating) {
      if (this.time_spent_meditating>0) {
        master.static_encounter_manager.startSpawning();
      }
      
      time_spent_meditating = 0;
      return false;
    }
    
    if (this.time_before_other_spawn>0) {
      time_before_other_spawn -= delta;
      return false;
    }
    
    if (time_spent_meditating==0) {
      time_spent_meditating = CeilF(delta);
    }
    else  {
      time_spent_meditating += GameTimeToSeconds(theGame.GetGameTime()-last_meditation_time);
      
    }
    
    last_meditation_time = theGame.GetGameTime();
    if (RandRangeF(100)<((this.trigger_chance*((float)(0.8+(time_spent_meditating/3600)))/12.0))*chance_scale) {
      NLOG("RER_ListenerMeditationAmbush - triggered, % increased by meditation = "+time_spent_meditating/3600);
      if (shouldAbortCreatureSpawn(master.settings, master.rExtra, master.bestiary)) {
        NLOG("RER_ListenerMeditationAmbush - cancelled");
        return false;
      }
      
      this.time_before_other_spawn += master.events_manager.internal_cooldown;
      createRandomCreatureAmbush(master, CreatureNONE);
      return true;
    }
    
    return false;
  }
  
}

state ListeningForEvents in RER_EventsManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    this.ListeningForEvents_main();
  }
  
  entry function ListeningForEvents_main() {
    var i: int;
    var listener: RER_EventsListener;
    var was_spawn_already_triggered: bool;
    var spawn_asked: bool;
    was_spawn_already_triggered = false;
    if (!parent.master.settings.is_enabled || !RER_modPowerIsEventSystemEnabled(parent.master.getModPower())) {
      parent.GotoState('Waiting');
    }
    
    for (i = 0; i<parent.listeners.Size(); i += 1) {
      listener = parent.listeners[i];
      
      if (!listener.is_ready) {
        listener.onReady(parent);
      }
      
      
      if (!listener.active) {
        continue;
      }
      
      
      was_spawn_already_triggered = listener.onInterval(was_spawn_already_triggered, parent.master, parent.delay, parent.chance_scale) || was_spawn_already_triggered;
    }
    
    parent.GotoState('Waiting');
  }
  
}

state Starting in RER_EventsManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    NLOG("RER_EventsManager - State Starting");
    this.Starting_main();
  }
  
  entry function Starting_main() {
    var inGameConfigWrapper: CInGameConfigWrapper;
    var listener: RER_EventsListener;
    var i: int;
    for (i = 0; i<parent.listeners.Size(); i += 1) {
      listener = parent.listeners[i];
      
      if (!listener.is_ready) {
        listener.onReady(parent);
      }
      
      
      listener.loadSettings();
    }
    
    inGameConfigWrapper = theGame.GetInGameConfigWrapper();
    parent.internal_cooldown = StringToFloat(inGameConfigWrapper.GetVarValue('RERevents', 'eventSystemICD'));
    parent.chance_scale = parent.delay/parent.internal_cooldown*parent.master.getModPower();
    NLOG("RER_EventsManager - chance_scale = "+parent.chance_scale+", delay ="+parent.delay);
    parent.GotoState('Waiting');
  }
  
}

state Waiting in RER_EventsManager {
  event OnEnterState(previous_state_name: name) {
    super.OnEnterState(previous_state_name);
    this.Waiting_main();
  }
  
  entry function Waiting_main() {
    Sleep(parent.delay);
    parent.GotoState('ListeningForEvents');
  }
  
}

function RER_tutorialTryShowAmbushed(): bool {
  if (!theGame.GetInGameConfigWrapper().GetVarValue('RERtutorials', 'RERtutorialAmbushed')) {
    return false;
  }
  
  RER_toggleHUD();
  NTUTO(GetLocStringByKey("rer_tutorial_ambush_title"), GetLocStringByKey("rer_tutorial_ambush_body"));
  RER_toggleHUD();
  theGame.GetInGameConfigWrapper().SetVarValue('RERtutorials', 'RERtutorialAmbushed', 0);
  theGame.SaveUserSettings();
  return true;
}

function RER_tutorialTryShowBounty(): bool {
  if (!theGame.GetInGameConfigWrapper().GetVarValue('RERtutorials', 'RERtutorialBountyHunting')) {
    return false;
  }
  
  RER_toggleHUD();
  NTUTO(GetLocStringByKey("rer_tutorial_bounty_title"), GetLocStringByKey("rer_tutorial_bounty_body"));
  RER_toggleHUD();
  theGame.GetInGameConfigWrapper().SetVarValue('RERtutorials', 'RERtutorialBountyHunting', 0);
  theGame.SaveUserSettings();
  return true;
}

function RER_tutorialTryShowBountyLevel(): bool {
  if (!theGame.GetInGameConfigWrapper().GetVarValue('RERtutorials', 'RERtutorialBountyLevel')) {
    return false;
  }
  
  RER_toggleHUD();
  NTUTO(GetLocStringByKey("rer_tutorial_bounty_level_title"), GetLocStringByKey("rer_tutorial_bounty_level_body"));
  RER_toggleHUD();
  theGame.GetInGameConfigWrapper().SetVarValue('RERtutorials', 'RERtutorialBountyLevel', 0);
  theGame.SaveUserSettings();
  return true;
}

function RER_tutorialTryShowBountyMaster(): bool {
  if (!theGame.GetInGameConfigWrapper().GetVarValue('RERtutorials', 'RERtutorialBountyMaster')) {
    return false;
  }
  
  RER_toggleHUD();
  NTUTO(GetLocStringByKey("rer_tutorial_bounty_master_title"), GetLocStringByKey("rer_tutorial_bounty_master_body"));
  RER_toggleHUD();
  theGame.GetInGameConfigWrapper().SetVarValue('RERtutorials', 'RERtutorialBountyMaster', 0);
  theGame.SaveUserSettings();
  return true;
}

function RER_tutorialTryShowClue(): bool {
  if (!theGame.GetInGameConfigWrapper().GetVarValue('RERtutorials', 'RERtutorialClueExamined')) {
    return false;
  }
  
  RER_toggleHUD();
  NTUTO(GetLocStringByKey("rer_tutorial_clue_title"), GetLocStringByKey("rer_tutorial_clue_body"));
  RER_toggleHUD();
  theGame.GetInGameConfigWrapper().SetVarValue('RERtutorials', 'RERtutorialClueExamined', 0);
  theGame.SaveUserSettings();
  return true;
}

function RER_tutorialTryShowContract(): bool {
  if (!theGame.GetInGameConfigWrapper().GetVarValue('RERtutorials', 'RERtutorialMonsterContract')) {
    return false;
  }
  
  RER_toggleHUD();
  NTUTO(GetLocStringByKey("rer_tutorial_contract_title"), GetLocStringByKey("rer_tutorial_contract_body"));
  RER_toggleHUD();
  theGame.GetInGameConfigWrapper().SetVarValue('RERtutorials', 'RERtutorialMonsterContract', 0);
  theGame.SaveUserSettings();
  return true;
}

function RER_tutorialTryShowEcosystem(): bool {
  if (!theGame.GetInGameConfigWrapper().GetVarValue('RERtutorials', 'RERtutorialEcosystem')) {
    return false;
  }
  
  RER_toggleHUD();
  NTUTO(GetLocStringByKey("rer_tutorial_ecosystem_title"), GetLocStringByKey("rer_tutorial_ecosystem_body"));
  RER_toggleHUD();
  theGame.GetInGameConfigWrapper().SetVarValue('RERtutorials', 'RERtutorialEcosystem', 0);
  theGame.SaveUserSettings();
  return true;
}

function RER_tutorialTryShowNoticeboard(): bool {
  if (!theGame.GetInGameConfigWrapper().GetVarValue('RERtutorials', 'RERtutorialNoticeboardEvent')) {
    return false;
  }
  
  RER_toggleHUD();
  NTUTO(GetLocStringByKey("rer_tutorial_noticeboard_event_title"), GetLocStringByKey("rer_tutorial_noticeboard_event_body"));
  RER_toggleHUD();
  theGame.GetInGameConfigWrapper().SetVarValue('RERtutorials', 'RERtutorialNoticeboardEvent', 0);
  theGame.SaveUserSettings();
  return true;
}

function RER_yellowFont(message: string): string {
  return "<font color='#CD7D03'>"+message+"</font>";
}

function RER_tutorialTryShowStarted(): bool {
  if (!theGame.GetInGameConfigWrapper().GetVarValue('RERtutorials', 'RERtutorialStarted')) {
    return false;
  }
  
  RER_toggleHUD();
  NTUTO(GetLocStringByKey("rer_tutorial_started_title"), GetLocStringByKey("rer_tutorial_started_body"));
  RER_toggleHUD();
  theGame.GetInGameConfigWrapper().SetVarValue('RERtutorials', 'RERtutorialStarted', 0);
  theGame.SaveUserSettings();
  return true;
}

function RER_tutorialTryShowTrophy(): bool {
  if (!theGame.GetInGameConfigWrapper().GetVarValue('RERtutorials', 'RERtutorialTrophy')) {
    return false;
  }
  
  RER_toggleHUD();
  NTUTO(GetLocStringByKey("rer_tutorial_rewards_title"), GetLocStringByKey("rer_tutorial_rewards_body"));
  RER_toggleHUD();
  theGame.GetInGameConfigWrapper().SetVarValue('RERtutorials', 'RERtutorialTrophy', 0);
  theGame.SaveUserSettings();
  return true;
}

