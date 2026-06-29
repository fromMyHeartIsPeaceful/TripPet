#!/usr/bin/env python3
"""Generate the 1.0 draft care postcard corpus for author review.

This is an authoring helper only. It does not feed the runtime Swift postcard
library. Direction 01 is read from the current 90-line sample draft; the other
13 directions are expanded from scene notes plus animal voice templates.
"""

from __future__ import annotations

import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SOURCE_DRAFT = REPO_ROOT / "Content" / "AnimalDatabase" / "PostcardGreetingCare_Draft.md"
OUTPUT = REPO_ROOT / "Content" / "AnimalDatabase" / "PostcardGreetingCare_1.0_Draft.md"

ANIMALS = [
    ("xiaoman_hamster", "小满", "仓鼠"),
    ("tangyuan_puppy", "糖圆", "小狗"),
    ("moji_cat", "墨迹", "猫"),
    ("dengdeng_rabbit", "灯灯", "兔子"),
    ("feifei_parrot", "飞飞", "鹦鹉"),
    ("xiaolu_guinea_pig", "小炉", "豚鼠"),
    ("deer_visitor", "啾啾", "小鹿"),
    ("fox_visitor", "埃尼", "小狐狸"),
    ("bear_visitor", "墩墩", "小熊"),
]

DIRECTIONS = [
    "疲惫恢复/夜间关照",
    "久坐与身体活动",
    "喝水与饮食",
    "睡眠与收工",
    "工作压力与节奏",
    "委屈与不被理解",
    "情绪乱/信息太多",
    "低电量与空掉",
    "自我责备与失败感",
    "直接想念与回家期待",
    "轻鼓励与继续出发",
    "小 tips/健康提醒",
    "天气、季节与身体感受",
    "早晨/重新开始",
]

BANNED = [
    "我陪你",
    "抱抱你",
    "在你身边",
    "等你回来",
    "你要接纳自己",
    "允许情绪流动",
    "你值得被爱",
    "你受伤了",
    "你焦虑了",
]

