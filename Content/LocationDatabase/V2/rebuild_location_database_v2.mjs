import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const candidatePath = path.join(here, "city_candidate_pool_v2.json");
const detailPath = path.join(here, "city_detail_packs_v2.json");
const eventPath = path.join(here, "scene_event_library_v2.json");
const geographyPath = path.join(here, "city_geography_capabilities_v2.json");

const animals = [
  "xiaoman_hamster",
  "dengdeng_rabbit",
  "moji_cat",
  "tangyuan_puppy",
  "feifei_parrot",
  "xiaolu_guinea_pig"
];

const postcardTypes = [
  "daily_observation",
  "personality_reaction",
  "relationship_card",
  "motif_echo",
  "value_choice"
];

const microArcs = ["动作型", "误会型", "旁观型", "反转型", "回声型", "缺席型", "选择型"];

const oldCandidate = JSON.parse(fs.readFileSync(candidatePath, "utf8"));
const cities = oldCandidate.cities;

const coastalCityIds = new Set([
  "cn_shanghai", "cn_guangzhou", "cn_shenzhen", "cn_tianjin", "cn_qingdao", "cn_xiamen", "cn_fuzhou",
  "cn_quanzhou", "cn_ningbo", "cn_wenzhou", "cn_dalian", "cn_haikou", "cn_sanya", "cn_hongkong",
  "cn_macau", "tw_tainan", "tw_kaohsiung", "jp_tokyo", "jp_osaka", "jp_fukuoka", "jp_nagoya",
  "jp_kobe", "jp_yokohama", "kr_busan", "kr_incheon", "kr_jeju", "sg_singapore", "my_penang",
  "my_melaka", "th_bangkok", "vn_ho_chi_minh", "vn_da_nang", "id_jakarta", "id_denpasar",
  "ph_manila", "ph_cebu", "bn_bandar_seri_begawan", "tl_dili", "mv_male", "in_mumbai",
  "in_chennai", "lk_colombo", "pk_karachi", "tr_istanbul", "tr_izmir", "tr_antalya", "ae_dubai",
  "qa_doha", "il_tel_aviv", "lb_beirut", "om_muscat", "bh_manama", "kw_kuwait_city", "cy_nicosia",
  "fr_marseille", "fr_nice", "uk_london", "uk_liverpool", "ie_dublin", "es_barcelona", "es_valencia",
  "pt_lisbon", "pt_porto", "it_venice", "it_naples", "de_hamburg", "nl_amsterdam", "nl_rotterdam",
  "be_antwerp", "hr_dubrovnik", "gr_athens", "gr_thessaloniki", "dk_copenhagen", "se_stockholm",
  "se_gothenburg", "no_oslo", "fi_helsinki", "is_reykjavik", "ru_saint_petersburg", "mt_valletta",
  "mc_monaco", "us_new_york", "us_los_angeles", "us_san_francisco", "us_boston", "us_seattle",
  "us_portland", "us_new_orleans", "us_miami", "us_san_diego", "ca_vancouver", "ca_montreal",
  "ca_quebec_city", "ca_halifax", "mx_merida", "cu_havana", "pa_panama_city", "do_santo_domingo",
  "jm_kingston", "tt_port_of_spain", "bs_nassau", "co_bogota", "pe_lima", "ar_buenos_aires",
  "br_rio", "br_salvador", "br_recife", "uy_montevideo", "gy_georgetown", "sr_paramaribo",
  "eg_cairo", "ma_casablanca", "za_cape_town", "tz_dar_es_salaam", "ng_lagos", "gh_accra",
  "sn_dakar", "tn_tunis", "dz_algiers", "mu_port_louis", "ao_luanda", "cm_douala", "ci_abidjan",
  "mz_maputo", "mu_curepipe", "au_sydney", "au_melbourne", "au_brisbane", "au_perth", "au_adelaide",
  "au_hobart", "nz_auckland", "nz_wellington", "fj_suva", "pg_port_moresby", "nc_noumea",
  "pf_papeete", "au_darwin", "nz_christchurch", "ws_apia", "to_nukualofa", "vu_port_vila"
]);

const seasideCityIds = new Set([
  "cn_qingdao", "cn_xiamen", "cn_dalian", "cn_haikou", "cn_sanya", "cn_hongkong", "cn_macau",
  "tw_kaohsiung", "jp_fukuoka", "jp_kobe", "jp_yokohama", "kr_busan", "kr_incheon", "kr_jeju",
  "sg_singapore", "my_penang", "vn_da_nang", "id_denpasar", "ph_cebu", "mv_male", "in_mumbai",
  "in_chennai", "lk_colombo", "pk_karachi", "tr_izmir", "tr_antalya", "ae_dubai", "qa_doha",
  "il_tel_aviv", "lb_beirut", "om_muscat", "bh_manama", "kw_kuwait_city", "fr_marseille", "fr_nice",
  "es_barcelona", "es_valencia", "pt_lisbon", "pt_porto", "it_venice", "it_naples", "hr_dubrovnik",
  "gr_athens", "gr_thessaloniki", "dk_copenhagen", "se_stockholm", "no_oslo", "fi_helsinki",
  "is_reykjavik", "mt_valletta", "mc_monaco", "us_los_angeles", "us_san_francisco", "us_boston",
  "us_seattle", "us_new_orleans", "us_miami", "us_san_diego", "ca_vancouver", "ca_halifax",
  "cu_havana", "do_santo_domingo", "jm_kingston", "tt_port_of_spain", "bs_nassau", "br_rio",
  "za_cape_town", "mu_port_louis", "au_sydney", "au_melbourne", "au_brisbane", "au_perth",
  "au_adelaide", "au_hobart", "nz_auckland", "nz_wellington", "fj_suva", "pg_port_moresby",
  "nc_noumea", "pf_papeete", "au_darwin", "nz_christchurch", "ws_apia", "to_nukualofa", "vu_port_vila"
]);

for (const inlandId of ["cy_nicosia", "th_bangkok", "uk_london", "ca_montreal", "ca_quebec_city", "co_bogota", "eg_cairo", "mu_curepipe"]) {
  coastalCityIds.delete(inlandId);
}

const pierOrFerryCityIds = new Set([
  ...coastalCityIds,
  "tr_istanbul", "it_venice", "nl_amsterdam", "uk_london", "us_new_york", "ca_vancouver",
  "bd_dhaka", "iq_baghdad", "eg_cairo", "fr_paris"
]);

const majorRiverOrLakeCityIds = new Set([
  ...coastalCityIds,
  ...pierOrFerryCityIds,
  "cn_beijing", "cn_shanghai", "cn_guangzhou", "cn_shenzhen", "cn_chengdu", "cn_hangzhou",
  "cn_suzhou", "cn_nanjing", "cn_wuhan", "cn_xian", "cn_chongqing", "cn_tianjin", "cn_changsha",
  "cn_kunming", "cn_dali", "cn_lijiang", "cn_guilin", "cn_fuzhou", "cn_ningbo", "cn_wenzhou",
  "cn_hefei", "cn_jinan", "cn_zhengzhou", "cn_luoyang", "cn_haerbin", "cn_changchun",
  "cn_shenyang", "cn_huhehaote", "cn_yinchuan", "cn_lanzhou", "cn_xining", "cn_lhasa",
  "cn_nanning", "cn_guiyang", "cn_taiyuan", "cn_nanchang", "cn_shijiazhuang", "tw_taipei",
  "jp_tokyo", "jp_kyoto", "jp_osaka", "jp_sapporo", "jp_nagoya", "kr_seoul", "mn_ulaanbaatar",
  "my_kuala_lumpur", "th_bangkok", "th_chiang_mai", "vn_hanoi", "vn_ho_chi_minh", "id_yogyakarta",
  "kh_phnom_penh", "kh_siem_reap", "la_vientiane", "mm_yangon", "bt_thimphu", "in_delhi",
  "in_kolkata", "in_bengaluru", "np_kathmandu", "bd_dhaka", "pk_lahore", "ir_tehran",
  "ir_isfahan", "iq_baghdad", "kz_almaty", "uz_tashkent", "tr_ankara", "az_baku", "ge_tbilisi",
  "am_yerevan", "fr_paris", "fr_lyon", "fr_toulouse", "fr_bordeaux", "uk_london",
  "uk_manchester", "uk_edinburgh", "uk_bristol", "es_madrid", "es_seville", "es_granada",
  "it_rome", "it_milan", "it_florence", "it_bologna", "de_berlin", "de_munich", "de_cologne",
  "de_frankfurt", "de_dresden", "nl_amsterdam", "be_brussels", "ch_zurich", "ch_geneva",
  "at_vienna", "at_salzburg", "cz_prague", "pl_warsaw", "pl_krakow", "hu_budapest",
  "hr_zagreb", "rs_belgrade", "si_ljubljana", "lv_riga", "lt_vilnius", "sk_bratislava",
  "lu_luxembourg", "li_vaduz", "md_chisinau", "by_minsk", "us_chicago", "us_washington_dc",
  "us_philadelphia", "us_austin", "us_denver", "us_atlanta", "us_dallas", "us_houston",
  "us_minneapolis", "us_nashville", "ca_toronto", "ca_montreal", "ca_quebec_city", "ca_calgary",
  "ca_ottawa", "mx_mexico_city", "mx_guadalajara", "mx_puebla", "cr_san_jose", "gt_guatemala_city",
  "sv_san_salvador", "hn_tegucigalpa", "ni_managua", "co_bogota", "co_medellin", "pe_cusco",
  "cl_santiago", "ar_cordoba", "ar_mendoza", "br_sao_paulo", "br_brasilia", "br_curitiba",
  "ec_quito", "bo_la_paz", "py_asuncion", "ve_caracas", "ug_kampala", "rw_kigali", "zm_lusaka",
  "zw_harare", "sd_khartoum", "nz_christchurch"
]);

