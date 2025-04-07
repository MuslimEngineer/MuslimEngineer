import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';

class IslamicInfoScreen extends StatefulWidget {
  const IslamicInfoScreen({Key? key}) : super(key: key);

  @override
  State<IslamicInfoScreen> createState() => _IslamicInfoScreenState();
}

class _IslamicInfoScreenState extends State<IslamicInfoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // متغيرات للأذكار
  List<Map<String, dynamic>> _athkarList = [];
  bool _isLoadingAthkar = true;

  // متغيرات للأحاديث
  List<Map<String, dynamic>> _hadithsList = [];
  bool _isLoadingHadiths = true;

  // متغيرات لأدعية القرآن
  List<Map<String, dynamic>> _quranDuaList = [];
  bool _isLoadingQuranDua = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // تحميل الأذكار من قاعدة البيانات
    _loadAthkarFromDatabase();

    // تحميل الأحاديث من قاعدة البيانات
    _loadHadithsFromDatabase();

    // تحميل أدعية القرآن من قاعدة البيانات
    _loadQuranDuaFromDatabase();
  }

  // تحميل الأذكار من قاعدة البيانات
  Future<void> _loadAthkarFromDatabase() async {
    setState(() {
      _isLoadingAthkar = true;
    });

    try {
      final athkarList = await DatabaseHelper.instance.getAllAthkar();

      setState(() {
        _athkarList = athkarList;
        _isLoadingAthkar = false;
      });
    } catch (e) {
      print('خطأ في تحميل الأذكار: $e');
      setState(() {
        _isLoadingAthkar = false;
      });
    }
  }

  // تحميل الأحاديث من قاعدة البيانات
  Future<void> _loadHadithsFromDatabase() async {
    setState(() {
      _isLoadingHadiths = true;
    });

    try {
      final hadithsList = await DatabaseHelper.instance.getAllHadiths();

      setState(() {
        _hadithsList = hadithsList;
        _isLoadingHadiths = false;
      });
    } catch (e) {
      print('خطأ في تحميل الأحاديث: $e');
      setState(() {
        _isLoadingHadiths = false;
      });
    }
  }

  // تحميل أدعية القرآن من قاعدة البيانات
  Future<void> _loadQuranDuaFromDatabase() async {
    setState(() {
      _isLoadingQuranDua = true;
    });

    try {
      final quranDuaList = await DatabaseHelper.instance.getAllQuranDuas();

      setState(() {
        _quranDuaList = quranDuaList;
        _isLoadingQuranDua = false;
      });
    } catch (e) {
      print('خطأ في تحميل أدعية القرآن: $e');
      setState(() {
        _isLoadingQuranDua = false;
      });
    }
  }

  // إضافة ذكر جديد
  Future<void> _addNewAthkar() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة ذكر جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                  labelText: 'العنوان', hintText: 'مثال: أذكار الصباح'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                  labelText: 'محتوى الذكر', hintText: 'أدخل الذكر هنا'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                await DatabaseHelper.instance.addAthkar(
                    titleController.text.trim(), contentController.text.trim());
                Navigator.pop(context, true);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadAthkarFromDatabase();
    }
  }

  // تعديل ذكر
  Future<void> _editAthkar(int id, String title, String content) async {
    final titleController = TextEditingController(text: title);
    final contentController = TextEditingController(text: content);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الذكر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'العنوان',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'المحتوى',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  contentController.text.isNotEmpty) {
                await DatabaseHelper.instance.updateAthkar(id,
                    titleController.text.trim(), contentController.text.trim());
                Navigator.pop(context, true);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadAthkarFromDatabase();
    }
  }

  // حذف ذكر
  Future<void> _deleteAthkar(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الذكر؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteAthkar(id);
      _loadAthkarFromDatabase();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الذكر بنجاح')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المعلومات الإسلامية والأذكار'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'المعلومات الإسلامية'),
            Tab(text: 'الأذكار'),
            Tab(text: 'أدعية من القرآن'),
            Tab(text: 'الأحاديث'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildIslamicInfoTab(),
          _buildAzkarTab(),
          _buildQuranDuaTab(),
          _buildHadithTab(),
        ],
      ),
    );
  }

  // إضافة تبويب معلومات إسلامية بسيط بدلاً من أوقات الصلاة
  Widget _buildIslamicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'معلومات إسلامية',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'هذا القسم مخصص للمعلومات الإسلامية المفيدة. يمكن إضافة محتوى متنوع هنا مثل أحكام فقهية، معلومات عن السيرة النبوية، أو فضائل الأعمال.',
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.nightlight_round, color: Colors.black),
                      const SizedBox(width: 8),
                      const Text(
                        'قيام الليل والتهجد',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'قيام الليل هي عبادة يؤديها المسلم في ليله، حيث يقف بين يدي الله للصلاة، تاليًا آياته، وداعيًا، وطالبًا لما يتمنى من أمور دينه ودنياه. يمكن أداؤها في أي وقت بعد صلاة العشاء وحتى صلاة الفجر.\n\n'
                    'فهي عبادة عظيمة ومستحبة في الإسلام، وقد كان النبي محمد صلى الله عليه وسلم يحافظ عليها، ويحثّ أصحابه على أدائها.\n\n'
                    'وأفضل وقت لأدائها هو الثلث الأخير من الليل، وقد ثبت عنه صلى الله عليه وسلم في الصحيحين من حديث أبي هريرة رضي الله عنه قال: قال رسول الله صلى الله عليه وسلم: "ينزل ربنا تبارك وتعالى كل ليلة إلى السماء الدنيا حين يبقى ثلث الليل الأخير، فيقول: من يدعوني فأستجيب له، من يسألني فأعطيه، من يستغفرني فأغفر له."\n\n'
                    'ومنها صلاة التهجد: وهي ما يُصلى بعد النوم.\n\n'
                    'وصلاة التراويح: في رمضان.\n\n'
                    'وقد جاء في فضلها في محكم التنزيل، أن الله سبحانه وتعالى قال:\n'
                    '"ومن الليل فتهجد به نافلة لك عسى أن يبعثك ربك مقامًا محمودًا" (سورة الإسراء: 79)\n\n'
                    'وقال سبحانه:\n'
                    '"كانوا قليلا من الليل ما يهجعون، وبالأسحار هم يستغفرون" (سورة الذاريات: 17-18)\n\n'
                    'وقال النبي ﷺ:\n'
                    '"أفضل الصلاة بعد الفريضة صلاة الليل" (رواه مسلم)\n\n'
                    'ويُقام الليل بركعتين ركعتين، قدر ما يفتح الله للمسلم وييسّر، فهي ليست لها عدد محدد، ثم تُختم بركعة واحدة (الوتر).\n\n'
                    'فلو لم يستطع المسلم القيام كثيرًا، فحسبه ركعتان في الليل بنيّة قيام الليل. المهم أن تكون النية خالصة لله، وأن يحرص الإنسان على الاستمرار حتى لو كان العمل قليلاً. فنرجو بذلك القبول من الله سبحانه وتعالى والأجر العظيم.',
                    style: TextStyle(fontSize: 16, height: 1.8),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mosque, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'الوتر',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'صلاة الوتر من أعظم القربات إلى الله تعالى، حتى رأى بعض العلماء – وهم الحنفية – أنها من الواجبات، ولكن الصحيح أنها من السنن المؤكدة التي ينبغي على المسلم المحافظة عليها وعدم تركها.\n\n'
                    'وقت صلاة الوتر يبدأ من حين أن يصلي الإنسان العشاء، ولو كانت مجموعة إلى المغرب تقديماً إلى طلوع الفجر، لقوله صلى الله عليه وسلم: (إن الله قد أمدكم بصلاةٍ وهي الوتر، جعله الله لكم فيما بين صلاة العشاء إلى أن يطلع الفجر) رواه الترمذي، وصححه الألباني في "صحيح الترمذي".\n\n'
                    'هل الأفضل تقديم صلاة الوتر أول الوقت أو تأخيرها؟ دلت السنة على أن من طمع أن يقوم من آخر الليل فالأفضل تأخيره، لأن صلاة آخر الليل أفضل، وهي مشهودة، ومن خاف أن لا يقوم آخر الليل أوتر قبل أن ينام، لحديث جابر رضي الله عنه قال: قال رسول الله صلى الله عليه وسلم: (من خاف أن لا يقوم من آخر الليل فليوتر أوله، ومن طمع أن يقوم آخره فليوتر آخر الليل، فإن صلاة آخر الليل مشهودة وذلك أفضل) رواه مسلم.\n\n'
                    'كيفية صلاة الوتر: أقل الوتر ركعة، لقول النبي صلى الله عليه وسلم: (الوتر ركعة من آخر الليل) رواه مسلم، وقوله صلى الله عليه وسلم: (صلاة الليل مثنى مثنى، فإذا خشي أحدكم الصبح صلى ركعة واحدة توتر له ما قد صلى) رواه البخاري.\n'
                    'فإذا اقتصر الإنسان عليها فقد أتى بالسنة... ويجوز الوتر بثلاث، وبخمس، وبسبع، وبتسع.\n'
                    'فعن أم سلمة رضي الله عنها قالت: (كان النبي صلى الله عليه وسلم يوتر بخمس وبسبع، ولا يفصل بينهن بسلام ولا كلام) رواه أحمد.\n\n'
                    'وإذا أوتر بتسع فإنها تكون متصلة ويجلس للتشهد في الثامنة، ثم يقوم ولا يسلم ويتشهد في التاسعة ويسلم، لما روته عائشة رضي الله عنها كما في مسلم: (أن النبي صلى الله عليه وسلم كان يصلي تسع ركعات لا يجلس فيها إلا في الثامنة، فيذكر الله ويحمده ويدعوه، ثم ينهض ولا يسلم، ثم يقوم فيصلي التاسعة، ثم يقعد فيذكر الله ويحمده ويدعوه، ثم يسلم تسليماً يسمعنا).\n\n'
                    'وإن أوتر بإحدى عشرة، فإنه يسلم من كل ركعتين، ويوتر منها بواحدة.\n\n'
                    'أدنى الكمال في صلاة الوتر: أدنى الكمال في الوتر أن يصلي ركعتين ويسلم، ثم يأتي بواحدة ويسلم، ويجوز أن يجعلها بسلام واحد، لكن بتشهد واحد لا بتشهدين.\n'
                    'فكل هذه الصفات في صلاة الوتر قد جاءت بها السنة، والأكمل أن لا يلتزم المسلم صفة واحدة، بل يأتي بهذه الصفة مرة وبغيرها أخرى.. وهكذا، حتى يكون فعل السنن جميعها.\n\n'
                    'والله تعالى أعلم.',
                    style: TextStyle(fontSize: 16, height: 1.8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======== قسم الأذكار ========
  Widget _buildAzkarTab() {
    if (_isLoadingAthkar) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_athkarList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('لا توجد أذكار محفوظة'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addNewAthkar,
              icon: const Icon(Icons.add),
              label: const Text('إضافة ذكر جديد'),
            ),
          ],
        ),
      );
    }

    // تجميع الأذكار حسب العنوان
    final Map<String, List<Map<String, dynamic>>> groupedAthkar = {};

    for (var athkar in _athkarList) {
      final title = athkar['title'] as String;

      if (!groupedAthkar.containsKey(title)) {
        groupedAthkar[title] = [];
      }

      groupedAthkar[title]!.add(athkar);
    }

    return Stack(
      children: [
        ListView.builder(
          itemCount: groupedAthkar.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final title = groupedAthkar.keys.elementAt(index);
            final athkars = groupedAthkar[title]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                children: [
                  ...athkars.map<Widget>((athkar) {
                    return ListTile(
                      title: Text(athkar['content']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editAthkar(athkar['id'],
                                athkar['title'], athkar['content']),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.content_copy),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: athkar['content']));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ الذكر'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            tooltip: 'نسخ',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAthkar(athkar['id']),
                            tooltip: 'حذف',
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _addNewAthkar,
            child: const Icon(Icons.add),
            tooltip: 'إضافة ذكر جديد',
          ),
        ),
      ],
    );
  }

  // ======== قسم أدعية من القرآن ========
  Widget _buildQuranDuaTab() {
    if (_isLoadingQuranDua) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_quranDuaList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('لا توجد أدعية قرآنية محفوظة'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addNewQuranDua,
              icon: const Icon(Icons.add),
              label: const Text('إضافة دعاء قرآني جديد'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _quranDuaList.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final dua = _quranDuaList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.teal.shade200, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    dua['theme'],
                    style: TextStyle(
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  dua['text'],
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.teal.shade100),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dua['source'],
                      style: TextStyle(
                        color: Colors.teal.shade700,
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editQuranDua(dua['id'], dua['text'],
                              dua['source'], dua['theme']),
                          tooltip: 'تعديل',
                        ),
                        IconButton(
                          icon: const Icon(Icons.content_copy,
                              color: Colors.teal),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: dua['text']));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم نسخ الدعاء'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          tooltip: 'نسخ',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteQuranDua(dua['id']),
                          tooltip: 'حذف',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // إضافة دعاء قرآني جديد
  Future<void> _addNewQuranDua() async {
    final textController = TextEditingController();
    final sourceController = TextEditingController();
    final themeController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دعاء قرآني جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                    labelText: 'نص الدعاء',
                    hintText: 'أدخل نص الدعاء من القرآن'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sourceController,
                decoration: const InputDecoration(
                    labelText: 'المصدر', hintText: 'مثال: سورة البقرة: 201'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: themeController,
                decoration: const InputDecoration(
                    labelText: 'الموضوع', hintText: 'مثال: دعاء طلب الهداية'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.isNotEmpty &&
                  sourceController.text.isNotEmpty &&
                  themeController.text.isNotEmpty) {
                await DatabaseHelper.instance.addQuranDua(
                    textController.text.trim(),
                    sourceController.text.trim(),
                    themeController.text.trim());
                Navigator.pop(context, true);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadQuranDuaFromDatabase();
    }
  }

  // تعديل دعاء قرآني
  Future<void> _editQuranDua(
      int id, String text, String source, String theme) async {
    final textController = TextEditingController(text: text);
    final sourceController = TextEditingController(text: source);
    final themeController = TextEditingController(text: theme);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الدعاء القرآني'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'نص الدعاء',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sourceController,
                decoration: const InputDecoration(
                  labelText: 'المصدر',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: themeController,
                decoration: const InputDecoration(
                  labelText: 'الموضوع',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.isNotEmpty &&
                  sourceController.text.isNotEmpty &&
                  themeController.text.isNotEmpty) {
                await DatabaseHelper.instance.updateQuranDua(
                    id,
                    textController.text.trim(),
                    sourceController.text.trim(),
                    themeController.text.trim());
                Navigator.pop(context, true);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadQuranDuaFromDatabase();
    }
  }

  // حذف دعاء قرآني
  Future<void> _deleteQuranDua(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الدعاء القرآني؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteQuranDua(id);
      _loadQuranDuaFromDatabase();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الدعاء القرآني بنجاح')),
      );
    }
  }

  // ======== قسم الأحاديث ========
  Widget _buildHadithTab() {
    if (_isLoadingHadiths) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hadithsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('لا توجد أحاديث محفوظة'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addNewHadith,
              icon: const Icon(Icons.add),
              label: const Text('إضافة حديث جديد'),
            ),
          ],
        ),
      );
    }

    // تجميع الأحاديث حسب الموضوع
    final Map<String, List<Map<String, dynamic>>> groupedHadiths = {};

    for (var hadith in _hadithsList) {
      final topic = hadith['topic'] as String;

      if (!groupedHadiths.containsKey(topic)) {
        groupedHadiths[topic] = [];
      }

      groupedHadiths[topic]!.add(hadith);
    }

    return Stack(
      children: [
        ListView.builder(
          itemCount: groupedHadiths.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final topic = groupedHadiths.keys.elementAt(index);
            final hadiths = groupedHadiths[topic]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                title: Text(
                  topic,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                children: [
                  ...hadiths.map<Widget>((hadith) {
                    return ListTile(
                      title: Text(hadith['text']),
                      subtitle: Text(
                        hadith['narrator'],
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editHadith(
                                hadith['id'],
                                hadith['text'],
                                hadith['narrator'],
                                hadith['topic']),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            icon: const Icon(Icons.content_copy),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: hadith['text']));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ الحديث'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                            tooltip: 'نسخ',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteHadith(hadith['id']),
                            tooltip: 'حذف',
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _addNewHadith,
            child: const Icon(Icons.add),
            tooltip: 'إضافة حديث جديد',
          ),
        ),
      ],
    );
  }

  // إضافة حديث جديد
  Future<void> _addNewHadith() async {
    final textController = TextEditingController();
    final narratorController = TextEditingController();
    final topicController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة حديث جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                    labelText: 'نص الحديث', hintText: 'أدخل نص الحديث'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: narratorController,
                decoration: const InputDecoration(
                    labelText: 'الراوي', hintText: 'مثال: متفق عليه'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: topicController,
                decoration: const InputDecoration(
                    labelText: 'الموضوع', hintText: 'مثال: الإيمان'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.isNotEmpty &&
                  narratorController.text.isNotEmpty &&
                  topicController.text.isNotEmpty) {
                await DatabaseHelper.instance.addHadith(
                    textController.text.trim(),
                    narratorController.text.trim(),
                    topicController.text.trim());
                Navigator.pop(context, true);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadHadithsFromDatabase();
    }
  }

  // تعديل حديث
  Future<void> _editHadith(
      int id, String text, String narrator, String topic) async {
    final textController = TextEditingController(text: text);
    final narratorController = TextEditingController(text: narrator);
    final topicController = TextEditingController(text: topic);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل الحديث'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'نص الحديث',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: narratorController,
                decoration: const InputDecoration(
                  labelText: 'الراوي',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: topicController,
                decoration: const InputDecoration(
                  labelText: 'الموضوع',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (textController.text.isNotEmpty &&
                  narratorController.text.isNotEmpty &&
                  topicController.text.isNotEmpty) {
                await DatabaseHelper.instance.updateHadith(
                    id,
                    textController.text.trim(),
                    narratorController.text.trim(),
                    topicController.text.trim());
                Navigator.pop(context, true);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadHadithsFromDatabase();
    }
  }

  // حذف حديث
  Future<void> _deleteHadith(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا الحديث؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteHadith(id);
      _loadHadithsFromDatabase();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الحديث بنجاح')),
      );
    }
  }
}