SCENES: dict[str, list[tuple[str, str, str]]] = {
    "久坐与身体活动": [
        ("坐久了，肩膀会比你更早喊累", "站起来走两步，顺便看看远处", "这不算打断，是换气"),
        ("屏幕看太久，眼睛会发干", "把视线挪到窗外十秒", "让脑袋从格子里出来一下"),
        ("腿麻了还硬撑，身体会偷偷生气", "绕桌子走一圈", "短短一圈也能把人叫回来"),
        ("手腕酸的时候，不要继续当没事", "转一转，揉一揉", "小地方也需要被认真对待"),
        ("一下午没动，心也会变闷", "倒水时多走几步", "路短也能带来一点新空气"),
        ("背绷得太紧，整个人会像被拉住", "把肩膀放低，再慢慢呼气", "不用做得很标准"),
        ("椅子坐久了，会把人固定住", "站起来把脚踩实", "地面会帮你稳一下"),
        ("脖子发沉时，别急着继续低头", "抬头看一眼天花板", "让上半身松一点"),
        ("忙到忘记活动，也不是你的错", "现在伸个懒腰就行", "照顾可以从这一秒开始"),
        ("身体发僵，是在提醒你换个姿势", "走到门口再回来", "把自己从疲惫里挪出来一点"),
    ],
    "喝水与饮食": [
        ("水杯如果离得太远，喝水就会被忘掉", "把它放到手边", "让提醒变得容易一点"),
        ("吃饭太快，身体会追不上你", "慢一点咬，慢一点吞", "别把一顿饭也过成赶路"),
        ("空着肚子想事情，心会变薄", "找点热的吃", "不丰盛也可以，很有用"),
        ("咖啡能撑一会儿，但不能替代水", "再喝几口清水", "给身体一点真正的补给"),
        ("饭点过了，也别假装没关系", "随便吃点也好", "别让忙碌把你漏掉"),
        ("边刷消息边吃饭，心很难休息", "把手机放远一点", "让饭和你单独待一会儿"),
        ("只想糊弄一口的时候", "也请加一点热的", "身体会记得这份小认真"),
        ("甜的能让心亮一下", "正餐也要有", "快乐和补给都别少"),
        ("喝水这件小事不华丽", "但会把人慢慢安定下来", "杯子拿起来就算开始"),
        ("饿着的时候，世界容易变硬", "吃完再处理麻烦", "很多事会没那么尖"),
    ],
    "睡眠与收工": [
        ("收工时间到了，明天就先放回明天", "把电脑合上", "人不是一直亮着的屏幕"),
        ("睡前再多看几条消息，脑袋会更吵", "把手机放远一点", "夜晚需要慢慢暗下来"),
        ("今晚目标可以很小", "洗漱、关灯、躺下", "完成这些就已经很好"),
        ("困意来敲门时，不要让它等太久", "顺着它去睡吧", "休息也是正经事"),
        ("工作没有完全结束，也可以暂停", "把最后一步写下来", "明天接上会更清楚"),
        ("上床前别反复检查烦心事", "闹钟设好就够了", "夜晚不是审判时间"),
        ("睡不着时，不要再责怪自己", "灯暗一点，身体躺平一点", "恢复可以慢慢发生"),
        ("收工仪式不用复杂", "水杯洗掉，桌面留一点空", "心也会跟着空一点"),
        ("明天的事不用现在背上床", "把它们留在纸上", "被子里只放你自己"),
        ("早点睡不是认输", "是给明天留力气", "这个决定很朴素，也很聪明"),
    ],
    "工作压力与节奏": [
        ("事情很多时，脑袋会乱成一团线", "挑最小的一根先解", "开始小一点更稳"),
        ("被催得很急，也别把呼吸交出去", "慢一拍再回话", "认真不等于慌张"),
        ("进度表可以很满", "心不要被填满", "你不是一张待办清单"),
        ("工作声音太大时", "在心里把音量调低一点", "你可以努力，也可以保留自己"),
        ("不用同时处理所有事", "把今天拆成几小块", "一块一块来就好"),
        ("忙到发麻的时候", "喝水，站起来，再回来", "这不是拖延，是校准"),
        ("别拿最累的状态要求最高效率", "先把标准降一点", "这样比较公平"),
        ("你不是永远满电的机器", "补给和暂停都算工作的一部分", "别漏掉自己"),
        ("计划乱了，就写三行", "现在、下一步、可以晚点", "剩下的先别碰"),
        ("下班以后，工作还想追上来", "给它关一扇门", "心也需要真正离场"),
    ],
    "委屈与不被理解": [
        ("被误会的时候，心会很累", "不用马上讲清楚", "先把自己照顾好"),
        ("有些人没听懂，不代表你说错了", "今晚别反复重演那一幕", "别把迟钝都算到自己身上"),
        ("委屈可以先放在这里", "不用包装成懂事", "喝口热的，慢慢缓"),
        ("别人没有看见你的努力", "努力并没有因此消失", "这句话需要被认真留下"),
        ("不被理解的时候", "别急着怀疑自己", "离开那段声音一会儿"),
        ("忍了很多话也很耗力气", "可以晚点再说", "不用为了被懂立刻耗尽"),
        ("难受不是矫情", "被刺到就是被刺到", "先照顾疼的那一块"),
        ("别人的粗心，不该全变成你的自责", "把那部分还回去", "你不用全部背着"),
        ("你已经很努力维持体面了", "现在可以松一点", "哪怕只松一小会儿"),
        ("委屈过夜也没关系", "睡一觉再决定要不要说清楚", "不用今晚就解决全部"),
    ],
    "情绪乱/信息太多": [
        ("消息太多时，脑袋会被挤满", "把提示音关小", "不是逃避，是留路"),
        ("心里乱成一桌纸", "先找最小的一张纸", "不用马上收完整张桌子"),
        ("屏幕一直亮，心也难暗下来", "少看一会儿", "给眼睛和脑袋一点空白"),
        ("情绪挤在一起时", "只认出一个就好", "累、饿、困，知道一点就够"),
        ("别急着回复所有人", "把自己排到前面一点", "消息可以等一会儿"),
        ("脑袋太满的时候", "写下现在、担心、下一步", "纸会替你分担一点"),
        ("信息会一直来", "你不用一直接住", "手机远一点，水杯近一点"),
        ("烦躁的时候，别跟自己吵架", "洗把脸，换个位置", "情绪也需要换气"),
        ("很多声音都在抢你", "身体的声音也要听", "它可能只是在说累了"),
        ("世界太吵时", "守住一小块安静", "那一小块就够你喘口气"),
    ],
    "低电量与空掉": [
        ("什么都不想做的时候", "别急着判定自己没用", "低电量需要充电"),
        ("心里空空的，就做一件小事", "喝水、洗脸、开灯", "小事会慢慢接住你"),
        ("没有力气社交也没关系", "回复可以晚一点", "把自己放前一点"),
        ("像没电一样的时候", "不要继续硬耗", "找个安静角落坐到呼吸回来"),
        ("空掉不是坏掉", "可能只是太久没有补给", "吃点热的，慢慢恢复"),
        ("不想动时，把目标改小", "站起来，倒水，再坐下", "完成一格也很好"),
        ("心里没有声音也可以", "安静不是失败", "那可能是在修复"),
        ("别用满电时的标准要求自己", "低电量就低电量过", "公平一点"),
        ("能维持到这里，已经不容易", "剩下的力气留给睡觉", "明天再慢慢续上"),
        ("空空的时候，不需要大道理", "热水、被子和一点时间", "就很够用"),
    ],
    "自我责备与失败感": [
        ("搞砸一件事，不等于你整个人搞砸了", "先停下责备", "看看下一步在哪里"),
        ("别把一次失误翻译成我不行", "这个翻译太粗暴", "不准确，也不公平"),
        ("脑袋一直骂你的时候", "把声音调小一点", "你需要复盘，不需要挨打"),
        ("失败感很重时", "吃点东西再想", "空着肚子会判得太狠"),
        ("可以承认难过，也可以重新来", "两件事不冲突", "不用急着选一个"),
        ("不是每次努力都会立刻有结果", "但努力没有消失", "它只是还没长成答案"),
        ("别急着把错误全背在身上", "先分清哪些是你的", "哪些不是"),
        ("没做好，也可以先睡", "明天的你会更有力气看它", "夜里不用硬判"),
        ("自责不是补救方案", "喝水，休息，写下一步", "这才比较有用"),
        ("你不会因为一次失败就变小", "只是这段路难走一点", "慢慢走也可以"),
    ],
    "直接想念与回家期待": [
        ("突然想起你，就想给你写张明信片", "饭要好好吃", "等我回家，再听你慢慢说"),
        ("路上看到一盏晚灯", "忽然想问你睡了没", "别熬太晚，等我回家"),
        ("这张卡先到，我晚一点回家", "你不用一直很坚强", "照顾好自己就很重要"),
        ("有些话不长", "我想起你了", "记得喝水，别久坐，等我回家"),
        ("给你写这张明信片时，心里很安静", "希望它到你手里", "能给你一点力气"),
        ("今天路很长，想到你时就没那么空", "给你写一张卡", "提醒你吃饭慢一点"),
        ("等我回家前", "你要把自己照顾好", "喝水、吃饭、早点睡，就很好"),
        ("这张明信片没有大道理", "只是想说我记得你", "也希望你轻松一点"),
        ("忽然想知道你有没有好好休息", "别只顾忙", "给自己留一口热饭"),
        ("明信片会先替我敲门", "说一句辛苦啦", "等我回家，你要好好的"),
    ],
    "轻鼓励与继续出发": [
        ("休息过后再继续，也算继续", "别把停一下当退后", "路还在，不会跑掉"),
        ("你不需要一下变得很厉害", "往前一点点就好", "一点点也是方向"),
        ("慢一点也能到", "把步子放小", "别把心拉得太紧"),
        ("可以继续加油", "但别用力到把自己弄丢", "照顾好自己才走得远"),
        ("有些路就是不好走", "不好走不代表走错", "歇一下再看下一步"),
        ("别急着证明全部", "先完成一个小目标", "剩下的慢慢排队"),
        ("你已经撑过很多次", "这一次也可以小口呼吸", "再继续"),
        ("给你一点不吵的鼓励", "可以慢慢来", "也可以重新开始"),
        ("往前走之前", "确认鞋带和心情都没被绊住", "这样比较稳"),
        ("力气不多也没关系", "用一点，留一点", "明天还有路"),
    ],
    "小 tips/健康提醒": [
        ("小 tips：吃饭慢一点", "胃会比较高兴", "健康的身体最重要"),
        ("记得不要久坐哦", "起来走两步，顺便把水杯倒满", "小提醒完成"),
        ("睡前别喝太多咖啡", "也别把烦心事带进被子", "两样都会让夜晚变吵"),
        ("看屏幕久了，看看远处", "眼睛不是玻璃做的", "也会累"),
        ("天冷记得加衣服", "不要等打喷嚏才承认冷", "身体的小信号要早听见"),
        ("饭不要吃太急", "慢一点，咬清楚一点", "身体会比较安心"),
        ("水杯放在看得见的地方", "喝水这件事就会简单很多", "这是实用魔法"),
        ("睡前把手机放远一点", "不是自律表演", "是让脑袋有机会安静"),
        ("出门前看一眼天气", "带伞或外套", "照顾自己有时就是少淋一场雨"),
        ("忙的时候也要伸伸手腕", "小地方轻松一点", "整个人会少紧一点"),
    ],
    "天气、季节与身体感受": [
        ("风大时，记得把领口拉好", "身体暖一点", "心也不容易被吹散"),
        ("下雨天容易低落", "吃点热的吧", "雨声可以大，你不用跟着沉下去"),
        ("天冷的时候，不要只靠忍", "加衣服，喝热水", "别让身体替你硬撑"),
        ("太阳好的时候", "晒一小会儿也可以", "不是为了积极，是让身体记得还有光"),
        ("换季容易疲惫", "别怪自己反应慢", "身体在适应，心也需要时间"),
        ("潮湿天气会让人发沉", "袜子换干的，灯开暖一点", "先照顾实际的部分"),
        ("热的时候别忘了喝水", "烦躁可能不是坏脾气", "只是身体太渴"),
        ("冷风进来时，先关窗", "能挡住一点是一点", "不用什么都硬扛"),
        ("阴天也可以过得慢一点", "把饭吃热，把灯开稳", "心情不用立刻放晴"),
        ("季节在变，你也可以慢慢变", "别催自己一下适应所有温度", "慢慢来就好"),
    ],
    "早晨/重新开始": [
        ("早上醒来，先别急着拿手机", "喝口水，看看窗外", "让新一天慢一点进来"),
        ("不用一开始就满格", "洗脸，吃早饭", "这两件就是很好的开头"),
        ("昨晚没睡好，也别先责怪自己", "早晨可以轻一点", "计划也可以小一点"),
        ("重新开始不一定很响", "把杯子倒满，把鞋穿好", "然后出门"),
        ("早饭记得吃", "空着肚子开始一天", "心情容易被小事撞倒"),
        ("如果昨天很难", "今天就把目标放低一点", "低一点不是差，是留路"),
        ("醒来时心还是沉的，也没关系", "把窗帘拉开一点", "光会慢慢进来"),
        ("新一天不需要立刻证明什么", "先照顾身体", "再处理世界"),
        ("出门前慢一点", "钥匙、水、外套，都确认好", "少一点慌张也是照顾"),
        ("早晨给自己一句小话", "可以慢慢来", "然后从第一件小事开始"),
    ],
}