const tramCityIds = new Set([
  "cn_hongkong", "jp_sapporo", "tr_istanbul", "tr_izmir", "fr_lyon", "fr_marseille", "fr_nice",
  "fr_toulouse", "fr_bordeaux", "uk_manchester", "ie_dublin", "es_barcelona", "es_valencia",
  "pt_lisbon", "pt_porto", "it_milan", "it_florence", "de_berlin", "de_munich", "de_cologne",
  "de_frankfurt", "de_dresden", "nl_amsterdam", "nl_rotterdam", "be_brussels", "be_antwerp",
  "ch_zurich", "ch_geneva", "at_vienna", "cz_prague", "pl_warsaw", "pl_krakow", "hu_budapest",
  "hr_zagreb", "gr_athens", "se_stockholm", "no_oslo", "fi_helsinki", "ru_moscow",
  "ru_saint_petersburg", "ua_kyiv", "ro_bucharest", "bg_sofia", "rs_belgrade", "lv_riga",
  "au_melbourne", "au_adelaide", "ca_toronto", "us_portland", "us_san_francisco"
]);

const hillOrSteepCityIds = new Set([
  "cn_chongqing", "cn_hongkong", "cn_macau", "cn_qingdao", "cn_xiamen", "cn_fuzhou", "cn_dalian",
  "cn_lhasa", "cn_guilin", "cn_dali", "cn_lijiang", "tw_taipei", "jp_kobe", "kr_seoul",
  "kr_busan", "th_chiang_mai", "np_kathmandu", "tr_istanbul", "tr_izmir", "ge_tbilisi",
  "am_yerevan", "fr_lyon", "fr_marseille", "fr_nice", "uk_edinburgh", "pt_lisbon", "pt_porto",
  "it_rome", "it_naples", "gr_athens", "hr_dubrovnik", "us_san_francisco", "us_seattle",
  "ca_vancouver", "mx_oaxaca", "co_medellin", "ec_quito", "bo_la_paz", "za_cape_town",
  "rw_kigali", "mg_antananarivo", "nz_wellington"
]);

const metroCityIds = new Set([
  "cn_beijing", "cn_shanghai", "cn_guangzhou", "cn_shenzhen", "cn_chengdu", "cn_hangzhou",
  "cn_suzhou", "cn_nanjing", "cn_wuhan", "cn_xian", "cn_chongqing", "cn_tianjin", "cn_qingdao",
  "cn_xiamen", "cn_changsha", "cn_kunming", "cn_fuzhou", "cn_ningbo", "cn_hefei", "cn_jinan",
  "cn_zhengzhou", "cn_luoyang", "cn_haerbin", "cn_changchun", "cn_shenyang", "cn_dalian",
  "cn_huhehaote", "cn_lanzhou", "cn_urumqi", "cn_nanning", "cn_guiyang", "cn_taiyuan",
  "cn_nanchang", "cn_shijiazhuang", "cn_hongkong", "tw_taipei", "tw_kaohsiung", "jp_tokyo",
  "jp_kyoto", "jp_osaka", "jp_sapporo", "jp_fukuoka", "jp_nagoya", "jp_kobe", "jp_yokohama",
  "kr_seoul", "kr_busan", "kr_incheon", "sg_singapore", "my_kuala_lumpur", "th_bangkok",
  "vn_hanoi", "vn_ho_chi_minh", "id_jakarta", "ph_manila", "in_delhi", "in_mumbai",
  "in_kolkata", "in_bengaluru", "in_chennai", "ir_tehran", "tr_istanbul", "ae_dubai", "qa_doha",
  "fr_paris", "fr_lyon", "fr_marseille", "fr_toulouse", "uk_london", "uk_manchester",
  "es_madrid", "es_barcelona", "it_rome", "it_milan", "de_berlin", "de_munich", "de_hamburg",
  "nl_amsterdam", "be_brussels", "ch_zurich", "at_vienna", "cz_prague", "pl_warsaw",
  "hu_budapest", "gr_athens", "dk_copenhagen", "se_stockholm", "no_oslo", "fi_helsinki",
  "ru_moscow", "ru_saint_petersburg", "ua_kyiv", "ro_bucharest", "bg_sofia", "us_new_york",
  "us_los_angeles", "us_san_francisco", "us_chicago", "us_boston", "us_washington_dc",
  "us_philadelphia", "us_miami", "us_atlanta", "ca_toronto", "ca_vancouver", "ca_montreal",
  "mx_mexico_city", "cl_santiago", "ar_buenos_aires", "br_sao_paulo", "br_rio", "eg_cairo"
]);

function buildGeographyCapabilities(city) {
  const isCoastal = coastalCityIds.has(city.cityId);
  const supportsSeaside = seasideCityIds.has(city.cityId);
  const supportsPierOrFerry = pierOrFerryCityIds.has(city.cityId);
  const supportsTram = tramCityIds.has(city.cityId);
  const supportsHillOrSteepStairs = hillOrSteepCityIds.has(city.cityId);
  const supportsMetro = metroCityIds.has(city.cityId);
  const hasMajorRiverOrLake = majorRiverOrLakeCityIds.has(city.cityId);
  return {
    cityId: city.cityId,
    cityNameZh: city.cityNameZh,
    cityNameLocal: city.cityNameLocal,
    countryOrRegion: city.countryOrRegion,
    isCoastal,
    hasMajorRiverOrLake,
    supportsPierOrFerry,
    supportsSeaside,
    supportsHillOrSteepStairs,
    supportsTram,
    supportsMetro,
    confidence: "coarse_geography_rule",
    notes: [
      "本表用于筛掉地理常识级错误，不代表具体地点已人工终审。",
      "不确定能力默认 false；宁可降级成普通生活空间，也不保留明显错误的海边、港边、轮渡、电车或山坡描述。"
    ]
  };
}

const geographyCapabilities = cities.map(buildGeographyCapabilities);
const geographyByCityId = new Map(geographyCapabilities.map((capability) => [capability.cityId, capability]));

function capabilityFor(city) {
  return geographyByCityId.get(city.cityId) || buildGeographyCapabilities(city);
}

function prototypeAllowedForCity(city, prototype) {
  const capability = capabilityFor(city);
  if (prototype.type === "seaside_walk") return capability.supportsSeaside;
  if (prototype.type === "pier") return capability.supportsPierOrFerry;
  if (prototype.type === "waterfront") return capability.hasMajorRiverOrLake;
  if (prototype.type === "tram_stop") return capability.supportsTram;
  if (prototype.type === "metro_transfer") return capability.supportsMetro;
  if (prototype.type === "stair_path") return capability.supportsHillOrSteepStairs;
  return true;
}

const stableAnchorOverrides = {
  cn_beijing: [
    ["北京西站北广场", "verified", "transport_hub", "https://s.visitbeijing.com.cn/attraction/101352"],
    ["西直门外大街动物园一带", "needs_human_final_review", "street_corner", "https://www.12306.cn/mormhweb/czyd_2143/bj/201001/t20100119_1582.html"]
  ],
  cn_shanghai: [
    ["人民广场地铁站换乘区", "needs_human_final_review", "metro_transfer", "https://www.metroman.cn/en/cities/shanghai/stations"],
    ["武康路附近街角", "needs_human_final_review", "street_corner", "https://www.openstreetmap.org/search?query=Wukang%20Road%20Shanghai"]
  ],
  cn_guangzhou: [
    ["广州东站站前区域", "needs_human_final_review", "transport_hub", "https://www.metroman.cn/en/cities/guangzhou/stations"],
    ["北京路步行街支路口", "needs_human_final_review", "shopping_street", "https://www.metroman.cn/en/cities/guangzhou/stations"]
  ],
  jp_tokyo: [
    ["吉祥寺站北口商店街", "needs_human_final_review", "shopping_street", "https://www.openstreetmap.org/search?query=Kichijoji%20Station%20Tokyo"],
    ["上野站公园口外侧", "needs_human_final_review", "station_edge", "https://www.openstreetmap.org/search?query=Ueno%20Station%20Tokyo"]
  ],
  fr_paris: [
    ["巴黎北站站前区域", "needs_human_final_review", "transport_hub", "https://www.openstreetmap.org/search?query=Gare%20du%20Nord%20Paris"],
    ["圣马丁运河岸边", "needs_human_final_review", "waterfront", "https://www.openstreetmap.org/search?query=Canal%20Saint-Martin%20Paris"]
  ],
  uk_london: [
    ["国王十字站外侧人行道", "needs_human_final_review", "transport_hub", "https://www.openstreetmap.org/search?query=King%27s%20Cross%20Station%20London"],
    ["南岸步道长椅边", "needs_human_final_review", "waterfront", "https://www.openstreetmap.org/search?query=South%20Bank%20London"]
  ],
  us_new_york: [
    ["宾夕法尼亚车站周边街口", "needs_human_final_review", "transport_hub", "https://www.openstreetmap.org/search?query=Penn%20Station%20New%20York"],
    ["布莱恩特公园边缘长椅", "needs_human_final_review", "quiet_place", "https://www.openstreetmap.org/search?query=Bryant%20Park%20New%20York"]
  ]
};

