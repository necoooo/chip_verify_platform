[![](https://img-home.csdnimg.cn/images/20201124032511.png)](https://www.csdn.net/)

- [博客](https://blog.csdn.net/)
- [下载](https://download.csdn.net/)
- [社区](https://devpress.csdn.net/)
- [![](https://img-home.csdnimg.cn/images/20240829093757.png)AtomGit](https://link.csdn.net/?target=https%3A%2F%2Fgitcode.com%3Futm_source%3Dcsdn_toolbar)
- [![](https://i-operation.csdnimg.cn/images/39657dbbb2604501b9aa9f52194654ad.png)模型市场\\
![](https://i-operation.csdnimg.cn/images/649cffb08af94768b41d9f9485799efe.png)](https://taotoken.net/?utm_source=tt_csdn_home_topbar)
- 更多


[会议](https://www.bagevent.com/event/9117243 "会议") [学习](https://edu.csdn.net/?utm_source=zhuzhantoolbar "高质量课程·大会云会员") [![](https://i-operation.csdnimg.cn/images/77c4dd7a760a493498bee1d336b064c0.png)InsCode](https://inscode.net/?utm_source=csdn_blog_top_bar "InsCode")


搜索

AI 搜索

登录

登录后您可以：

- 复制代码和一键运行
- 与博主大V深度互动
- 解锁海量精选资源
- 获取前沿技术资讯

立即登录

[![](https://i-operation.csdnimg.cn/images/f9098e9320264ddc85f274234b2f0c6a.png)新客开通会员 立减60![](https://i-operation.csdnimg.cn/images/97f199b02b604390ab516e4897fb5bfe.png)](https://mall.csdn.net/vip?utm_source=dl_hover)

[会员·新人礼包 ![](https://i-operation.csdnimg.cn/images/105eda9d414f4250a7c3fe45be3cd15f.png)](https://mall.csdn.net/vip?utm_source=vip_toolbarhyzx_hy)

[消息](https://i.csdn.net/#/msg/index)

[创作中心](https://mp.csdn.net/ "创作中心")

[创作](https://mp.csdn.net/edit)

[![](https://i-operation.csdnimg.cn/images/6e41bd372d1f4ec39b3cd36ab95046c4.png)](https://mp.csdn.net/edit)![](https://i-operation.csdnimg.cn/images/43349e98a45341699652b0b6fa4ea541.png)![](https://i-operation.csdnimg.cn/images/0f13ec529b6b4195ad99894f76653e56.png)

# FPGA/Verilog 企业级编码规范

最新推荐文章于 2026-03-06 00:16:11 发布

原创于 2026-02-14 10:02:37 发布·727 阅读

·![](https://csdnimg.cn/release/blogv2/dist/pc/img/newHeart2023Active.png)![](https://csdnimg.cn/release/blogv2/dist/pc/img/newHeart2023Black.png)
18


·![](https://csdnimg.cn/release/blogv2/dist/pc/img/tobarCollect2.png)![](https://csdnimg.cn/release/blogv2/dist/pc/img/tobarCollectionActive2.png)
20
·

CC 4.0 BY-SA版权

版权声明：本文为博主原创文章，遵循 [CC 4.0 BY-SA](http://creativecommons.org/licenses/by-sa/4.0/) 版权协议，转载请附上原文出处链接和本声明。


文章标签：

[#fpga开发](https://so.csdn.net/so/search/s.do?q=fpga%E5%BC%80%E5%8F%91&t=all&o=vip&s=&l=&f=&viparticle=&from_tracking_code=tag_word&from_code=app_blog_art) [#verilog](https://so.csdn.net/so/search/s.do?q=verilog&t=all&o=vip&s=&l=&f=&viparticle=&from_tracking_code=tag_word&from_code=app_blog_art) [#编码规范](https://so.csdn.net/so/search/s.do?q=%E7%BC%96%E7%A0%81%E8%A7%84%E8%8C%83&t=all&o=vip&s=&l=&f=&viparticle=&from_tracking_code=tag_word&from_code=app_blog_art)

做FPGA研发和团队多年，经过理论和项目实践的结合，慢慢沉淀出一套经验——既有理论支撑，又能直接落地用，分享给大家。

这份Verilog编码规范核心有三点：可综合、好维护、能复用。目的是帮大家少踩坑、少出bug，适合有一定基础，想往正规工程师方向走、想把代码写漂亮的同学。

**1\.** **编码原则**

- 编码别偷懒！只写可综合的语法，那些图方便的不可综合写法，尽量别用，基础打牢才靠谱。

- 记住一点：代码首先是给人看的，其次才是给编译器看的。逻辑清晰比语句简洁更重要，不然别人看你的代码得猜半天。

- 同一个项目、同一个模块，编码风格一定要统一，别东一榔头西一棒子，整齐划一才好协作、好调试。

- 别追求“炫技”搞些花里胡哨的操作，要是不能明显提升性能、节省资源，不如不用，简约高效才是王道。

**2\. 文件与模块命名**

**2.1 文件命名**

- 记住“一文一模块”：一个.v文件只放一个module，职责分清，后续找文件、维护起来都省事。

- 文件名和模块名必须完全一样，别搞“名不副实”，不然协作的时候很容易搞混，徒增麻烦。

- 统一用“小写+下划线”命名，简单规范、一眼能看懂，别大小写混用，也别加奇怪的特殊字符。

给大家举几个规范的例子：

uart\_tx.v

fifo\_sync.v

led\_ctrl.v

**2.2 模块命名**

- 推荐用“名词+功能”来命名，下划线或者大驼峰都行，关键是整个项目保持统一，灵活又规范。

- 命名要“见名知意”，一眼就知道这个模块是干嘛的，别用拼音、乱七八糟的缩写，不然别人看名字猜不出功能，太费劲。

规范示例走一个：

UartTx

SyncFifo

LedController

**3\. 端口与信号命名**

**3.1 端口顺序（固定模板）**

端口顺序按下面这个模板来写，不用自己瞎排序，别人一看就知道哪些是
时钟
、哪些是输入输出，省得逐行找：

|     |
| --- |
| verilog<br>module 模块名<br>(<br>     // 时钟 & 复位<br>     input  wire         clk,<br>     input  wire         rst\_n,<br>     // 输入信号<br>     input  wire         data\_vld,<br>     input  wire \[7:0\]   data\_i,<br>     // 输出信号<br>     output reg          tx\_vld,<br>     output reg \[7:0\]    data\_o<br>); |

**3.2 信号命名规则**

- 信号命名也用“小写+下划线”，和文件命名保持一致，整体看起来整齐，一眼就能看清。

- 千万别用单字母命名！比如a、b、c、tmp这种，完全看不出信号是干嘛的，调试、协作的时候很容易乱。

分享几个常用的命名小约定，记下来能快速分清信号属性：

- 以 \_i 结尾：输入信号，一眼就知道信号是从哪来的

- 以 \_o 结尾：输出信号，清楚信号要送到哪去

- 以 \_n 结尾：低电平有效信号，不用再反复确认电平逻辑

- 以 \_vld 结尾：有效标志信号，知道什么时候信号生效

规范示例不用额外找，上面的端口模板里，信号命名就很标准。

**4\. 变量与位宽**

**4.1 一律写明 wire /reg**

变量声明的时候，一定要写清楚是
wire 还是reg，别依赖默认的wire类型！这种写法可读性太差，很容易让人误解逻辑，是做工程的大忌，别踩坑。

|     |
| --- |
| verilog<br>// 推荐（规范清晰，一眼看懂）<br>input  wire         clk;<br>output reg  \[7:0\]   data\_o;<br>// 不推荐（依赖默认类型，容易看错）<br>output      \[7:0\]   data\_o; |

**4.2 位宽统一写法**

- 位宽就按“高位在前、低位在后”来写，这是行业通用的习惯，别人看你的代码不用适应，调试也省事。

- 位宽要写完整，统一用\[N-1:0\]的格式，别省略高位，也别搞不规范的写法，避免位宽理解出错。

|     |
| --- |
| verilog<br>// 推荐（规范完整，不容易错）<br>reg \[7:0\]   data;<br>// 不推荐（写法不规范，容易误解位宽）<br>reg \[0:7\]   data;<br>reg         data\[7:0\]; |

**5\. 赋值风格**

**5.1 组合逻辑**

- 组合逻辑赋值，用assign语句或者always @(\*)块都行，两种方式灵活选，但同一个项目里要保持一致。

- 组合逻辑里面，一律用“=”阻塞赋值，跟着组合逻辑的执行规律来，能减少很多潜在的bug，避免时序混乱。

**5.2 时序逻辑**

- 时序逻辑统一用always @(posedge clk or negedge rst\_n)块，固定时钟上升沿触发、复位下降沿触发，保持时序一致，不容易出问题。

- 时序逻辑里面，一律用“<=”非阻塞赋值，符合时序逻辑的同步特性，能有效避免时序竞争冒险，代码更稳定。

**5.3 严禁混用**

- 重点提醒！同一个always块里，别同时用“=”和“<=”赋值，两种赋值方式的执行逻辑不一样，混用必出问题，要么逻辑乱，要么时序异常。

- 别在时序逻辑块里硬写复杂的组合逻辑，很容易造成时序违规，影响代码性能，把复杂组合逻辑拆出来，单独写一个组合逻辑块就好。

**6\. 状态机规范（重点）**

**6.1 只推荐：三段式状态机**

做状态机，优先选三段式结构！把状态寄存器（时序逻辑）、下一状态组合逻辑、输出逻辑（优先用时序）分开写，结构清晰、好维护，是做工程最稳妥的选择，新手也能快速上手。

给大家放一个规范的示例结构，照着写准没错：

|     |
| --- |
| // 1\. 状态定义（用localparam，不会污染全局，命名也清晰）<br>localparam S\_IDLE   = 4'd0;<br>localparam S\_DATA   = 4'd1;<br>localparam S\_END    = 4'd2;<br>// 2\. 现态 & 次态声明（分清当前状态和下一状态，不容易乱）<br>reg \[3:0\] curr\_state;<br>reg \[3:0\] next\_state;<br>// 3\. 状态转移时序逻辑（同步时序，状态切换更稳定）<br>always @(posedge clk or negedge rst\_n) begin<br>     if(!rst\_n)<br>         curr\_state <= S\_IDLE;<br>     else<br>         curr\_state <= next\_state;<br>end<br>// 4\. 下一状态组合逻辑（把状态转移条件写清楚，后续好追溯、好修改）<br>always @(\*) begin<br>     case(curr\_state)<br>         S\_IDLE: next\_state = ...;<br>         S\_DATA: next\_state = ...;<br>         default: next\_state = S\_IDLE;<br>     endcase<br>end<br>// 5\. 输出时序逻辑（时序输出，能避免毛刺，代码更稳定）<br>always @(posedge clk or negedge rst\_n) begin<br>     if(!rst\_n)<br>         out\_o <= 1'b0;<br>     else<br>         out\_o <= ...;<br>end |

**6.2 禁止**

- 别用一段式状态机写复杂逻辑！把状态转移和输出逻辑混在一起，看不懂、难调试，很容易出逻辑漏洞，后期改起来巨麻烦。

- 别把输出逻辑直接写在case语句里，还不寄存！这种写法容易产生毛刺，影响输出稳定性，不符合工程规范，多一步寄存更稳妥。

- 状态机的case语句，千万别少了default分支！万一出现异常状态，default能帮我们规避逻辑错乱，是状态机稳定运行的关键。

**7\. 时钟与复位**

**7.1 全局复位**

- 复位逻辑统一用低电平有效，这是行业常用的习惯，团队协作、适配器件都更方便，不用额外沟通。

- 复位信号就叫rst\_n，“n”后缀一看就知道是低电平有效，别起乱七八糟的名字，避免混淆。

**7.2 时钟**

- 主时钟就叫clk，简单明了，一看就知道是核心时钟，不用加多余的后缀。

- 其他辅助时钟，加个功能前缀就行，比如tx\_clk、rx\_clk，清楚哪个时钟对应哪个模块、哪个功能，多时钟场景下不会乱。

- 尽量少用门控时钟、内部生成时钟，这类时钟容易出现时序违规、时钟抖动，影响整个系统的稳定性，能不用就不用。

**8\. 注释规范**

- 模块头部一定要写注释！把模块功能、端口含义、参数配置、使用注意事项写清楚，别人一看就知道这个模块怎么用、要注意什么。

- 关键逻辑、核心算法、状态机转移过程，这些复杂的地方，一定要加注释！把你的逻辑思路写下来，后续调试、维护、迭代都省事。

- 别写废话注释！注释是用来补充说明的，显而易见的内容就别反复写了，纯属浪费时间。

不规范示例：// clk clock（纯属废话，谁都知道clk是时钟）

规范示例：// 系统时钟 50MHz（精准说明时钟属性，实用又简洁）

**9\. 参数化设计**

- 只要是能配置的参数，比如时钟频率、数据位宽，一律用parameter声明！这样代码能复用、能配置，换个项目改改参数就能用，不用重新写。

- 尽量少用\`define宏定义，容易造成跨文件污染，而且不能限制局部作用域，后续维护起来很麻烦。

- 参数名统一用“大写+下划线”，和普通信号命名区分开，一眼就能看出是参数，方便识别和修改。

|     |
| --- |
| module uart\_tx<br>#(<br>     parameter CLK\_FREQ   = 50\_000\_000,<br>     parameter BAUD\_RATE  = 115200<br>)<br>(<br>     // ports ...<br>); |

**10\. 工程里绝对禁止的写法**

- 别用多层嵌套的assign语句，逻辑绕来绕去，谁看都懵，容易写错，调试起来也巨费劲。

- 同一个信号，别在多个always块里赋值！会导致信号竞争，逻辑必出问题，这是做工程的严重错误，一定要避开。

- 组合逻辑的always块，别漏写敏感信号！漏写会产生意外锁存器，破坏组合逻辑的特性，代码功能会异常。

- 状态机别少了default分支，case语句也别漏分支！不然出现异常状态，逻辑就乱了，影响系统稳定。

- 时钟、复位信号别随便连线，也别滥用局部复位！容易造成时序混乱、复位不彻底，最后系统出故障，得不偿失。

- 别用无意义的信号命名，比如reg t1,t2,t3; 完全看不出信号是干嘛的，协作、调试的时候全是麻烦。

**11\. 给学生与新手的额外建议**

- 先学规范，再学技巧！规范学扎实了，才能打好基础，避免养成坏习惯，后期想改都难。

- 做工程的时候，代码规范比仿真正确更重要！哪怕仿真过了，代码写得乱七八糟，企业也不敢用，后续维护也麻烦。

- 不管是毕设还是学科竞赛，编码规范本身就是加分项！规范的代码，既能体现你的专业态度，也能快速获取评审老师的认可。

- 工作后会发现，工程里80%的bug，都是不规范编码搞出来的，把规范记牢，能少走很多弯路、提升不少效率。

后续我还会持续分享FPGA工程实战、项目架构设计、时序收敛技巧，还有常用模块的源码，不管是自学、做项目，还是找工作，都能用得上～ 感兴趣的同学可以关注一下，一起深耕FPGA，共同进步！

![](https://csdnimg.cn/release/blogv2/dist/pc/img/vip-limited-close-newWhite.png)

确定要放弃本次机会？


福利倒计时

_:_ _:_

![](https://csdnimg.cn/release/blogv2/dist/pc/img/vip-limited-close-roup.png)立减 ¥

普通VIP年卡可用

[立即使用](https://mall.csdn.net/vip)

[![](https://profile-avatar.csdnimg.cn/default.jpg!1)\\
\_和光同尘\_](https://blog.csdn.net/FDSFSD432)

关注关注

- ![](https://csdnimg.cn/release/blogv2/dist/pc/img/tobarThumbUpactive.png)![](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/like-active.png)![](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/like.png)
18

点赞

- ![](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/unlike-active.png)![](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/unlike.png)
踩

- ![](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/collect-active.png)![](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/collect.png)![](https://csdnimg.cn/release/blogv2/dist/pc/img/newCollectActive.png)
20




收藏







觉得还不错?

一键收藏
![](https://csdnimg.cn/release/blogv2/dist/pc/img/collectionCloseWhite.png)

- [![](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/comment.png)\\
0](https://blog.csdn.net/FDSFSD432/article/details/158067605#commentBox)
评论

- ![](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/share.png)分享




复制链接



分享到 QQ



分享到新浪微博









![](https://csdnimg.cn/release/blogv2/dist/pc/img/share/icon-wechat.png)扫一扫


- ![打赏](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/reward.png)打赏
打赏

- ![](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/more.png)


![打赏](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/reward.png)打赏![](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/report.png)举报



![](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/report.png)举报


[华为 _FPGA_ 设计规范 _VERILOG_ 约束 编程规范时序分析等全套资料.zip](https://download.csdn.net/download/guoruibin123/20096714)

07-09

[华为 _FPGA_ 设计规范 _VERILOG_ 约束 编程规范时序分析等全套资料:\\
_FPGA_ 技巧Xilinx.pdf\\
HuaWei _Verilog_ 约束.rar\\
Synplify工具使用指南(华为文档)\[1\].rar.rar\\
_Verilog_ HDL 华为入门教程.rar\\
_Verilog_ 典型电路设计 华为.rar\\
一种将异步时钟域转换成同步时钟域的方法.pdf\\
华为coding style.rar\\
华为 _FPGA_ 设计流程指南.doc\\
华为 _FPGA_ 设计规范.rar\\
华为VHDL设计风格和实现.rar\\
华为专利：一种快速无毛刺的时钟倒换方法.rar\\
华为专利：华为小数分频.rar\\
华为以太网时钟同步技术\_时钟透传技术白皮书.rar\\
华为硬件工程师手册目前最全版本.rar\\
华为面经.doc\\
华为面经.rar\\
静态时序分析与逻辑...pdf](https://download.csdn.net/download/guoruibin123/20096714)

[神州龙芯\_ _verilog_\_ _编码规范_.doc](https://download.csdn.net/download/misrig001/2295695)

04-28

[对于初学者来说，养成良好的编码习惯很有必要。因为编码风格对于综合结果以及后续维护特别是软IP的重用很重要，这是神州龙芯的编码要求，可作为参考。](https://download.csdn.net/download/misrig001/2295695)

参与评论您还未登录，请先登录后发表或查看评论

[【集成电路设计】基于HDL的 _FPGA_ _编码规范_:Actel器件硬件描述语言...](https://download.csdn.net/download/weixin_44707118/92560000)

5-19

[Actel器件硬件描述语言代码风格指南与性能优化技术 Actel器件作为集成电路设计领域中一种特殊的 _FPGA_,拥有独特的硬件描述语言(HDL) _编码规范_。在进行 _FPGA_ 设计时,HDL代码的编写质量直接影响到最终产品的性能与可靠性。因此,掌握一套高效、规范的编码风格指南对于设计人员而言至关重要。 指南中的 _编码规范_ 部分明确了代码的结构与...](https://download.csdn.net/download/weixin_44707118/92560000)

[_FPGA_ 可综合风格代码\_ _fpga_ #](https://blog.csdn.net/weixin_41113735/article/details/79872409)

5-19

[_FPGA_ 可综合风格代码 #1:当为时序逻辑建模,使用“非阻塞赋值”。 #2:当为锁存器(latch)建模,使用“非阻塞赋值”。 #3:当用always块为组合逻辑建模,使用“阻塞赋值” #4:当在同一个always块里面既为组合逻辑又为时序逻辑建模,使用“非阻塞赋值”。](https://blog.csdn.net/weixin_41113735/article/details/79872409)

[逻辑这回事（二）---- _FPGA_ 安全 _编码规范_](https://blog.csdn.net/u013056038/article/details/139203160)

[冬瓜](https://blog.csdn.net/u013056038)

05-25![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
2408


[安全编码的背景、定义\\
\\
_FPGA_ 攻击方式和攻击目的\\
\\
安全编码价值\\
\\
2020年4月，来自德国的研究者披露了一个名为“StarBleed”的漏洞，当时引起了业内一片轰动。这种漏洞存在于赛灵思的Virtex、Kintex、Artix、Spartan 等全部7系列 _FPGA_ 中。通过这个漏洞，攻击者可以同时攻破 _FPGA_ 配置文件的加密（confidentiality）和鉴权（authenticity），并由此可以随意修改 _FPGA_ 中实现的逻辑功能。攻击者通过篡改bit流实现对 _FPGA_ 加载关键配置寄存器的修改，通过蚂蚁搬](https://blog.csdn.net/u013056038/article/details/139203160)

[_FPGA_ _开发_ 必备：规范编写代码！](https://blog.csdn.net/2301_78484069/article/details/131629672)

[2301\_78484069的博客](https://blog.csdn.net/2301_78484069)

07-10![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
647


[例如，当我们使用一个信号来表示LED灯的开或关时，我们可以使用“led\_on”或“led\_off”等名称，而不是使用“a”或“b”等单一字母。最后，我们需要强调的是，在 _FPGA_ _开发_ 中编写规范的代码是提高设计效率和可维护性的重要手段。因此，我们应该在代码中添加清晰明了的注释，例如在关键变量和函数上方添加简短的注释。在代码编写过程中，我们应该遵循适当的缩进和空格规范。在 _FPGA_ _开发_ 中，编写规范的代码是至关重要的，因为它不仅可以提高代码的可读性和可维护性，还能缩短设计周期和提高生产效率。](https://blog.csdn.net/2301_78484069/article/details/131629672)

[_FPGA_ 学习笔记之数字电路篇\_ _fpga_ 数字电路](https://blog.csdn.net/Archar_Saber/article/details/81606317)

5-29

[_FPGA_ 学习笔记之数字电路篇 本文介绍了数字电路的基础知识,包括数字电路与模拟电路的区别、数制与编码、逻辑代数及 _Verilog_ 语言的基本语法。详细讲解了与门电路的 _Verilog_ 描述方法,并探讨了组合逻辑电路的分析与设计过程,包括真值表的使用、逻辑表达式的化简、逻辑图的绘制,以及竞争和冒险现象的识别与消除。](https://blog.csdn.net/Archar_Saber/article/details/81606317)

[每天一点 _Verilog_,《高级 _FPGA_ 设计》学习笔记:综合编码2\_ _fpga_ ctrl\[2\]是...](https://blog.csdn.net/teead/article/details/6196188)

5-16

[每天一点 _Verilog_,《高级 _FPGA_ 设计》学习笔记:综合编码2 当判决树有特权编码时应该利用if/else结构。 另一方面,case结构常常利用在所有条件互不相容的情况。为了在 _verilog_ 中实现完全相同的功能,一个case语句可以利用。 case(1) ctrl\[0\]: rout<=in\[0\]; ctrl\[1\]: rout<=in\[1\];...](https://blog.csdn.net/teead/article/details/6196188)

[华为 _FPGA_ _开发_ 实战： _Verilog_ 高效 _编码规范_ 与最佳实践\\
\\
最新发布](https://blog.csdn.net/weixin_29159711/article/details/158711995)

[weixin\_29159711的博客](https://blog.csdn.net/weixin_29159711)

03-06![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
66


[本文系统阐述了华为 _FPGA_ _开发_ 中 _Verilog_ 高效 _编码规范_ 与最佳实践，旨在提升代码可读性、可维护性与综合质量。内容涵盖从命名规则、模块划分到状态机设计等核心要点，帮助 _开发_ 者从“能跑”到“跑得好”，打造稳定可靠的硬件设计，是 _FPGA_ 工程师提升代码质量的必备指南。](https://blog.csdn.net/weixin_29159711/article/details/158711995)

[_FPGA_ 入门 —— 代码规范与模块结构](https://ppqppl.blog.csdn.net/article/details/129434751)

[ppqppl的博客](https://blog.csdn.net/m0_59161987)

03-09![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
1488


[_FPGA_ 入门 —— 代码规范与模块结构\\
不可综合或不推荐使用的代码\\
\\
代码\\
要求\\
\\
initial\\
严谨在设计中使用，只能在测试文件中使用\\
\\
task/function\\
不推荐在设计中使用，在测试文件中使用\\
\\
for\\
在设计中、测试文件中均可以使用，但在设计中多数会将其用错，所以建议在初期设计时不使用，熟练后按规范使用\\
\\
while/repeat/forever\\
严禁在设计文件...](https://ppqppl.blog.csdn.net/article/details/129434751)

[VHDL编码与XILINX _FPGA_ 设计 _开发_ 规范要点 资源](https://download.csdn.net/download/dabbler_zhu/6418941)

5-26

[xilinx _FPGA_ UG901 浏览:5 System _Verilog_:IEEE标准System _Verilog_ 统一硬件设计规范,以及验证语言(IEEE Std 1800-2012) _Verilog_:IEEE _Verilog_ 硬件描述语言标准(IEEE Std 1364-2005)VHDL:IEEEVHDL语言标准(IEEE Std 1076-2002)VHDL... EDA/PLD中的 _FPGA_ 的学习及注意事项 ...](https://download.csdn.net/download/dabbler_zhu/6418941)

[_fpga_ 代码编写规范](https://blog.csdn.net/weixin_43802726/article/details/143982947)

[weixin\_43802726的博客](https://blog.csdn.net/weixin_43802726)

11-23![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
2971


[应用HDL设计数字系统时，清晰、规范的描述代码是确保模块功能与性能的关键因素之一。优秀HDL代码的编写目标是： (1) 简洁规范，具有良好的的可阅读性和可维护性，便于分析与调试；(2) 紧贴硬件，确保模块功能正确，并且易于综合出性能优良的电路；(3) 结构清晰，具有良好的可重用性，能够提高设计效率。](https://blog.csdn.net/weixin_43802726/article/details/143982947)

[_FPGA_ 编程规范](https://blog.csdn.net/weixin_45372778/article/details/134004376)

[柳柳的博客](https://blog.csdn.net/weixin_45372778)

10-24![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
1813


[每个工程师的代码风格各不一样，当工程较大，面临需要多个工程师共同完成，或者面临当工程师离职后代码交接等问题。若代码规范未统一，阅读代码将是非常吃力的。下文是作者从各大论坛、网站、书籍收集整理的 _Verilog_ 编程规范。1．端口定义按照功能块划分，每个功能块中按照输入、输出、双向的顺序，各个功能块之间要有空行或注释为间隔；2．每行声明一个端口并有注释，注释在同一行；3．用下述顺序声明端口，不同类型的端口声明使用一个空行间隔；](https://blog.csdn.net/weixin_45372778/article/details/134004376)

[_FPGA_ 文档规范.Xilinx编码规则-1](https://blog.csdn.net/weixin_42087978/article/details/133758167)

[weixin\_42087978的博客](https://blog.csdn.net/weixin_42087978)

10-10![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
411


[学习 _FPGA_，一个好的编码风格非常重要，不同的平台，不同的公司对 _编码规范_ 都有自己的要求，狼哥今天来和大家一起看看xilinx平台推荐的编码规则。和固定移位寄存器比起来，可变移位寄存器多了个数据选择器，可以根据选择值选择对应移位次数的数据进行输出。2.FDPE：带使能功能的异步置位D触发器；3.FDSE：带使能功能的同步置位D触发器；](https://blog.csdn.net/weixin_42087978/article/details/133758167)

[_FPGA_ _编码规范_](https://blog.csdn.net/weixin_37226977/article/details/153684811)

[weixin\_37226977的博客](https://blog.csdn.net/weixin_37226977)

10-21![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
213


[模块之间的接口信号，命名分为两个部分，第一部分表明数据方向，其中数据发出方在前，数据接收方在后，第二部分为数据名称：若某个信号从一个模块传递到多个模块，其命名应视信号的主要路径而定，在不同的子模块中尽量采用相同的名字；这样做的目的是为了能更有效的综合，因为在顶层模块中出现中间逻辑，综合工具不能把子模块中的逻辑综合到最优。5．时钟信号必须连接到全局时钟管脚上，禁止用计数器分频后的信号做其他模块的时钟，而要用改成时钟使能的方式，否则这种时钟满天飞的方式对设计的可靠性极为不利，也大大增加了静态时序分析的复杂性；](https://blog.csdn.net/weixin_37226977/article/details/153684811)

[_Verilog_ _编码规范_](https://blog.csdn.net/hdu_ding/article/details/135119501)

[hdu\_ding的博客](https://blog.csdn.net/hdu_ding)

12-20![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
1423


[用有意义的名字，如地址。](https://blog.csdn.net/hdu_ding/article/details/135119501)

[_FPGA_ 代码设计规范一些探讨](https://blog.csdn.net/wandou0511/article/details/127706826)

[wandou0511的博客](https://blog.csdn.net/wandou0511)

11-05![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
4165


[可事实上却不是这样的，当项目复杂度越来越高，代码都需要经过多轮的审核等才能被应用在项目工程里，如果大家写得代码都非常复杂繁琐，那么后期带来重用的工作量是非常巨大的，也非常不容易理解当事人的想法，所以请大家编程的时候，尽量去使用常见的基本语法，也有利于工具的资源优化，对于复杂功能的模块理清楚逻辑，可以先用前面学习到的TimeGen绘制各个信号的波形图，分析明白后再动手编程，从而减少了语句之间的耦合带来程序设计上的二义性。请多去对需求分析，多去画设计图纸，前期增加方案时间，后期减少返工时间。](https://blog.csdn.net/wandou0511/article/details/127706826)

[华为 _FPGA_ 设计规范（ _Verilog_\_HDL）](https://download.csdn.net/download/yxyncut/10330173)

04-06

[华为内部 _FPGA_ 源代码设计时所需遵循的设计规范，培养好的设计方法。](https://download.csdn.net/download/yxyncut/10330173)

[_verilog_ _编码规范_ 华为内部.PDF](https://download.csdn.net/download/xfeichen2/2284362)

04-25

[_verilog_ _编码规范_ 华为内部.PDF，要想学好 _VERILOG_，还要好好看一下吧](https://download.csdn.net/download/xfeichen2/2284362)

[SOC平台 _verilog_ 代码风格规范V0.4.pdf](https://download.csdn.net/download/weixin_39840924/11419674)

07-23

[RTL 是指 Register Transfer Level，即寄存器传输级，代码显式定义每一个 DFF，组合 电路描述每个 DFF 之间的信号传输过程。当前的主流工具对 RTL 级的综合、优化及仿真 非常成熟。 不建议采用行为级甚至更高级的语言来描述硬件，代码的可控性，可跟踪性及可移植 性难以保证。](https://download.csdn.net/download/weixin_39840924/11419674)

[_FPGA_ 知识汇集-值得收藏的 _FPGA_ 代码命名规范？](https://blog.csdn.net/mochenbaobei/article/details/122921504)

[mochenbaobei的博客](https://blog.csdn.net/mochenbaobei)

02-14![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
2376


[命名规范\\
\\
随者 _FPGA_ 设计的日益复杂，设计实践、方法和流程逐渐成为重要的成功因素。良好的设计能有效影响 _FPGA_ 设计的性能和逻辑利用，使系统可靠性显著提高，产品可以更快投入到市场。相反，不良的设计可能会导致系统成本较高、性能较低，错过了项目进度，导致设计的不可靠。\\
\\
持续关注，本篇及随后会提供一些 _Verilog_ 命名、编码风格及 _FPGA_ 综合的规则与准则。其指导原则是改善代码的可读性和可移植性，促进代码在不同项目中的复用。\\
\\
为了提高有效性，规则和准则必须建立正式文档并分发给整个设计团队，还要定期检查代码和审查](https://blog.csdn.net/mochenbaobei/article/details/122921504)

[00 大厂的 _verilog_ 代码风格与规范](https://blog.csdn.net/qq_43244515/article/details/124155704)

[毕淑敏曾说过：“我不相信命运，我只相信自己的手；我不相信手掌上的纹路，但我相信手指加上手掌的力量”。在这个快节奏的社会，只有自己能力不足才会被卷，踏踏实实沉下心来学一些技术，及时记录，方便以后复盘。](https://blog.csdn.net/qq_43244515)

04-13![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
3541


[虚拟机：VMware-workstation-full-14.0.0.24051\\
环 境：ubuntu 18.04.1\\
\\
所有的信号名、变量名和端口名都用小写，这样做是为了和业界的习惯保持一致；常量名和用户定义的类型则用大写。\\
使用有意义的信号名、端口名、函数名和参数名。例如模块端口名用 a2b\_data、a2c\_ctrl，而不是直接用 data1、ctrl1 等。\\
信号名长度不要太长。对于超过 28 个字符的信号名，有些 EDA 工具不能够识别，太长的信号名也不容易记忆。因此，在描述清楚的前提下，尽可能](https://blog.csdn.net/qq_43244515/article/details/124155704)

[_FPGA_ 学习笔记（四）——一些代码设计规范](https://blog.csdn.net/qq_33833073/article/details/100049840)

[buaalzm](https://blog.csdn.net/qq_33833073)

08-24![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
504


[时序逻辑和组合逻辑的写法\\
\\
时序逻辑的敏感信号必须是（posedge clk or negedge rst\_n）\\
组合逻辑的写法always@(\*)\\
值允许使用always，不用assign\\
一个always里面只允许设计一个输出，但可以有多个输入。\\
注意要点：a.组合逻辑不能作为时钟、复位信号；b.组合逻辑一定要写else，避免生成锁存器。\\
\\
begin end以及信号的对齐\\
\\
always、条...](https://blog.csdn.net/qq_33833073/article/details/100049840)

[_FPGA_- _Verilog_ 的书写规范格式](https://vuko-wxh.blog.csdn.net/article/details/83310763)

[Vuko\_Coding Zone](https://blog.csdn.net/weixin_41445387)

10-23![](https://csdnimg.cn/release/blogv2/dist/pc/img/readCountWhite.png)
3468


[代码规范有利于在项目和工程中的维护，养成习惯对后期的工作学习会有很大的帮助！\\
\\
下面就看下各个情况的规范书写格式是什么\\
\\
1.时序逻辑的规范写法：\\
\\
always @(posedge clk or negedge rst\_n)begin \\
if(rst\_n==1'b0)begin\\
tmp\_init&lt;=1'b0;\\
end...](https://vuko-wxh.blog.csdn.net/article/details/83310763)

- [关于我们](https://www.csdn.net/company/index.html#about)
- [招贤纳士](https://www.csdn.net/company/index.html#recruit)
- [商务合作](https://fsc-p05.txscrm.com/T8PN8SFII7W)
- [寻求报道](https://marketing.csdn.net/questions/Q2202181748074189855)
- ![](https://g.csdnimg.cn/common/csdn-footer/images/tel.png)400-660-0108
- ![](https://g.csdnimg.cn/common/csdn-footer/images/email.png)[kefu@csdn.net](mailto:webmaster@csdn.net)
- ![](https://g.csdnimg.cn/common/csdn-footer/images/cs.png)[在线客服](https://csdn.s2.udesk.cn/im_client/?web_plugin_id=29181)
- 工作时间 8:30-22:00


- ![](https://g.csdnimg.cn/common/csdn-footer/images/badge.png)[公安备案号11010502030143](http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=11010502030143)
- [京ICP备19004658号](http://beian.miit.gov.cn/publish/query/indexFirst.action)
- [京网文〔2020〕1039-165号](https://csdnimg.cn/release/live_fe/culture_license.png)
- [经营性网站备案信息](https://csdnimg.cn/cdn/content-toolbar/csdn-ICP.png)
- [北京互联网违法和不良信息举报中心](http://www.bjjubao.org/)
- [家长监护](https://download.csdn.net/tutelage/home)
- [网络110报警服务](https://cyberpolice.mps.gov.cn/)
- [中国互联网举报中心](http://www.12377.cn/)
- [Chrome商店下载](https://chrome.google.com/webstore/detail/csdn%E5%BC%80%E5%8F%91%E8%80%85%E5%8A%A9%E6%89%8B/kfkdboecolemdjodhmhmcibjocfopejo?hl=zh-CN)
- [账号管理规范](https://blog.csdn.net/blogdevteam/article/details/126135357)
- [版权与免责声明](https://www.csdn.net/company/index.html#statement)
- [版权申诉](https://blog.csdn.net/blogdevteam/article/details/90369522)
- [出版物许可证](https://img-home.csdnimg.cn/images/20250103023206.png)
- [营业执照](https://img-home.csdnimg.cn/images/20250103023201.png)
- ©1999-2026北京创新乐知网络技术有限公司

登录后您可以享受以下权益：

- ![](<Base64-Image-Removed>)免费复制代码
- ![](<Base64-Image-Removed>)和博主大V互动
- ![](<Base64-Image-Removed>)下载海量资源
- ![](<Base64-Image-Removed>)发动态/写文章/加入社区

×立即登录

评论![](https://csdnimg.cn/release/blogv2/dist/pc/img/closeBt.png)

![](https://csdnimg.cn/release/blogv2/dist/pc/img/commentArrowLeftWhite.png)被折叠的  条评论
[为什么被折叠?](https://blogdev.blog.csdn.net/article/details/122245662) [![](https://csdnimg.cn/release/blogv2/dist/pc/img/iconPark.png)到【灌水乐园】发言](https://bbs.csdn.net/forums/FreeZone)

查看更多评论![](https://csdnimg.cn/release/blogv2/dist/pc/img/commentArrowDownWhite.png)

添加红包


祝福语

请填写红包祝福语或标题

红包数量

个

红包个数最小为10个

红包总金额

元

红包金额最低5元

余额支付

当前余额3.43元
[前往充值 >](https://i.csdn.net/#/wallet/balance/recharge)

需支付：10.00元


取消确定

打赏作者![](https://csdnimg.cn/release/blogv2/dist/pc/img/closeBt.png)

[![](https://profile-avatar.csdnimg.cn/default.jpg!1)](https://blog.csdn.net/FDSFSD432)

\_和光同尘\_

你的鼓励将是我创作的最大动力

¥1¥2¥4¥6¥10¥20

扫码支付：¥1

![](https://csdnimg.cn/release/blogv2/dist/pc/img/pay-time-out.png)获取中

![](https://csdnimg.cn/release/blogv2/dist/pc/img/newWeiXin.png)![](https://csdnimg.cn/release/blogv2/dist/pc/img/newZhiFuBao.png)扫码支付

您的余额不足，请更换扫码支付或 [充值](https://i.csdn.net/#/wallet/balance/recharge?utm_source=RewardVip)

打赏作者

实付元

使用余额支付

![](https://csdnimg.cn/release/blogv2/dist/pc/img/pay-time-out.png)点击重新获取

![](https://csdnimg.cn/release/blogv2/dist/pc/img/weixin.png)![](https://csdnimg.cn/release/blogv2/dist/pc/img/zhifubao.png)![](https://csdnimg.cn/release/blogv2/dist/pc/img/jingdong.png)扫码支付

钱包余额0

![](https://csdnimg.cn/release/blogv2/dist/pc/img/pay-help.png)

抵扣说明：

1.余额是钱包充值的虚拟货币，按照1:1的比例进行支付金额的抵扣。

2.余额无法直接购买下载，可以购买VIP、付费专栏及课程。

[![](https://csdnimg.cn/release/blogv2/dist/pc/img/recharge.png)余额充值](https://i.csdn.net/#/wallet/balance/recharge)

![](https://blog.csdn.net/FDSFSD432/article/details/158067605)

确定取消![](https://csdnimg.cn/release/blogv2/dist/pc/img/closeBt.png)

举报

![](https://csdnimg.cn/release/blogv2/dist/pc/img/closeBlack.png)

选择你想要举报的内容（必选）

- 内容涉黄
- 政治相关
- 内容抄袭
- 涉嫌广告
- 内容侵权
- 侮辱谩骂
- 样式问题
- 其他

原文链接（必填）

请选择具体原因（必选）

- 包含不实信息
- 涉及个人隐私

请选择具体原因（必选）

- 侮辱谩骂
- 诽谤

请选择具体原因（必选）

- 搬家样式
- 博文样式

补充说明（选填）

取消

确定

[![](https://csdnimg.cn/release/blogv2/dist/pc/img/toolbar/Group.png)点击体验\\
\\
DeepSeekR1满血版](https://ai.csdn.net/chat?utm_source=cknow_pc_blogdetail&spm=1001.2101.3001.10583)![](https://g.csdnimg.cn/side-toolbar/3.6/images/mobile.png)

下载APP

![程序员都在用的中文IT技术交流社区](https://g.csdnimg.cn/side-toolbar/3.6/images/qr_app.png)

程序员都在用的中文IT技术交流社区

公众号

![专业的中文 IT 技术社区，与千万技术人共成长](https://g.csdnimg.cn/side-toolbar/3.6/images/qr_wechat.png)

专业的中文 IT 技术社区，与千万技术人共成长

视频号

![关注【CSDN】视频号，行业资讯、技术分享精彩不断，直播好礼送不停！](https://g.csdnimg.cn/side-toolbar/3.6/images/qr_video.png)

关注【CSDN】视频号，行业资讯、技术分享精彩不断，直播好礼送不停！

![](https://g.csdnimg.cn/side-toolbar/3.6/images/customer.png)客服

新手引导

![](https://g.csdnimg.cn/side-toolbar/3.6/images/totop.png)返回顶部