PROFILES: dict[str, list[str]] = {
    "xiaoman_hamster": [
        "{core}。{advice}。{extra}。小满轻轻提醒你。",
        "{core}。{advice}。{extra}，小满把话放低一点说。",
        "{core}。{advice}。{extra}。不用急着逞强，小满觉得这样就好。",
        "{core}。{advice}。{extra}。一点点就够，小满认真写下这一句。",
        "{core}。{advice}。{extra}。小满希望你别太用力。",
        "{core}。{advice}。{extra}。把自己照看得轻一点。",
        "{core}。{advice}。{extra}。小满不催你，只想让你松一小口气。",
        "{core}。{advice}。{extra}。像把皱起的纸角慢慢抚平。",
        "{core}。{advice}。{extra}。小满觉得这样比较稳。",
        "{core}。{advice}。{extra}。小满的明信片，只负责轻轻提醒。",
    ],
    "tangyuan_puppy": [
        "汪，{core}。{advice}。{extra}。糖圆觉得身体会轻快一点。",
        "{core}。{advice}。{extra}。这条小 tips 糖圆觉得很有用，汪。",
        "糖圆提醒：{core}。{advice}。{extra}。别把自己忙丢啦。",
        "{core}。{advice}。{extra}。然后给自己一点小奖励，汪。",
        "汪！{core}。{advice}。{extra}。健康的身体最重要。",
        "{core}。{advice}。{extra}。糖圆听了会皱鼻子，别硬撑。",
        "{core}。{advice}。{extra}。糖圆给这条提醒盖一个亮亮的章。",
        "{core}。{advice}。{extra}。一点点照顾也会变成很多力气。",
        "糖圆小声汪一下：{core}。{advice}。{extra}。你要好好吃饭好好休息。",
        "{core}。{advice}。{extra}。糖圆相信你能慢慢找回状态。",
    ],
    "moji_cat": [
        "{core}。{advice}。{extra}。猫的评价：这不是偷懒，是必要维护。",
        "{core}。{advice}。{extra}。墨迹认为，够了就该停。",
        "{core}。{advice}。{extra}。别证明自己还能扛，没必要。",
        "{core}。{advice}。{extra}。墨迹把话说短：对自己别那么狠。",
        "{core}。{advice}。{extra}。今晚别把这件事回放十遍。",
        "墨迹判断：{core}。{advice}。{extra}。这比继续硬撑有用。",
        "{core}。{advice}。{extra}。猫不爱安慰，但这句是真的。",
        "{core}。{advice}。{extra}。别审问自己，处理实际问题。",
        "{core}。{advice}。{extra}。这张明信片没有花话，只有结论。",
        "{core}。{advice}。{extra}。墨迹建议别再追加惩罚。",
    ],
    "dengdeng_rabbit": [
        "{core}。{advice}。{extra}。灯灯把灯调暖一点，这样比较好缓过来。",
        "{core}。{advice}。{extra}。别让自己一直亮得太辛苦。",
        "{core}。{advice}。{extra}，像把被角掖好一点，灯灯这样想。",
        "{core}。{advice}。{extra}，给身体一小块柔软的时间。",
        "灯灯轻轻写：{core}。{advice}。{extra}。今晚可以慢一点。",
        "{core}。{advice}。{extra}。热一点、暗一点，心会比较安稳。",
        "{core}。{advice}。{extra}。灯灯希望这张卡能让你松下来一点。",
        "{core}。{advice}。{extra}。别让夜晚继续替白天加班。",
        "{core}。{advice}。{extra}。灯灯建议这样，很普通，但很暖。",
        "{core}。{advice}。{extra}。这句话像一盏小灯，给你留一点亮。",
    ],
    "feifei_parrot": [
        "{core}。{advice}。{extra}。飞飞把中场灯光调低，给你一点喘息。",
        "{core}。{advice}。{extra}。舞台也有换景时间，不必一直站在亮处。",
        "{core}。{advice}。{extra}。这不是退场，是漂亮的中场整理。",
        "{core}。{advice}。{extra}。让今天的幕布慢慢落下来。",
        "飞飞宣布：{core}。{advice}。{extra}。掌声暂时不用急着要。",
        "{core}。{advice}。{extra}。卸下一点亮片，也会更轻。",
        "{core}。{advice}。{extra}。飞飞觉得，下一幕可以晚一点开。",
        "{core}。{advice}。{extra}。把聚光灯从压力上移开一会儿。",
        "{core}。{advice}。{extra}。这叫优雅地保存体力。",
        "{core}。{advice}。{extra}。飞飞给你留一束不刺眼的小灯。",
    ],
    "xiaolu_guinea_pig": [
        "小炉后勤记录：{core}。处理方式：{advice}。备注：{extra}。",
        "{core}。小炉建议：{advice}。{extra}。基础补给要补上。",
        "状态检查：{core}。下一步：{advice}。{extra}。不用复杂，照做一条就行。",
        "{core}。{advice}。{extra}。小炉认为这是必要维护，不是偷懒。",
        "{core}。{advice}。{extra}。小炉把清单缩短到这里。",
        "{core}。{advice}。{extra}。效率反而会稳一点。",
        "小炉提醒你：{core}。{advice}。{extra}。身体数据会诚实报警。",
        "{core}。{advice}。{extra}。这条不浪漫，但很管用。",
        "{core}。{advice}。{extra}。小炉建议处理可处理的部分。",
        "{core}。{advice}。{extra}。小炉确认：补给优先。",
    ],
    "deer_visitor": [
        "{core}。啾啾小声确认：{advice}。{extra}。不用一下回到很厉害。",
        "{core}。{advice}。{extra}。把声音放低一点，世界就没那么近。",
        "{core}。{advice}。{extra}。啾啾觉得你可以停在这里。",
        "{core}。{advice}。{extra}。慢慢来，呼吸会找到位置。",
        "啾啾轻轻写：{core}。{advice}。{extra}。别让消息贴得太近。",
        "{core}。{advice}。{extra}。给自己一点安全的空白。",
        "{core}。{advice}。{extra}。啾啾确认过了，这样已经很好。",
        "{core}。{advice}。{extra}。把眼前变小一点。",
        "{core}。{advice}。{extra}。啾啾建议只做一点点。",
        "{core}。{advice}。{extra}。这张明信片只发出很轻的声音。",
    ],
    "fox_visitor": [
        "{core}。{advice}。{extra}。埃尼勉强承认：这办法还算聪明。",
        "{core}。{advice}。{extra}。省点力气给真正重要的事。",
        "{core}。{advice}。{extra}。埃尼只是顺便提醒，才不是特意关心。",
        "{core}。{advice}。{extra}。这叫策略，不叫示弱。",
        "埃尼判断：{core}。{advice}。{extra}。比继续逞强划算。",
        "{core}。{advice}。{extra}。别问，照顾自己这件事很有性价比。",
        "{core}。{advice}。{extra}。别把小问题拖成大麻烦。",
        "{core}。{advice}。{extra}。埃尼把话说完就走，但你要记得。",
        "{core}。{advice}。{extra}。不要反驳有用的建议。",
        "{core}。{advice}。{extra}。埃尼觉得你可以少为难自己一点点。",
    ],
    "bear_visitor": [
        "{core}。{advice}。{extra}。墩墩觉得稳住就很好。",
        "{core}。{advice}。{extra}。慢慢来，厚一点的力气会回来。",
        "{core}。{advice}。{extra}，像把沉的东西放下一小块。",
        "{core}。{advice}。{extra}。不急，坐稳了再继续。",
        "墩墩认真写：{core}。{advice}。{extra}。别空着肚子硬撑。",
        "{core}。{advice}。{extra}。身体暖一点，心就有地方落脚。",
        "{core}。{advice}。{extra}。墩墩觉得今天这样已经够好了。",
        "{core}。{advice}。{extra}。给自己一点重量感。",
        "{core}。{advice}。{extra}。墩墩建议这样，很普通，但很可靠。",
        "{core}。{advice}。{extra}。这张明信片慢慢说：你可以歇一歇。",
    ],
}