const scenePrototypes = [
  {
    key: "rail_station_plaza",
    type: "transport_hub",
    anchorKind: "city_life_area",
    templates: ["铁路站前雨棚旁", "车站外侧票据角", "站前广场行李坡道", "出站口短暂停留处", "候车楼外人行道"],
    details: ["站前风", "拖箱轮声", "电子屏反光", "临停车辆提示音", "雨棚滴水", "人群停顿"],
    objects: ["车票", "纸杯", "站内地图", "行李挂牌", "掉落纽扣", "折皱收据"],
    events: ["临时改道", "差点走错出口", "车票被风吹到脚边", "等人时多买了一杯水"],
    actions: ["把票角压平", "捡起纽扣", "让开行李坡道", "在地图边画一道线", "把纸杯移到墙边"]
  },
  {
    key: "metro_transfer_corner",
    type: "metro_transfer",
    anchorKind: "city_life_area",
    templates: ["换乘通道指示牌下", "地铁口台阶边", "地下通道转角", "闸机外侧小空地", "出口编号牌旁"],
    details: ["刷卡声", "地下通道风", "出口编号", "脚步回声", "广告灯箱", "扶梯提示音"],
    objects: ["交通卡", "路线图", "小票", "伞套", "耳机盒", "号码贴纸"],
    events: ["看错出口", "帮人指路", "伞套漏水", "路线图折反了"],
    actions: ["停下看编号", "把路线图折回去", "擦掉伞套水痕", "把小票塞回口袋", "让出扶梯口"]
  },
  {
    key: "bus_loop_stop",
    type: "bus_stop",
    anchorKind: "city_life_area",
    templates: ["公交总站候车栏", "巴士站牌影子下", "末班车站牌旁", "临时改线公告前", "站台长椅边"],
    details: ["站牌塑料壳", "车门气声", "排队线", "座椅冷边", "零钱碰撞声", "路边树影"],
    objects: ["站牌", "零钱", "纸袋", "排队栏绳", "公交票", "折叠扇"],
    events: ["等错方向", "末班车晚到", "有人找不到零钱", "站牌被贴了改线纸"],
    actions: ["把零钱推回掌心", "看两遍方向", "扶住被风吹起的公告", "把纸袋放到脚边", "往队尾退一步"]
  },
  {
    key: "neighborhood_market",
    type: "market",
    anchorKind: "city_life_area",
    templates: ["社区市场早摊边", "菜场入口塑料帘旁", "市场称台前", "摊位号码牌下", "湿地面通道口"],
    details: ["塑料帘响", "称台滴声", "湿地面", "纸袋摩擦声", "摊主喊价", "菜叶水珠"],
    objects: ["纸袋", "零钱", "号码牌", "菜叶", "手套", "热食盒"],
    events: ["错拿袋子", "找零钱", "帮忙扶住摊布", "买多了一小份"],
    actions: ["把袋子放回摊位", "递还零钱", "压住摊布角", "让出称台前的位置", "把热食盒扶正"]
  },
  {
    key: "small_food_counter",
    type: "food_counter",
    anchorKind: "city_life_area",
    templates: ["街边食物小摊队尾", "早餐铺蒸汽边", "面包店玻璃柜前", "小吃摊收银台旁", "外带窗口台阶边"],
    details: ["蒸汽", "油纸袋声", "菜单灯", "找零声", "热气贴着玻璃", "排队短句"],
    objects: ["菜单", "油纸袋", "杯套", "收据", "餐巾纸", "号码夹"],
    events: ["点错菜单", "杯名写错", "食物滚到袋角", "多买一份"],
    actions: ["转动杯套", "把餐巾纸压住", "换回袋子", "把号码夹递回去", "把多的一份放到旁边"]
  },
  {
    key: "night_convenience_store",
    type: "small_shop",
    anchorKind: "city_life_area",
    templates: ["夜间便利店门口", "便利店伞架旁", "小超市收银台外", "冷柜灯下", "自动门垫子边"],
    details: ["冷柜嗡声", "自动门提示音", "塑料袋细响", "伞架水痕", "收银扫码声", "夜灯白光"],
    objects: ["塑料袋", "收据", "雨伞", "杯面叉", "找零盒", "冰柜贴纸"],
    events: ["雨伞拿错", "找不到零钱", "收据被夹住", "杯面叉掉到袋底"],
    actions: ["把伞放回原位", "重新排到队尾", "从袋底摸出小叉", "把收据压平", "把门垫踢正一点"]
  },
  {
    key: "public_park_bench",
    type: "quiet_place",
    anchorKind: "city_life_area",
    templates: ["公园长椅编号旁", "城市绿地树荫下", "小广场花坛边", "儿童游具外侧长椅", "步道转弯处"],
    details: ["树叶影子", "长椅编号", "远处球声", "落叶擦地", "鸟叫被车声盖住", "石子路"],
    objects: ["报纸", "落叶", "长椅编号牌", "围巾", "小石子", "空水瓶"],
    events: ["风吹走纸页", "有人落下围巾", "看到一串脚印", "地图被吹开"],
    actions: ["压住纸页", "把围巾放到椅背", "绕开脚印", "记下编号", "把空水瓶立起来"]
  },
  {
    key: "riverside_walk",
    type: "waterfront",
    anchorKind: "city_life_area",
    templates: ["河岸步道栏杆边", "水边台阶低处", "桥下避雨阴影里", "湖边慢跑道旁", "水边远端栏杆"],
    details: ["水面反光", "栏杆凉意", "桥下回声", "潮湿台阶", "慢跑鞋声", "风贴着水面"],
    objects: ["票角", "红围巾", "湿纸巾", "饮料瓶盖", "明信片角", "旧皮筋"],
    events: ["票角被风吹起", "台阶有水", "有人把瓶盖落下", "围巾差点滑进栏杆缝"],
    actions: ["按住票角", "把围巾系紧一点", "绕开湿台阶", "捡起瓶盖", "把明信片塞回包里"]
  },
  {
    key: "old_street_doorplate",
    type: "street_corner",
    anchorKind: "city_life_area",
    templates: ["旧街门牌下", "巷口墙角纸箱边", "老楼门灯旁", "旧门铃下面", "窄街转角处"],
    details: ["门牌掉漆", "墙角水痕", "楼道灯", "旧门铃声", "窄街脚步", "窗帘缝里的光"],
    objects: ["门牌", "信封", "小灯泡", "纸箱", "旧钥匙", "胶带角"],
    events: ["门牌看不清", "信封没写完整地址", "纸箱被雨打湿", "门灯亮着没人出来"],
    actions: ["描下号码", "把信封放回包里", "把纸箱推到墙边", "没有敲门", "把胶带角按平"]
  },
  {
    key: "library_bookshop_edge",
    type: "bookish_place",
    anchorKind: "city_life_area",
    templates: ["旧书店门口书箱旁", "图书馆还书口外", "独立书店台阶边", "二手书摊纸箱前", "阅览室窗外长凳"],
    details: ["纸页味", "书脊磨痕", "还书口轻响", "木门铃", "铅笔擦声", "窗边灰尘"],
    objects: ["书签", "借阅条", "铅笔", "旧书腰封", "纸箱标签", "便签纸"],
    events: ["书签掉出来", "借阅条夹错书", "铅笔滚到椅脚", "旧书箱被风吹开"],
    actions: ["把书签夹回去", "捡起铅笔", "压住纸箱盖", "看一眼借阅条又合上", "把便签贴正"]
  },
  {
    key: "university_gate",
    type: "campus_edge",
    anchorKind: "city_life_area",
    templates: ["大学门口公告栏旁", "校园外自行车架边", "校门外树荫下", "讲座海报前", "学生食堂外台阶"],
    details: ["自行车铃", "海报胶痕", "树影", "外卖袋声", "课间脚步", "保安亭灯光"],
    objects: ["海报角", "自行车牌", "外卖袋", "笔帽", "讲座传单", "雨伞扣"],
    events: ["海报卷起来", "外卖袋被拿错", "笔帽滚远", "讲座时间看错"],
    actions: ["按平海报角", "把外卖袋放回架子", "捡回笔帽", "多看一遍时间", "把伞扣扣好"]
  },
  {
    key: "museum_side_entrance",
    type: "museum_edge",
    anchorKind: "landmark_edge",
    templates: ["博物馆侧门外", "展馆寄存柜旁", "美术馆台阶低处", "纪念馆外排队绳边", "展厅出口明信片架前"],
    details: ["寄存柜金属声", "台阶影子", "排队绳", "展厅冷气", "玻璃门倒影", "票根纸面"],
    objects: ["票根", "寄存牌", "铅笔", "明信片架", "导览折页", "号码牌"],
    events: ["票根皱了", "寄存牌差点丢", "导览折页折反", "排队绳被碰歪"],
    actions: ["压平票根", "把寄存牌塞好", "扶正排队绳", "把折页折回去", "没有买那张最显眼的卡"]
  },
  {
    key: "post_office_notice",
    type: "quiet_return",
    anchorKind: "city_life_area",
    templates: ["邮局门口投递箱旁", "社区公告栏下", "街边邮筒影子里", "明信片货架前", "邮政柜台外侧"],
    details: ["邮筒漆面", "公告纸边", "胶带反光", "柜台铃", "信封摩擦声", "邮票小格"],
    objects: ["明信片", "邮票", "胶带角", "信封", "铅笔", "投递口盖子"],
    events: ["没投出去", "邮票贴歪", "地址写到一半", "公告纸边翘起"],
    actions: ["把邮票按平", "合上投递口盖子", "把地址擦掉一小段", "按住公告纸角", "先把明信片带回去"]
  },
  {
    key: "laundry_lodging",
    type: "lodging",
    anchorKind: "city_life_area",
    templates: ["旅馆洗衣房门口", "自助洗衣店折衣台", "青旅公共厨房边", "楼道晾衣绳下", "电梯口行李角"],
    details: ["烘干机低响", "洗衣粉味", "折衣台灯光", "楼道回声", "杯盘轻碰", "电梯提示音"],
    objects: ["洗衣袋", "衣夹", "房卡", "纸杯", "小勺", "备用扣子"],
    events: ["衣夹少一个", "房卡找不到", "纸杯被写错名字", "备用扣子掉出来"],
    actions: ["把衣夹夹回去", "翻找房卡", "把纸杯转到背面", "捡起备用扣子", "把小勺放回杯边"]
  },
  {
    key: "flower_bucket_corner",
    type: "small_shop",
    anchorKind: "city_life_area",
    templates: ["花店外水桶旁", "街角花摊阴影下", "花束包装台边", "盆栽架下面", "花店门口湿砖上"],
    details: ["水桶水声", "湿砖", "包装纸响", "花枝剪声", "叶子气味", "小灯串"],
    objects: ["花枝标签", "包装纸", "小水桶", "丝带", "掉落叶片", "价签"],
    events: ["价签被水打湿", "丝带散开", "叶片粘在鞋边", "包装纸被风吹起"],
    actions: ["按住包装纸", "把丝带绕回去", "捡起叶片", "把价签移到干处", "没有碰那束最漂亮的花"]
  },
  {
    key: "cinema_sidewalk",
    type: "evening_place",
    anchorKind: "city_life_area",
    templates: ["小电影院门口", "影院散场人行道", "旧海报橱窗前", "售票窗口旁", "深夜放映厅外"],
    details: ["海报灯箱", "爆米花纸桶", "散场脚步", "票根纸边", "玻璃橱窗", "夜里车灯"],
    objects: ["票根", "纸桶", "海报角", "座位号纸", "饮料杯盖", "小票"],
    events: ["票根撕歪", "散场时走错方向", "纸桶滚到墙边", "座位号看反了"],
    actions: ["把票根夹进书里", "扶住纸桶", "多看一遍座位号", "让开门口", "把杯盖扣紧"]
  },
  {
    key: "hospital_bench",
    type: "care_edge",
    anchorKind: "city_life_area",
    templates: ["医院外长椅边", "药房门口排队线", "诊所楼下台阶", "急诊外自动门旁", "药袋窗口外"],
    details: ["药袋纸声", "自动门风", "长椅冷面", "排队线", "叫号屏光", "消毒水味很淡"],
    objects: ["药袋", "号码纸", "水杯", "围巾", "口罩袋", "笔"],
    events: ["号码纸折皱", "药袋差点拿错", "水杯盖没拧紧", "笔掉到长椅下"],
    actions: ["把号码纸压平", "确认药袋名字", "拧紧水杯盖", "把笔捡出来", "把围巾放到干净处"]
  },
  {
    key: "ferry_pier_edge",
    type: "pier",
    anchorKind: "city_life_area",
    templates: ["轮渡口栏杆边", "码头候船棚下", "渡船检票口外", "水上巴士站台", "港边排队线旁"],
    details: ["船绳轻响", "检票口灯", "潮湿木板", "水面油光", "海风", "候船广播"],
    objects: ["船票", "绳结", "纸杯", "防风夹", "小地图", "瓶盖"],
    events: ["船票被吹折", "广播听漏一半", "纸杯滚到栏杆边", "防风夹松开"],
    actions: ["把船票按进包里", "扶住防风夹", "捡回瓶盖", "往队伍里退一步", "看一眼水面再转身"]
  },
  {
    key: "pharmacy_window",
    type: "pharmacy_edge",
    anchorKind: "city_life_area",
    templates: ["药房取药窗口外", "药店玻璃门边", "药袋柜台旁", "夜间药房小灯下", "处方窗口排队线"],
    details: ["药袋纸声", "玻璃门反光", "叫号屏", "柜台小铃", "货架灯", "门口脚垫"],
    objects: ["药袋", "号码纸", "水杯盖", "小票", "笔帽", "口罩袋"],
    events: ["药袋差点拿错", "号码纸折皱", "小票夹在袋口", "笔帽滚到门边"],
    actions: ["确认药袋名字", "把号码纸压平", "把小票塞回袋里", "捡起笔帽", "让开窗口"]
  },
  {
    key: "community_center_notice",
    type: "community_center",
    anchorKind: "city_life_area",
    templates: ["社区中心公告板前", "活动室门口折椅边", "居民服务台外", "社区课程海报下", "楼下通知栏旁"],
    details: ["公告纸边", "胶带反光", "折椅脚声", "门口风扇", "印章垫味", "旧海报钉孔"],
    objects: ["报名表", "胶带角", "折椅", "宣传单", "铅笔", "印章纸"],
    events: ["报名表卷起", "胶带角翘着", "折椅被碰歪", "宣传单掉到地上"],
    actions: ["按住报名表", "贴平胶带角", "扶正折椅", "捡起宣传单", "把铅笔放回盒里"]
  },
  {
    key: "newspaper_kiosk",
    type: "kiosk",
    anchorKind: "city_life_area",
    templates: ["报刊亭小窗前", "街角售卖亭雨棚下", "彩票报纸架旁", "杂志架塑料帘边", "清晨报纸捆旁"],
    details: ["报纸油墨味", "塑料帘响", "硬币落声", "雨棚阴影", "杂志封面反光", "橡皮筋绷声"],
    objects: ["报纸", "硬币", "橡皮筋", "找零盘", "杂志角", "小票"],
    events: ["报纸角被风翻起", "硬币滚远", "橡皮筋松开", "小票贴在玻璃上"],
    actions: ["压住报纸角", "捡回硬币", "把橡皮筋绕回去", "把小票揭下来", "把杂志角放平"]
  },
  {
    key: "bike_repair_stand",
    type: "repair_stand",
    anchorKind: "city_life_area",
    templates: ["自行车修理摊旁", "打气筒影子下", "车铃零件盒边", "街边补胎小凳旁", "自行车架尽头"],
    details: ["打气筒声", "金属零件碰声", "轮胎橡胶味", "小凳影子", "链条油光", "车铃短响"],
    objects: ["车铃", "气门帽", "小扳手", "补胎片", "零件盒", "旧抹布"],
    events: ["气门帽掉了", "车铃响了一下", "补胎片粘在纸上", "小扳手滑到盒边"],
    actions: ["捡起气门帽", "把车铃扶正", "按住补胎片", "把扳手放回盒里", "把抹布叠一下"]
  },
  {
    key: "shoe_key_repair",
    type: "repair_stand",
    anchorKind: "city_life_area",
    templates: ["修鞋配钥匙小摊前", "钥匙坯挂板下", "补鞋凳旁", "街边小修补柜台", "钥匙圈纸牌边"],
    details: ["钥匙碰声", "胶水味很淡", "小锤敲声", "皮革边角", "挂板反光", "脚垫灰尘"],
    objects: ["钥匙坯", "鞋带", "小票", "胶水盖", "号码牌", "旧鞋垫"],
    events: ["鞋带散开", "胶水盖滚远", "号码牌放反", "钥匙坯掉到桌边"],
    actions: ["把鞋带绕好", "捡回胶水盖", "翻正号码牌", "把钥匙坯推回桌上", "没有催老板"]
  },
  {
    key: "tea_coffee_counter",
    type: "drink_counter",
    anchorKind: "city_life_area",
    templates: ["茶饮小店取餐口", "咖啡吧台边角", "热饮窗口排队线", "外带杯架旁", "饮料店吸管盒前"],
    details: ["杯盖扣声", "制冰机响", "吸管纸套", "热饮雾气", "吧台水痕", "叫号声"],
    objects: ["杯套", "吸管纸", "号码贴", "杯盖", "小票", "搅拌棒"],
    events: ["杯盖没扣紧", "号码贴粘歪", "吸管纸被吹起", "小票湿了一角"],
    actions: ["扣紧杯盖", "按平号码贴", "压住吸管纸", "把小票擦干一点", "把搅拌棒放回盒里"]
  },
  {
    key: "bakery_side_door",
    type: "bakery_edge",
    anchorKind: "city_life_area",
    templates: ["面包店侧门纸袋边", "烘焙房玻璃窗外", "甜品柜台队尾", "面包篮标签下", "清晨出炉架旁"],
    details: ["烤面包味", "纸袋摩擦", "玻璃雾气", "标签小夹", "托盘声", "黄灯"],
    objects: ["面包袋", "标签夹", "托盘", "小票", "纸巾", "丝带"],
    events: ["标签夹歪了", "面包袋开口", "托盘轻轻滑动", "丝带松开"],
    actions: ["扶正标签夹", "折好袋口", "按住托盘", "把丝带绕回去", "把纸巾压在袋下"]
  },
  {
    key: "hair_salon_door",
    type: "small_shop",
    anchorKind: "city_life_area",
    templates: ["理发店门口旋转灯下", "发廊玻璃门旁", "洗发椅外的等候凳", "价目牌小黑板前", "剪发围布篮边"],
    details: ["吹风机声", "玻璃门倒影", "小黑板粉笔字", "围布布料声", "旋转灯", "洗发水味"],
    objects: ["价目牌", "小发夹", "号码纸", "围布", "雨伞", "纸杯"],
    events: ["小发夹掉在门口", "价目牌被风吹歪", "号码纸夹在椅缝", "雨伞滴水"],
    actions: ["捡起小发夹", "扶正价目牌", "抽出号码纸", "把伞移到门边", "把纸杯拿远一点"]
  },
  {
    key: "playground_fence",
    type: "playground_edge",
    anchorKind: "city_life_area",
    templates: ["儿童游具围栏外", "滑梯影子边", "小广场秋千旁", "沙坑水桶边", "跷跷板外侧长椅"],
    details: ["秋千链声", "沙子摩擦", "塑料桶", "远处笑声", "橡胶地面", "长椅影子"],
    objects: ["小水桶", "塑料铲", "纸巾", "落叶", "鞋扣", "空水瓶"],
    events: ["塑料铲被遗忘", "鞋扣开了", "纸巾被风吹到围栏", "小水桶倒着"],
    actions: ["把塑料铲放进桶里", "扣好鞋扣", "捡起纸巾", "扶正小水桶", "绕开沙坑边"]
  },
  {
    key: "school_crosswalk",
    type: "school_edge",
    anchorKind: "city_life_area",
    templates: ["学校外斑马线边", "放学路口护栏旁", "校门口文具摊前", "书包队伍外侧", "人行灯按钮下"],
    details: ["人行灯滴声", "书包拉链声", "护栏反光", "文具摊塑料盒", "放学脚步", "路口风"],
    objects: ["铅笔", "橡皮", "书包扣", "传单", "按钮贴纸", "零钱"],
    events: ["铅笔滚到护栏边", "书包扣松开", "传单被踩住一角", "零钱掉在按钮下"],
    actions: ["捡回铅笔", "扣好书包扣", "把传单拾起来", "捡起零钱", "等绿灯再走"]
  },
  {
    key: "grocery_loading",
    type: "small_shop",
    anchorKind: "city_life_area",
    templates: ["小超市卸货纸箱旁", "杂货店卷帘门前", "货架补货车边", "门口饮料箱旁", "清晨进货单下"],
    details: ["纸箱摩擦", "卷帘门声", "扫码枪响", "饮料箱塑料面", "货车倒车声", "清晨冷风"],
    objects: ["纸箱", "进货单", "胶带", "瓶盖", "塑料筐", "记号笔"],
    events: ["纸箱边翘起", "进货单被风吹开", "胶带粘到袖口", "记号笔滚远"],
    actions: ["按住纸箱边", "压住进货单", "把胶带绕回去", "捡起记号笔", "把塑料筐推正"]
  },
  {
    key: "apartment_noticeboard",
    type: "residential_edge",
    anchorKind: "city_life_area",
    templates: ["居民楼公告栏前", "楼道信箱旁", "电梯口通知纸下", "门禁旁小台面", "楼下快递架边"],
    details: ["信箱金属声", "电梯提示音", "通知纸胶带", "快递袋声", "楼道灯", "门禁滴声"],
    objects: ["通知纸", "快递单", "钥匙扣", "胶带角", "旧信封", "便签"],
    events: ["通知纸翘起", "快递单看不清", "钥匙扣掉到台面", "旧信封夹在缝里"],
    actions: ["贴平通知纸", "把快递单翻正", "捡起钥匙扣", "把旧信封推回去", "按亮楼道灯"]
  },
  {
    key: "pedestrian_bridge",
    type: "bridge_crossing",
    anchorKind: "city_life_area",
    templates: ["人行天桥楼梯口", "过街桥栏杆边", "桥上广告牌下", "天桥转弯平台", "桥梯扶手旁"],
    details: ["扶手凉意", "广告牌影子", "脚步震动", "车流声", "桥面风", "楼梯灰尘"],
    objects: ["传单", "发圈", "瓶盖", "小票", "伞尖套", "鞋带"],
    events: ["传单贴在栏杆", "发圈被风吹到角落", "鞋带散开", "小票卡在台阶缝"],
    actions: ["揭下传单", "捡起发圈", "系好鞋带", "把小票取出来", "扶一下栏杆"]
  },
  {
    key: "hill_stair_path",
    type: "stair_path",
    anchorKind: "city_life_area",
    templates: ["坡道石阶转角", "山城楼梯平台", "上坡小路扶手旁", "台阶尽头树荫下", "陡坡墙根边"],
    details: ["石阶磨痕", "扶手热度", "坡道风", "墙根青苔", "鞋底摩擦", "树影短停"],
    objects: ["鞋带", "水瓶", "纸巾", "小石子", "地图角", "伞扣"],
    events: ["鞋带散开", "水瓶滚到低一级", "地图角翘起", "小石子卡在鞋底"],
    actions: ["系紧鞋带", "捡回水瓶", "按住地图角", "磕掉小石子", "在平台停一停"]
  },
  {
    key: "beach_promenade",
    type: "seaside_walk",
    anchorKind: "city_life_area",
    templates: ["海边步道护栏旁", "沙滩入口冲脚处", "海风长椅边", "防晒棚影子下", "木栈道尽头"],
    details: ["海风", "沙粒", "冲脚水声", "防晒棚布面", "木板轻响", "远处浪声"],
    objects: ["拖鞋", "瓶盖", "湿纸巾", "防晒夹", "小贝壳", "水票"],
    events: ["拖鞋进了沙", "瓶盖滚到木板缝", "防晒夹松开", "湿纸巾贴在包边"],
    actions: ["抖掉沙子", "捡回瓶盖", "夹紧防晒夹", "把湿纸巾收好", "没有把贝壳带走"]
  },
  {
    key: "public_pool_fountain",
    type: "water_corner",
    anchorKind: "city_life_area",
    templates: ["公共喷泉外圈", "广场水池石沿", "饮水台旁", "小水渠桥边", "喷水雾气边缘"],
    details: ["水声", "石沿湿痕", "硬币亮点", "水雾", "孩子脚步", "广场回声"],
    objects: ["硬币", "纸巾", "水杯", "地图角", "小石子", "瓶盖"],
    events: ["纸巾沾湿", "水杯盖松了", "硬币滚到石沿", "地图角碰到水"],
    actions: ["捡起硬币", "拧紧杯盖", "把地图拿远", "擦干石沿一小块", "把瓶盖放进口袋"]
  },
  {
    key: "botanical_greenhouse",
    type: "garden_edge",
    anchorKind: "city_life_area",
    templates: ["植物园温室门外", "花圃标签牌旁", "公园苗圃栅栏边", "温室玻璃雾气前", "园艺工具柜旁"],
    details: ["玻璃雾气", "土味", "标签牌", "浇水声", "叶面反光", "工具轻碰"],
    objects: ["植物标签", "小铲", "水壶", "手套", "门票角", "叶片"],
    events: ["标签牌歪了", "小铲滑到柜边", "门票角湿了", "叶片粘在鞋边"],
    actions: ["扶正标签牌", "把小铲推回去", "擦干门票角", "捡起叶片", "把手套叠好"]
  },
  {
    key: "tram_stop_shelter",
    type: "tram_stop",
    anchorKind: "city_life_area",
    templates: ["有轨电车站亭下", "路面电车轨道边", "站亭玻璃挡风处", "电车时刻牌旁", "轨道转弯铃声边"],
    details: ["电车铃", "轨道亮线", "站亭玻璃", "时刻牌", "刷卡声", "路面震动"],
    objects: ["交通卡", "时刻表", "纸杯", "伞套", "小票", "耳机盒"],
    events: ["时刻表看漏一行", "纸杯滚到站亭边", "伞套积水", "交通卡找不到"],
    actions: ["多看一遍时刻表", "捡回纸杯", "倒掉伞套水", "翻找交通卡", "往站亭里退一点"]
  },
  {
    key: "taxi_rank_curb",
    type: "taxi_rank",
    anchorKind: "city_life_area",
    templates: ["出租车排队路缘", "网约车上车点牌下", "临停区白线边", "车道护栏外侧", "上客点雨棚旁"],
    details: ["车门开合", "路缘白线", "上车点编号", "雨棚灯", "轮胎水声", "导航提示音"],
    objects: ["上车点号码", "纸袋", "伞套", "行李贴", "小票", "水瓶"],
    events: ["上车点号码看错", "纸袋被放到地上", "行李贴翘起", "水瓶滚到路缘"],
    actions: ["确认号码", "把纸袋拎起", "按平行李贴", "捡回水瓶", "退到白线内"]
  },
  {
    key: "record_music_shop",
    type: "music_shop",
    anchorKind: "city_life_area",
    templates: ["唱片店门口旧海报下", "乐器店橱窗前", "二手唱片箱边", "小音像店试听台旁", "街角音乐店台阶"],
    details: ["旧海报边", "塑料唱片套", "橱窗反光", "门铃声", "试听耳机线", "木台阶"],
    objects: ["唱片套", "海报角", "耳机线", "价签", "纸袋", "小票"],
    events: ["海报角翘起", "耳机线打结", "价签掉进箱里", "唱片套滑出来"],
    actions: ["按平海报角", "解开耳机线", "捡起价签", "把唱片套推回去", "把纸袋折好"]
  },
  {
    key: "church_temple_edge",
    type: "quiet_landmark_edge",
    anchorKind: "landmark_edge",
    templates: ["寺庙或教堂外长椅", "安静院墙门口", "钟声听得到的街角", "礼拜堂侧门外", "香烛或花束摊旁"],
    details: ["远处钟声", "石墙阴影", "门口台阶", "花束纸", "安静脚步", "木门纹路"],
    objects: ["花束纸", "蜡烛小盒", "门票角", "纸袋", "小卡片", "落叶"],
    events: ["花束纸散开", "小卡片掉到台阶", "落叶贴在鞋边", "门票角皱了"],
    actions: ["按住花束纸", "捡起小卡片", "把落叶拿开", "压平门票角", "没有走进正门"]
  },
  {
    key: "sports_court_fence",
    type: "sports_edge",
    anchorKind: "city_life_area",
    templates: ["社区球场围网外", "篮球场长椅边", "网球场门扣旁", "晨练广场器械旁", "跑道入口白线前"],
    details: ["球落地声", "围网影子", "运动鞋摩擦", "长椅热面", "水瓶碰声", "白线反光"],
    objects: ["水瓶", "毛巾", "球票", "门扣", "发圈", "鞋带"],
    events: ["水瓶倒了", "毛巾滑下长椅", "门扣没扣好", "鞋带散开"],
    actions: ["扶起水瓶", "把毛巾叠回去", "扣好门扣", "系好鞋带", "把发圈放到长椅上"]
  },
  {
    key: "public_toilet_sink",
    type: "utility_corner",
    anchorKind: "city_life_area",
    templates: ["公共洗手台纸巾盒旁", "公园洗手池边", "商场洗手间外水池", "水龙头滴水处", "烘手机影子下"],
    details: ["水龙头滴声", "纸巾盒空响", "烘手机风", "瓷砖冷光", "洗手液味", "门轴声"],
    objects: ["纸巾", "水杯", "洗手液泵头", "伞套", "小票", "发夹"],
    events: ["纸巾只剩一张", "水杯盖掉了", "泵头按不下去", "小票湿了一角"],
    actions: ["把纸巾折好", "捡起杯盖", "轻按泵头", "擦干小票", "把发夹放到台边"]
  },
  {
    key: "embassy_consulate_street",
    type: "office_street",
    anchorKind: "city_life_area",
    templates: ["办公街区安检栏外", "领事馆街口树下", "办事窗口排队线", "写字楼外快递架边", "文件复印店门口"],
    details: ["文件袋声", "安检栏", "复印机热气", "快递架塑料袋", "树影", "窗口叫号"],
    objects: ["文件袋", "号码纸", "回形针", "复印单", "快递袋", "铅笔"],
    events: ["回形针掉了", "文件袋角折了", "号码纸看错", "复印单少一页"],
    actions: ["捡起回形针", "压平文件袋角", "多看一遍号码", "把复印单数一遍", "让开窗口"]
  }
];