XIAN_REPLACEMENTS = [
    ("可以先", "可以暂时"),
    ("也可以先", "也可以暂时"),
    ("先把", "把"),
    ("先照顾", "照顾"),
    ("先停下", "暂停"),
    ("先停", "停"),
    ("先放", "暂时放"),
    ("先关窗", "把窗关上"),
    ("先完成", "完成"),
    ("先找", "找"),
    ("先认出", "认出"),
    ("先吃", "吃"),
    ("先喝", "喝"),
    ("先分清", "分清"),
    ("先处理", "处理"),
    ("先补", "补"),
    ("先给", "给"),
    ("先稳住", "稳住"),
    ("先歇", "歇"),
    ("先不", "暂时不"),
    ("先别", "暂时别"),
    ("先写", "写"),
    ("先小口", "小口"),
]

PUNCTUATION_REPLACEMENTS = [
    ("的时候。", "的时候，"),
    ("时。", "时，"),
    ("之前。", "之前，"),
    ("以后。", "以后，"),
    ("前。", "前，"),
    ("如果昨天很难。", "如果昨天很难，"),
    ("分清哪些是你的。哪些不是。", "分清哪些是你的，哪些不是。"),
]


def parse_existing() -> dict[str, list[str]]:
    current: str | None = None
    result: dict[str, list[str]] = {}
    for line in SOURCE_DRAFT.read_text(encoding="utf-8").splitlines():
        heading = re.match(r"^##\s+.+?｜(.+)$", line)
        if heading:
            current = heading.group(1).strip()
            result[current] = []
            continue
        item = re.match(r"^\d+\.\s+(.+)$", line)
        if item and current:
            result[current].append(item.group(1).strip())
    return result


def make_lines(key: str, name: str, direction: str) -> list[str]:
    templates = PROFILES[key]
    scenes = SCENES[direction]
    lines = []
    for index, (core, advice, extra) in enumerate(scenes):
        template = templates[index]
        line = template.format(
            name=name,
            core=core,
            advice=advice,
            extra=extra,
        )
        for source, replacement in XIAN_REPLACEMENTS:
            line = line.replace(source, replacement)
        for source, replacement in PUNCTUATION_REPLACEMENTS:
            line = line.replace(source, replacement)
        lines.append(line)
    return lines


def validate(lines_by_key: dict[str, dict[str, list[str]]]) -> None:
    total = 0
    seen: set[str] = set()
    for key, _name, _species in ANIMALS:
        if set(lines_by_key[key]) != set(DIRECTIONS):
            raise ValueError(f"{key} directions mismatch")
        for direction in DIRECTIONS:
            lines = lines_by_key[key][direction]
            if len(lines) != 10:
                raise ValueError(f"{key} {direction}: {len(lines)} lines")
            total += len(lines)
            for line in lines:
                if any(term in line for term in BANNED):
                    raise ValueError(f"banned phrase in {key}/{direction}: {line}")
                if line in seen:
                    raise ValueError(f"duplicate line: {line}")
                seen.add(line)
    if total != 1260:
        raise ValueError(f"expected 1260 lines, got {total}")