const climates = {
  Asia: ["高密度街区", "早晚通勤", "小店门口", "湿热或温差日常"],
  Europe: ["老城街角", "公共交通节点", "广场边缘", "书店和小店"],
  "Europe/Asia": ["跨海或山坡街区", "渡口与电车", "市集边缘", "傍晚风"],
  "North America": ["街区公园", "公交或地铁入口", "社区店铺", "宽人行道"],
  "South America": ["广场边缘", "市场入口", "公交站前", "午后街声"],
  Africa: ["市场边缘", "巴士站前", "街边小店", "干热或海风日常"],
  Oceania: ["港口或海边步道", "社区小店", "公园草地", "傍晚风"]
};

const continentSceneBias = {
  Oceania: ["ferry_pier_edge", "riverside_walk", "flower_bucket_corner"],
  "Europe/Asia": ["ferry_pier_edge", "old_street_doorplate", "small_food_counter"],
  Europe: ["library_bookshop_edge", "old_street_doorplate", "museum_side_entrance"],
  Africa: ["neighborhood_market", "bus_loop_stop", "small_food_counter"],
  "South America": ["neighborhood_market", "public_park_bench", "bus_loop_stop"],
  "North America": ["public_park_bench", "night_convenience_store", "metro_transfer_corner"],
  Asia: ["metro_transfer_corner", "small_food_counter", "neighborhood_market"]
};