def main() -> None:
    existing = parse_existing()
    lines_by_key: dict[str, dict[str, list[str]]] = {}
    for key, name, _species in ANIMALS:
        source_lines = existing.get(key)
        if source_lines is None:
            raise ValueError(f"missing existing sample lines for {key}")
        if len(source_lines) != 10:
            raise ValueError(f"{key} source draft expected 10 lines, got {len(source_lines)}")
        lines_by_key[key] = {"疲惫恢复/夜间关照": source_lines}
        for direction in DIRECTIONS[1:]:
            lines_by_key[key][direction] = make_lines(key, name, direction)

    validate(lines_by_key)

    output: list[str] = [
        "# 小动物关照明信片语料库 1.0 草稿",
        "",
        "> 目的：作者语料草稿，不接入运行时文本库。",
        "> 规模：9 只小动物，每只 14 个方向，每方向 10 条，共 1260 条。",
        "> 继承：每只动物第 1 个方向沿用 `PostcardGreetingCare_Draft.md` 当前 10 条。",
        "> 边界：直接关照用户，允许想念和等我回家；禁止心理咨询腔和现实同空间陪伴承诺。",
        "",
    ]
    for key, name, species in ANIMALS:
        output.append(f"## {name}｜{key}｜{species}")
        output.append("")
        for index, direction in enumerate(DIRECTIONS, start=1):
            output.append(f"### {index:02d}. {direction}")
            output.append("")
            for item_index, line in enumerate(lines_by_key[key][direction], start=1):
                output.append(f"{item_index}. {line}")
            output.append("")

    OUTPUT.write_text("\n".join(output), encoding="utf-8")
    print(f"wrote {OUTPUT}")
    print("total: 1260")


if __name__ == "__main__":
    main()