function hashText(text) {
  let h = 2166136261;
  for (const ch of text) {
    h ^= ch.charCodeAt(0);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

function pick(arr, seed, count) {
  return arr
    .map((item, index) => ({ item, rank: hashText(`${seed}:${index}:${item}`) }))
    .sort((a, b) => a.rank - b.rank)
    .slice(0, Math.min(count, arr.length))
    .map(({ item }) => item);
}

function slugPart(text) {
  return text.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_+|_+$/g, "").slice(0, 40);
}

function osmSearchUrl(query) {
  return `https://www.openstreetmap.org/search?query=${encodeURIComponent(query)}`;
}

function wikidataSearchUrl(query) {
  return `https://www.wikidata.org/w/index.php?search=${encodeURIComponent(query)}`;
}

function sceneSourceRefs(city, anchorText, status, explicitUrl) {
  const refs = [];
  if (explicitUrl) refs.push({ label: "人工种子来源", url: explicitUrl });
  refs.push({ label: "OpenStreetMap 查询入口", url: osmSearchUrl(`${anchorText} ${city.cityNameLocal}`) });
  refs.push({ label: "Wikidata 城市查询入口", url: wikidataSearchUrl(`${city.cityNameLocal} ${city.countryOrRegion}`) });
  if (status === "verified") {
    refs.push({ label: "北京市重点站区示例来源", url: "https://zdzqgw.beijing.gov.cn/zqfw/bjzdq/" });
  }
  return refs;
}

function buildAnchor(city, prototype, cityIndex, sceneIndex) {
  const capability = capabilityFor(city);
  const overrides = stableAnchorOverrides[city.cityId] || [];
  const matching = overrides.find((o) => o[2] === prototype.type || o[2] === prototype.anchorKind);
  if (matching && sceneIndex < 2) {
    return {
      text: matching[0],
      verificationStatus: matching[1],
      anchorKind: matching[2],
      sourceRefs: sceneSourceRefs(city, matching[0], matching[1], matching[3])
    };
  }

  const cityLabel = `${city.cityNameZh}（${city.cityNameLocal}）`;
  const placeByType = {
    transport_hub: `${cityLabel}的主要铁路、长途客运或综合交通站前公共区域`,
    metro_transfer: `${cityLabel}的轨道交通、地下通道或中心换乘口`,
    bus_stop: `${cityLabel}的公交总站、巴士站牌或临时改线公告处`,
    market: `${cityLabel}的社区市场、菜场或早市入口`,
    food_counter: `${cityLabel}的街边早餐铺、小吃摊或外带窗口`,
    small_shop: `${cityLabel}的便利店、小超市、花店或夜间小店门口`,
    quiet_place: `${cityLabel}的城市公园、广场绿地或树荫长椅`,
    waterfront: `${cityLabel}的河岸、湖边、水边栏杆或桥下步道`,
    street_corner: `${cityLabel}的旧街、居民区巷口或门牌墙角`,
    bookish_place: `${cityLabel}的图书馆、旧书店或二手书摊外侧`,
    campus_edge: `${cityLabel}的大学、学校或讲座公告栏周边`,
    museum_edge: `${cityLabel}的博物馆、美术馆或展馆侧门外生活角落`,
    quiet_return: `${cityLabel}的邮局、邮筒、公告栏或明信片货架附近`,
    lodging: `${cityLabel}的旅馆公共厨房、洗衣房或自助洗衣店`,
    evening_place: `${cityLabel}的小电影院、剧场或夜间散场街口`,
    care_edge: `${cityLabel}的医院、诊所或药房外侧等候处`,
    pier: capability.isCoastal
      ? `${cityLabel}的轮渡口、码头、港边或水上交通候乘处`
      : `${cityLabel}的轮渡口、水边码头或水上交通候乘处`,
    pharmacy_edge: `${cityLabel}的药房、药店或取药窗口外侧`,
    community_center: `${cityLabel}的社区中心、活动室或居民服务公告栏附近`,
    kiosk: `${cityLabel}的报刊亭、售卖亭或街角小窗口`,
    repair_stand: `${cityLabel}的自行车、修鞋、配钥匙或街边修补摊`,
    drink_counter: `${cityLabel}的茶饮、咖啡或热饮外带窗口`,
    bakery_edge: `${cityLabel}的面包店、甜品柜或烘焙小店门口`,
    playground_edge: `${cityLabel}的儿童游具、社区小广场或游乐围栏外侧`,
    school_edge: `${cityLabel}的学校外斑马线、文具摊或放学路口`,
    residential_edge: `${cityLabel}的居民楼公告栏、楼道信箱或快递架附近`,
    bridge_crossing: `${cityLabel}的人行天桥、过街桥或桥梯扶手边`,
    stair_path: `${cityLabel}的坡道、石阶、台阶平台或上坡小路`,
    seaside_walk: `${cityLabel}的海边步道、沙滩入口或木栈道`,
    water_corner: `${cityLabel}的公共喷泉、水池石沿、饮水台或小水渠边`,
    garden_edge: `${cityLabel}的植物园、花圃、苗圃或温室门外`,
    tram_stop: `${cityLabel}的有轨电车站亭、路面轨道或电车时刻牌旁`,
    taxi_rank: `${cityLabel}的出租车、网约车或临停上客点`,
    music_shop: `${cityLabel}的唱片店、乐器店或音像小店门口`,
    quiet_landmark_edge: `${cityLabel}的寺庙、教堂、院墙或安静侧门外`,
    sports_edge: `${cityLabel}的社区球场、跑道入口或晨练器械旁`,
    utility_corner: `${cityLabel}的公共洗手台、洗手池或烘手机附近`,
    office_street: `${cityLabel}的办事窗口、办公街区、复印店或文件服务小店`
  };
  const anchorText = placeByType[prototype.type] || `${cityLabel}的普通生活公共空间`;
  return {
    text: anchorText,
    verificationStatus: "needs_human_final_review",
    anchorKind: prototype.anchorKind,
    sourceRefs: sceneSourceRefs(city, anchorText, "needs_human_final_review")
  };
}

function selectPrototypes(city, cityIndex) {
  const biasKeys = continentSceneBias[city.continent] || continentSceneBias.Asia;
  const bias = biasKeys.map((key) => scenePrototypes.find((p) => p.key === key)).filter(Boolean);
  const start = hashText(city.cityId) % scenePrototypes.length;
  const rotated = Array.from({ length: scenePrototypes.length }, (_, i) => scenePrototypes[(start + i) % scenePrototypes.length]);
  const merged = [...bias, ...rotated].filter((prototype) => prototypeAllowedForCity(city, prototype));
  const unique = [];
  const seen = new Set();
  for (const p of merged) {
    if (!seen.has(p.key)) {
      unique.push(p);
      seen.add(p.key);
    }
    if (unique.length === 10) break;
  }
  if (!unique.some((p) => p.type === "landmark_edge" || p.type === "museum_edge")) {
    unique[9] = scenePrototypes.find((p) => p.key === "museum_side_entrance");
  }
  return unique;
}

function adaptPrototypeForCity(city, prototype) {
  const capability = capabilityFor(city);
  if (prototype.type !== "pier" || capability.isCoastal) return prototype;
  return {
    ...prototype,
    templates: prototype.templates.map((template) => template.replace("港边排队线旁", "水边排队线旁")),
    details: prototype.details.map((detail) => detail.replace("海风", "水面风"))
  };
}

function sceneName(city, prototype, cityIndex, sceneIndex) {
  const seed = hashText(`${city.cityId}:${prototype.key}:${sceneIndex}`);
  const template = prototype.templates[(seed + cityIndex + sceneIndex) % prototype.templates.length];
  const localHint = city.cityNameLocal.replace(/\s+/g, " ");
  const variants = [
    "短停处", "侧边", "小灯下", "避风边", "台阶低处", "排队线外", "门口右侧", "雨痕旁", "长椅尽头", "公告栏下",
    "影子里", "水痕边", "边角处", "转角外", "玻璃前", "树荫边", "出口外", "窄路口", "栏杆低处", "墙根前",
    "等候点", "脚垫边", "低檐下", "墙边", "扶手边", "货架侧", "小窗外", "门牌下", "灯箱边", "风口处"
  ];
  const variant = variants[(seed + cityIndex * 7 + sceneIndex * 11) % variants.length];
  return `${city.cityNameZh}${template}${variant}（${localHint}）`;
}

function buildScene(city, cityIndex, prototype, sceneIndex) {
  prototype = adaptPrototypeForCity(city, prototype);
  const seed = hashText(`${city.cityId}:${prototype.key}:${sceneIndex}`);
  const name = sceneName(city, prototype, cityIndex, sceneIndex);
  const anchor = buildAnchor(city, prototype, cityIndex, sceneIndex);
  const animalStart = seed % animals.length;
  const sceneId = `${city.cityId}_${slugPart(prototype.key)}_${String(sceneIndex + 1).padStart(2, "0")}`;
  const isFamousPlace = prototype.type === "museum_edge" || anchor.anchorKind === "landmark_edge";
  return {
    sceneId,
    sceneName: name,
    sceneType: prototype.type,
    isFamousPlace,
    realWorldAnchor: anchor.text,
    anchorKind: anchor.anchorKind,
    verificationStatus: anchor.verificationStatus,
    sourceRefs: anchor.sourceRefs,
    sensoryDetails: pick(prototype.details, seed, 5),
    localObjects: pick(prototype.objects, seed + 1, 6),
    possibleEvents: pick(prototype.events, seed + 2, 4),
    availableActions: pick(prototype.actions, seed + 3, 5),
    emotionTags: pick(["轻松日常", "等待", "温柔", "临时改道", "尴尬", "回访", "小心", "好奇", "松一口气"], seed + 4, 4),
    postcardTypes: pick(postcardTypes, seed + 5, 3),
    microArcFits: pick(microArcs, seed + 6, 3),
    animalAffinity: pick(animals, animalStart, 3),
    culturalNotes: [
      `写 ${city.cityNameZh}的普通生活动作，不把城市简化成观光标签。`,
      "具体事实进入产品正文前，需要人工终审 sourceRefs。"
    ],
    avoidWriting: [
      "不要把地点写成景点介绍。",
      "不要让风物只做背景，至少一个物件要参与动作。",
      "不要把待终审锚点当成已核验事实写进最终文案。"
    ]
  };
}

function buildCandidate(city, cityIndex) {
  const prototypes = selectPrototypes(city, cityIndex);
  const climateBits = climates[city.continent] || climates.Asia;
  const tagPool = prototypes.flatMap((p) => {
    const map = {
      transport_hub: ["站前广场", "票据", "拖箱轮声"],
      metro_transfer: ["换乘通道", "出口编号", "地下风"],
      bus_stop: ["站牌", "改线公告", "候车栏"],
      market: ["社区市场", "湿地面", "纸袋"],
      food_counter: ["外带窗口", "蒸汽", "菜单"],
      small_shop: ["夜间小店", "伞架", "收据"],
      quiet_place: ["城市绿地", "长椅编号", "树影"],
      waterfront: ["水边栏杆", "潮湿台阶", "桥下风"],
      street_corner: ["旧门牌", "巷口", "墙角纸箱"],
      bookish_place: ["旧书箱", "借阅条", "窗边灰尘"],
      campus_edge: ["公告栏", "自行车架", "讲座海报"],
      museum_edge: ["展馆侧门", "票根", "寄存牌"],
      quiet_return: ["邮筒", "公告纸边", "明信片"],
      lodging: ["洗衣房", "房卡", "衣夹"],
      evening_place: ["小电影院", "票根", "夜灯"],
      care_edge: ["药袋", "号码纸", "等候长椅"],
      pier: ["码头栏杆", "船票", "候船棚"],
      pharmacy_edge: ["药房窗口", "药袋", "号码纸"],
      community_center: ["社区公告", "折椅", "活动海报"],
      kiosk: ["报刊亭", "报纸", "硬币"],
      repair_stand: ["修补摊", "零件盒", "钥匙碰声"],
      drink_counter: ["取餐口", "杯盖", "号码贴"],
      bakery_edge: ["面包店", "纸袋", "标签夹"],
      playground_edge: ["游具围栏", "塑料小桶", "长椅"],
      school_edge: ["学校路口", "文具摊", "人行灯"],
      residential_edge: ["居民楼公告栏", "快递架", "信箱"],
      bridge_crossing: ["人行天桥", "栏杆", "楼梯口"],
      stair_path: ["坡道石阶", "扶手", "墙根"],
      seaside_walk: ["海边步道", "木栈道", "海风"],
      water_corner: ["水池石沿", "喷泉外圈", "饮水台"],
      garden_edge: ["花圃标签", "温室门外", "园艺工具"],
      tram_stop: ["电车站亭", "时刻牌", "轨道铃声"],
      taxi_rank: ["上车点", "路缘白线", "行李贴"],
      music_shop: ["唱片店", "旧海报", "试听台"],
      quiet_landmark_edge: ["安静院墙", "侧门台阶", "花束纸"],
      sports_edge: ["社区球场", "围网影子", "水瓶"],
      utility_corner: ["洗手台", "纸巾盒", "水龙头"],
      office_street: ["办事窗口", "文件袋", "复印店"]
    };
    return map[p.type] || ["生活角落", "可行动物件", "公共空间"];
  });
  return {
    ...city,
    climateOrGeography: `${city.cityNameZh}的 V2 写作重点是 ${pick(climateBits, cityIndex, 2).join("、")}，使用已维护或待终审的真实生活锚点，不临时编造城市事实。`,
    modernLifeTags: [`${city.cityNameZh}生活锚点`, ...pick(tagPool, cityIndex + hashText(city.cityId), 7)],
    emotionTags: pick(["轻松日常", "等待", "温柔", "临时改道", "尴尬", "回访", "小心", "好奇"], cityIndex, 5),
    culturalNotes: [
      `优先写 ${city.cityNameZh}的当代日常、公共空间和普通生活动作。`,
      "本轮 V2 已移除旧模板；具体地点 sourceRefs 仍需人工终审。"
    ],
    avoidStereotypes: [
      `不要把 ${city.cityNameZh}只写成观光符号、单一情绪或刻板印象。`,
      "不要把待终审锚点写成已核验事实。"
    ],
    detailPackStatus: "ready_needs_human_final_review",
    sortIndex: city.sortIndex ?? cityIndex + 1
  };
}

function buildCityPack(city, cityIndex) {
  const prototypes = selectPrototypes(city, cityIndex);
  return {
    cityId: city.cityId,
    cityNameZh: city.cityNameZh,
    cityNameLocal: city.cityNameLocal,
    countryOrRegion: city.countryOrRegion,
    continent: city.continent,
    overviewForWriters: `${city.cityNameZh}城市包使用真实城市内的生活锚点或待终审锚点。明信片重点放在物件、小动作和小动物反应，不写成景点介绍。`,
    verificationStatus: "ready_needs_human_final_review",
    globalAvoidRules: [
      `不要把 ${city.cityNameZh}只写成观光符号、单一情绪或刻板印象。`,
      "不要把城市级生活锚点当成已经人工核验的具体地址。",
      "如果 sourceRefs 尚未人工终审，最终产品文案只能使用城市级描述。"
    ],
    scenes: prototypes.map((prototype, sceneIndex) => buildScene(city, cityIndex, prototype, sceneIndex))
  };
}

const eventCategories = [
  ["transport_waiting", "等车换乘", "transport_hub", ["车票", "站牌", "路线图", "号码纸", "行李挂牌", "交通卡", "纸杯", "改线公告", "票夹", "出口编号"]],
  ["weather_shelter", "天气避让", "street_corner", ["雨伞", "伞套", "湿纸巾", "帽檐", "鞋印", "围巾", "纸袋", "门垫", "水痕", "折伞扣"]],
  ["small_purchase", "小额购买", "food_counter", ["零钱", "收据", "杯套", "菜单", "油纸袋", "找零盒", "号码夹", "餐巾纸", "小票", "瓶盖"]],
  ["queue_and_order", "排队与顺序", "market", ["队尾标识", "号码牌", "排队绳", "餐盘", "称台小票", "找零盒", "纸袋", "座位号纸", "托盘", "外带袋"]],
  ["lost_and_reroute", "迷路与改道", "metro_transfer", ["地图", "路牌", "票背面", "铅笔", "手机低电提示", "出口编号", "便签", "站内箭头", "街角门牌", "小地图"]],
  ["object_repair", "修补小物", "lodging", ["扣子", "针线包", "坏伞", "袖口", "纸盒", "胶带角", "衣夹", "备用扣", "书签", "拉链头"]],
  ["quiet_observation", "安静观察", "quiet_place", ["报纸", "长椅编号", "落叶", "水瓶", "脚印", "旧海报", "窗边灰尘", "票根", "纸页", "小石子"]],
  ["help_without_intrusion", "不打扰地帮忙", "small_shop", ["门把手", "摊布角", "掉落笔帽", "小水桶", "外卖袋", "药袋", "排队绳", "自行车牌", "包装纸", "伞架"]],
  ["name_and_ticket", "名字与票据", "museum_edge", ["票根", "寄存牌", "借阅条", "纸杯名字", "信封", "座位号", "导览折页", "房卡", "明信片背面", "邮票"]],
  ["not_sending", "没有寄出", "quiet_return", ["明信片", "邮票", "投递口盖子", "地址栏", "铅笔", "信封", "邮筒影子", "胶带角", "公告纸边", "空白贴纸"]]
];

const eventActions = [
  ["把它压平", "放到更稳的位置", "多看一遍再决定"],
  ["擦掉水痕", "等一小会儿", "让开门口"],
  ["递还给对方", "重新排到队尾", "把多的一份留出来"],
  ["确认顺序", "往后退半步", "扶正被碰歪的东西"],
  ["把路线折回去", "在边角做记号", "承认自己看错了"],
  ["临时扣好", "把它收到小袋里", "没有立刻丢掉"],
  ["只记下一个细节", "把物件放回原处", "不去追问"],
  ["扶一下就松手", "提醒一句就走开", "把东西移到不挡路的位置"],
  ["把名字转到背面", "夹进书页", "没有改掉那个错字"],
  ["先带回去", "把邮票按平", "合上投递口又松开"]
];

const eventNames = [
  ["等车", "买票", "错过车", "看错方向", "临时改道", "出口看错", "票角折皱", "行李挂牌掉了", "末班车晚到", "车票被风吹起"],
  ["避雨", "风吹开地图", "鞋底湿", "突然降温", "伞收不起来", "门垫积水", "纸袋被打湿", "围巾滑落", "台阶反光", "伞套漏水"],
  ["找零钱", "买错东西", "多买一份", "杯名写错", "点错菜单", "小票夹住", "号码夹拿错", "瓶盖滚远", "餐巾纸被吹起", "外带袋漏出一角"],
  ["排错队", "让别人先", "被催促", "拿错号码", "多等一会儿", "排队绳歪了", "托盘滑了一下", "找零盒满了", "座位号看反", "称台小票没拿"],
  ["地图折错", "路牌看不清", "备用路线", "绕远路", "少检查一次", "出口编号记反", "手机快没电", "便签掉了", "街角门牌被挡住", "站内箭头贴歪"],
  ["缝扣子", "整理围巾", "修伞扣", "贴平纸角", "放回盒子", "夹回衣夹", "捡起备用扣", "夹好书签", "拉链头卡住", "胶带角翘起"],
  ["旁观一张报纸", "记下长椅编号", "看见落叶停住", "水瓶立起来", "绕开脚印", "旧海报没撕完", "窗边灰尘被照亮", "票根夹在书里", "纸页翻过一角", "小石子滚到鞋边"],
  ["扶住门", "压住摊布", "捡回笔帽", "挪开小水桶", "放回外卖袋", "确认药袋名字", "扶正排队绳", "看一眼自行车牌", "按住包装纸", "把伞放回伞架"],
  ["票根撕歪", "寄存牌差点丢", "借阅条夹错", "纸杯名字写错", "信封没写完", "座位号看反", "导览折页折反", "房卡找不到", "明信片背面空着", "邮票贴歪"],
  ["没投出去", "邮票按了两次", "投递口合上", "地址写到一半", "铅笔太短", "信封没封口", "邮筒影子变长", "胶带角翘着", "公告纸边被风掀起", "空白贴纸留着"]
];

function buildEvents() {
  const events = [];
  eventCategories.forEach(([eventType, prefix, sceneType, objects], catIndex) => {
    for (let i = 0; i < 10; i += 1) {
      const name = eventNames[catIndex][i];
      const coreObject = objects[i];
      const seed = catIndex * 31 + i * 7;
      events.push({
        eventId: `${eventType}_${String(i + 1).padStart(2, "0")}`,
        eventName: `${prefix}：${name}`,
        eventType,
        trigger: `旅行途中在适配场景遇到“${name}”这件小事。`,
        coreObject,
        actionOptions: pick(eventActions[catIndex], seed, 3),
        possibleOutcomes: [
          `${coreObject}的状态变清楚或被放稳。`,
          "小动物少带、多带或暂时收起了一样小东西。",
          "事件没有变大，但结尾能从这个动作自然长出来。"
        ],
        microArcFits: pick(microArcs, seed + 1, 3),
        postcardTypes: pick(postcardTypes, seed + 2, 3),
        animalAffinity: pick(animals, seed + 3, 3),
        sceneTypeFits: pick([sceneType, "street_corner", "quiet_place", "small_shop", "transport_hub", "market", "quiet_return"], seed + 4, 3),
        emotionWeightRange: [0, Math.min(3, 1 + (i % 3))],
        styleRisks: [
          "不要写成抽象金句。",
          "不要让核心物件只做背景。",
          "结尾必须来自本事件的动作结果。"
        ],
        continuityCheck: `删除“${coreObject}”或“${name}”后，结尾不应继续成立。`
      });
    }
  });
  return events;
}

const newCandidates = {
  version: 2,
  locale: "zh-Hans",
  count: cities.length,
  verificationStatus: "ready_needs_human_final_review",
  cities: cities.map(buildCandidate)
};

const newDetailPacks = {
  version: 2,
  locale: "zh-Hans",
  cityCount: cities.length,
  scenesPerCity: 10,
  totalScenes: cities.length * 10,
  verificationStatus: "ready_needs_human_final_review",
  schemaAdditions: ["anchorKind", "verificationStatus", "sourceRefs"],
  cityPacks: cities.map(buildCityPack)
};

const newEvents = {
  version: 2,
  locale: "zh-Hans",
  count: 100,
  duplicatePolicy: "eventName must be unique in V2 rebuilt library",
  events: buildEvents()
};

const newGeographyCapabilities = {
  version: 2,
  locale: "zh-Hans",
  count: geographyCapabilities.length,
  purpose: "coarse geography guardrail for filtering obvious scene/location mismatches before human final review",
  defaultPolicy: "unknown capabilities default to false; uncertain water, tram, ferry and slope scenes downgrade to ordinary daily spaces",
  capabilities: geographyCapabilities
};

fs.writeFileSync(candidatePath, `${JSON.stringify(newCandidates, null, 2)}\n`);
fs.writeFileSync(detailPath, `${JSON.stringify(newDetailPacks, null, 2)}\n`);
fs.writeFileSync(eventPath, `${JSON.stringify(newEvents, null, 2)}\n`);
fs.writeFileSync(geographyPath, `${JSON.stringify(newGeographyCapabilities, null, 2)}\n`);

console.log(JSON.stringify({
  cityCandidates: newCandidates.cities.length,
  cityPacks: newDetailPacks.cityPacks.length,
  totalScenes: newDetailPacks.totalScenes,
  events: newEvents.events.length,
  geographyCapabilities: newGeographyCapabilities.capabilities.length,
  scenePrototypeCount: scenePrototypes.length,
  status: "rebuilt"
}, null, 2));
