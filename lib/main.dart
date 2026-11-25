// Witria (ويتريا) - Arabic brain-teaser quiz.
//
// File layout (single file, top to bottom):
//   1. Entry point + palette + models
//   2. Question bank (4 categories x 20 levels: easy -> medium -> hard)
//   3. Sfx (tones generated in code) and Notifier (comeback reminders)
//   4. App shell, game state and screens (home / levels / quiz / result)
//   5. Shared doodle widgets
//   6. DoodlePainter: every illustration is vector code, no image assets
//
import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notifier.init();
  Notifier.scheduleComeback();
  runApp(const WitriaApp());
}

// ======================= Palette =======================
const Color kCream = Color(0xFFFBF7EF);
const Color kInk = Color(0xFF2E2A26);
const Color kTeal = Color(0xFF2EB8A6);
const Color kCoral = Color(0xFFFF7F66);
const Color kSunny = Color(0xFFFFD166);
const Color kSky = Color(0xFF8ED1E8);
const Color kGood = Color(0xFF4CB56B);
const Color kBad = Color(0xFFE8554E);
const Color kBrown = Color(0xFFB5835A);
const Color kGrey = Color(0xFFD5D0C6);
const Color kPink = Color(0xFFF4A6B8);
const Color kPurple = Color(0xFFA78BDA);

// ======================= Models =======================
class Question {
  final String text;
  final List<String> options;
  final int correctIndex;
  final String art; // doodle id, optional args after ':' e.g. plus:7,8

  const Question({
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.art,
  });
}

class QuizCategory {
  final String name;
  final String emoji;
  final String art;
  final Color color;
  final bool lightText;
  final List<Question> questions;

  const QuizCategory({
    required this.name,
    required this.emoji,
    required this.art,
    required this.color,
    required this.lightText,
    required this.questions,
  });
}

// Difficulty by level number (1-based): 1-7 easy, 8-14 medium, 15-20 hard
int difficultyOf(int index) => index < 7 ? 0 : (index < 14 ? 1 : 2);
const List<String> kDiffNames = ['سهل', 'متوسط', 'صعب'];
const List<Color> kDiffColors = [kGood, kSunny, kCoral];

// ======================= Question Bank (20 per category) =======================
const List<QuizCategory> kCategories = [
  // ---------- ألغاز وذكاء ----------
  QuizCategory(
    name: 'ألغاز وذكاء',
    emoji: '🧩',
    art: 'bulb',
    color: kTeal,
    lightText: true,
    questions: [
      Question(
        text: 'ما هو الشيء الذي كلما أخذت منه كَبُر؟',
        options: ['الحفرة', 'الجبل', 'البحر', 'الشجرة'],
        correctIndex: 0,
        art: 'hole',
      ),
      Question(
        text: 'له عينٌ واحدة ولا يرى، فما هو؟',
        options: ['النظارة', 'الإبرة', 'التلسكوب', 'المرآة'],
        correctIndex: 1,
        art: 'needle',
      ),
      Question(
        text: 'له أسنان ولا يعضّ، ونرتّب به شعرنا، فما هو؟',
        options: ['التمساح', 'المشط', 'القط', 'الكلب'],
        correctIndex: 1,
        art: 'comb',
      ),
      Question(
        text: 'يمشي بلا أرجل ويدخل الأذن، فما هو؟',
        options: ['الساعة', 'الصوت', 'النملة', 'الظل'],
        correctIndex: 1,
        art: 'sound',
      ),
      Question(
        text: 'يكتب ولا يقرأ، فما هو؟',
        options: ['القلم', 'الكتاب', 'الطالب', 'الجدار'],
        correctIndex: 0,
        art: 'pencil',
      ),
      Question(
        text: 'ما الشيء الذي لا يمشي إلا بالضرب؟',
        options: ['الحصان', 'المسمار', 'الكرة', 'الطبل'],
        correctIndex: 1,
        art: 'nail',
      ),
      Question(
        text: 'له عقارب ولا يلدغ، فما هو؟',
        options: ['الساعة', 'الثعبان', 'العقرب', 'الخريطة'],
        correctIndex: 0,
        art: 'clock',
      ),
      Question(
        text: 'يحملك وتحمله في الوقت نفسه، فما هو؟',
        options: ['الحقيبة', 'الحذاء', 'الكرسي', 'القبعة'],
        correctIndex: 1,
        art: 'shoe',
      ),
      Question(
        text: 'ما هو الباب الذي لا يمكن فتحه أبداً؟',
        options: ['الباب الحديدي', 'باب البيت', 'الباب المفتوح', 'الباب القديم'],
        correctIndex: 2,
        art: 'door',
      ),
      Question(
        text: 'أي شهر من شهور السنة فيه 28 يوماً؟',
        options: ['فبراير فقط', 'شهور الصيف', 'كل الشهور', 'لا يوجد'],
        correctIndex: 2,
        art: 'calendar',
      ),
      Question(
        text: 'قبل اكتشافه، ما كان أعلى جبل في العالم؟',
        options: ['كليمنجارو', 'جبل إفرست', 'جبال الألب', 'لم يكن هناك جبل'],
        correctIndex: 1,
        art: 'mountain',
      ),
      Question(
        text: 'كم مرة تستطيع طرح الرقم 5 من الرقم 25؟',
        options: ['خمس مرات', 'أربع مرات', 'مرة واحدة فقط', 'عشر مرات'],
        correctIndex: 2,
        art: 'minus:5,1',
      ),
      Question(
        text: 'ما الشيء الذي يكون أمامك دائماً ولا تراه؟',
        options: ['الظل', 'المستقبل', 'الهواء', 'الحائط'],
        correctIndex: 1,
        art: 'road',
      ),
      Question(
        text: 'ما الشيء الذي كلما زاد نقص؟',
        options: ['العمر', 'المال', 'الطعام', 'الماء'],
        correctIndex: 0,
        art: 'candle',
      ),
      Question(
        text: 'يسمع بلا أذن ويتكلم بلا لسان، فما هو؟',
        options: ['الراديو', 'الهاتف', 'الكتاب', 'الببغاء'],
        correctIndex: 1,
        art: 'phone',
      ),
      Question(
        text: 'ما الشيء الذي تملكه ولكن غيرك يستخدمه أكثر منك؟',
        options: ['سيارتك', 'هاتفك', 'اسمك', 'بيتك'],
        correctIndex: 2,
        art: 'nametag',
      ),
      Question(
        text: 'رجل يقول وهو ينظر إلى صورة: ليس لي إخوة، لكن والد هذا الرجل هو ابن أبي. من الرجل في الصورة؟',
        options: ['أبوه', 'ابنه', 'هو نفسه', 'عمّه'],
        correctIndex: 1,
        art: 'photo',
      ),
      Question(
        text: 'ما الشيء الذي يرتفع وينخفض ولا يتحرك من مكانه؟',
        options: ['الدرج', 'البالون', 'الميزان', 'الموج'],
        correctIndex: 0,
        art: 'stairs',
      ),
      Question(
        text: 'كان معك 3 تفاحات وأخذت منها 2، كم تفاحة معك أنت؟',
        options: ['واحدة', 'اثنتان', 'ثلاث', 'صفر'],
        correctIndex: 1,
        art: 'apples:3',
      ),
      Question(
        text: 'أعطاك الطبيب 3 حبات دواء وقال لك: خذ واحدة كل نصف ساعة. كم تكفيك؟',
        options: ['ساعة ونصف', 'ساعة', 'ثلاث ساعات', 'نصف ساعة'],
        correctIndex: 1,
        art: 'pills',
      ),
    ],
  ),
  // ---------- معلومات عامة ----------
  QuizCategory(
    name: 'معلومات عامة',
    emoji: '🌍',
    art: 'globe',
    color: kSunny,
    lightText: false,
    questions: [
      Question(
        text: 'ما هي عاصمة مصر؟',
        options: ['الإسكندرية', 'القاهرة', 'أسوان', 'الجيزة'],
        correctIndex: 1,
        art: 'pyramid',
      ),
      Question(
        text: 'ما هي عاصمة اليابان؟',
        options: ['بكين', 'سول', 'طوكيو', 'بانكوك'],
        correctIndex: 2,
        art: 'fuji',
      ),
      Question(
        text: 'كم عدد قارات العالم؟',
        options: ['5', '6', '7', '8'],
        correctIndex: 2,
        art: 'globe',
      ),
      Question(
        text: 'كم عدد ألوان قوس قزح؟',
        options: ['5', '6', '7', '9'],
        correctIndex: 2,
        art: 'rainbow',
      ),
      Question(
        text: 'كم عدد لاعبي فريق كرة القدم داخل الملعب؟',
        options: ['9', '10', '11', '12'],
        correctIndex: 2,
        art: 'ball',
      ),
      Question(
        text: 'ما هو أكبر كوكب في المجموعة الشمسية؟',
        options: ['الأرض', 'المشتري', 'زحل', 'المريخ'],
        correctIndex: 1,
        art: 'planet',
      ),
      Question(
        text: 'ما هو الكوكب الأحمر؟',
        options: ['المريخ', 'الزهرة', 'عطارد', 'نبتون'],
        correctIndex: 0,
        art: 'mars',
      ),
      Question(
        text: 'ما هو أكبر محيطات العالم؟',
        options: ['الأطلسي', 'الهندي', 'المتجمد الشمالي', 'الهادئ'],
        correctIndex: 3,
        art: 'waves',
      ),
      Question(
        text: 'ما هو أطول أنهار العالم؟',
        options: ['النيل', 'الأمازون', 'الفرات', 'الدانوب'],
        correctIndex: 0,
        art: 'river',
      ),
      Question(
        text: 'ما هو أسرع حيوان بري في العالم؟',
        options: ['الأسد', 'الغزال', 'الفهد', 'الحصان'],
        correctIndex: 2,
        art: 'paw',
      ),
      Question(
        text: 'ما هي أصغر دولة في العالم؟',
        options: ['موناكو', 'الفاتيكان', 'سنغافورة', 'مالطا'],
        correctIndex: 1,
        art: 'flag',
      ),
      Question(
        text: 'ما هو المعدن السائل في درجة حرارة الغرفة؟',
        options: ['الحديد', 'الذهب', 'الألومنيوم', 'الزئبق'],
        correctIndex: 3,
        art: 'thermo',
      ),
      Question(
        text: 'كم عدد عظام جسم الإنسان البالغ تقريباً؟',
        options: ['106', '206', '306', '406'],
        correctIndex: 1,
        art: 'bone',
      ),
      Question(
        text: 'ما هو الغاز الذي تمتصه النباتات لتصنع غذاءها؟',
        options: ['الأكسجين', 'النيتروجين', 'ثاني أكسيد الكربون', 'الهيليوم'],
        correctIndex: 2,
        art: 'leaf',
      ),
      Question(
        text: 'من رسم لوحة الموناليزا؟',
        options: ['بيكاسو', 'فان جوخ', 'ليوناردو دا فينشي', 'مايكل أنجلو'],
        correctIndex: 2,
        art: 'frame',
      ),
      Question(
        text: 'ما هي أكبر صحراء حارة في العالم؟',
        options: ['صحراء النفود', 'الصحراء الكبرى', 'صحراء جوبي', 'صحراء كالاهاري'],
        correctIndex: 1,
        art: 'dunes',
      ),
      Question(
        text: 'ما هو الرمز الكيميائي للذهب؟',
        options: ['Ag', 'Fe', 'Au', 'Gd'],
        correctIndex: 2,
        art: 'gold',
      ),
      Question(
        text: 'ما هي أعلى قمة جبل في العالم؟',
        options: ['إفرست', 'كيليمانجارو', 'مونت بلان', 'الأنديز'],
        correctIndex: 0,
        art: 'mountain',
      ),
      Question(
        text: 'ما هي اللغة الأكثر انتشاراً في العالم من حيث عدد المتحدثين بها كلغة أم؟',
        options: ['الإنجليزية', 'الإسبانية', 'الصينية (الماندرين)', 'العربية'],
        correctIndex: 2,
        art: 'speech',
      ),
      Question(
        text: 'كم عدد كواكب المجموعة الشمسية؟',
        options: ['7', '8', '9', '10'],
        correctIndex: 1,
        art: 'orbit',
      ),
    ],
  ),
  // ---------- رياضيات خفيفة ----------
  QuizCategory(
    name: 'رياضيات خفيفة',
    emoji: '🔢',
    art: 'calc',
    color: kCoral,
    lightText: true,
    questions: [
      Question(
        text: 'كم ناتج 7 + 8؟',
        options: ['13', '14', '15', '16'],
        correctIndex: 2,
        art: 'plus:7,8',
      ),
      Question(
        text: 'كان معك 10 تفاحات وأكلت 4، كم بقي معك؟',
        options: ['5', '6', '7', '4'],
        correctIndex: 1,
        art: 'minus:10,4',
      ),
      Question(
        text: 'ما هو نصف العدد 50؟',
        options: ['20', '25', '30', '15'],
        correctIndex: 1,
        art: 'pie:1,2',
      ),
      Question(
        text: 'كم ناتج 5 × 4؟',
        options: ['15', '20', '25', '30'],
        correctIndex: 1,
        art: 'times:5,4',
      ),
      Question(
        text: 'وزّعنا 20 حلوى على 4 أطفال بالتساوي، كم حلوى لكل طفل؟',
        options: ['4', '5', '6', '8'],
        correctIndex: 1,
        art: 'divide:20,4',
      ),
      Question(
        text: 'كم ناتج 12 × 3؟',
        options: ['33', '36', '39', '42'],
        correctIndex: 1,
        art: 'times:12,3',
      ),
      Question(
        text: 'كم ناتج 9 × 9؟',
        options: ['72', '79', '81', '99'],
        correctIndex: 2,
        art: 'times:9,9',
      ),
      Question(
        text: 'كم ناتج 100 − 37؟',
        options: ['63', '67', '73', '53'],
        correctIndex: 0,
        art: 'numline:37,100',
      ),
      Question(
        text: 'كم يساوي 6² (ستة تربيع)؟',
        options: ['12', '26', '36', '46'],
        correctIndex: 2,
        art: 'square:6',
      ),
      Question(
        text: 'كم يساوي 15٪ من 200؟',
        options: ['15', '25', '30', '35'],
        correctIndex: 2,
        art: 'percent',
      ),
      Question(
        text: 'كم مجموع زوايا المثلث؟',
        options: ['90 درجة', '120 درجة', '180 درجة', '360 درجة'],
        correctIndex: 2,
        art: 'triangle',
      ),
      Question(
        text: 'ما هو العدد الأولي الذي يأتي بعد الرقم 7؟',
        options: ['8', '9', '10', '11'],
        correctIndex: 3,
        art: 'numline:8,12',
      ),
      Question(
        text: 'كم دقيقة في ساعتين؟',
        options: ['90', '100', '120', '180'],
        correctIndex: 2,
        art: 'clock',
      ),
      Question(
        text: 'كم ناتج 25 × 4؟',
        options: ['90', '100', '120', '150'],
        correctIndex: 1,
        art: 'coins',
      ),
      Question(
        text: 'كم ناتج 2 + 2 × 3؟',
        options: ['12', '8', '10', '7'],
        correctIndex: 1,
        art: 'calc',
      ),
      Question(
        text: 'ما مساحة مستطيل طوله 8 وعرضه 5؟',
        options: ['13', '26', '40', '45'],
        correctIndex: 2,
        art: 'rect:8,5',
      ),
      Question(
        text: 'ما محيط مربع طول ضلعه 7؟',
        options: ['14', '21', '28', '49'],
        correctIndex: 2,
        art: 'rect:7,7',
      ),
      Question(
        text: 'ما هو الجذر التربيعي للعدد 144؟',
        options: ['10', '11', '12', '14'],
        correctIndex: 2,
        art: 'sqrt',
      ),
      Question(
        text: 'ما هو العدد الزوجي الوحيد الذي هو عدد أولي؟',
        options: ['2', '4', '6', '8'],
        correctIndex: 0,
        art: 'numline:2,12',
      ),
      Question(
        text: 'سيارة تسير بسرعة 60 كم في الساعة، كم تقطع في 3 ساعات؟',
        options: ['120 كم', '150 كم', '180 كم', '200 كم'],
        correctIndex: 2,
        art: 'car',
      ),
    ],
  ),
  // ---------- أسئلة إسلامية ----------
  QuizCategory(
    name: 'أسئلة إسلامية',
    emoji: '🕌',
    art: 'crescent',
    color: kSky,
    lightText: false,
    questions: [
      Question(
        text: 'كم عدد أركان الإسلام؟',
        options: ['4', '5', '6', '7'],
        correctIndex: 1,
        art: 'pillars',
      ),
      Question(
        text: 'كم عدد سور القرآن الكريم؟',
        options: ['110', '114', '120', '99'],
        correctIndex: 1,
        art: 'quran',
      ),
      Question(
        text: 'من هو أول مؤذن في الإسلام؟',
        options: [
          'عمر بن الخطاب',
          'علي بن أبي طالب',
          'بلال بن رباح',
          'سلمان الفارسي',
        ],
        correctIndex: 2,
        art: 'minaret',
      ),
      Question(
        text: 'كم عدد الصلوات المفروضة في اليوم والليلة؟',
        options: ['3', '4', '5', '6'],
        correctIndex: 2,
        art: 'rug',
      ),
      Question(
        text: 'إلى أين يتجه المسلمون في صلاتهم؟',
        options: ['المسجد الأقصى', 'الكعبة المشرفة', 'المسجد النبوي', 'جبل عرفة'],
        correctIndex: 1,
        art: 'kaaba',
      ),
      Question(
        text: 'ما هو الشهر الذي يصومه المسلمون؟',
        options: ['شعبان', 'رجب', 'رمضان', 'محرم'],
        correctIndex: 2,
        art: 'crescent',
      ),
      Question(
        text: 'ما هي أطول سورة في القرآن الكريم؟',
        options: ['آل عمران', 'النساء', 'البقرة', 'المائدة'],
        correctIndex: 2,
        art: 'quran',
      ),
      Question(
        text: 'كم عدد أركان الإيمان؟',
        options: ['5', '6', '7', '4'],
        correctIndex: 1,
        art: 'heart',
      ),
      Question(
        text: 'ما هي أقصر سورة في القرآن الكريم؟',
        options: ['الكوثر', 'الإخلاص', 'الناس', 'الفلق'],
        correctIndex: 0,
        art: 'river',
      ),
      Question(
        text: 'كم عدد أجزاء القرآن الكريم؟',
        options: ['28', '29', '30', '31'],
        correctIndex: 2,
        art: 'quran',
      ),
      Question(
        text: 'كم عدد أبواب الجنة؟',
        options: ['7', '8', '9', '10'],
        correctIndex: 1,
        art: 'gate',
      ),
      Question(
        text: 'ما هي السورة التي نزلت فيها أول آيات من القرآن الكريم (في غار حراء)؟',
        options: ['الفاتحة', 'البقرة', 'العلق', 'الإخلاص'],
        correctIndex: 2,
        art: 'cave',
      ),
      Question(
        text: 'كم عدد الأنبياء المذكورين بأسمائهم في القرآن الكريم؟',
        options: ['20', '25', '30', '15'],
        correctIndex: 1,
        art: 'stars',
      ),
      Question(
        text: 'من هو النبي الذي ابتلعه الحوت؟',
        options: ['يونس', 'موسى', 'أيوب', 'يوسف'],
        correctIndex: 0,
        art: 'whale',
      ),
      Question(
        text: 'من هو النبي الذي بنى السفينة بأمر الله؟',
        options: ['إبراهيم', 'نوح', 'صالح', 'هود'],
        correctIndex: 1,
        art: 'ark',
      ),
      Question(
        text: 'ما هي الليلة التي نزل فيها القرآن الكريم؟',
        options: ['ليلة القدر', 'ليلة الإسراء', 'ليلة النصف من شعبان', 'ليلة عرفة'],
        correctIndex: 0,
        art: 'night',
      ),
      Question(
        text: 'ما هي السورة التي تُسمّى قلب القرآن؟',
        options: ['الرحمن', 'يس', 'الكهف', 'الملك'],
        correctIndex: 1,
        art: 'heart',
      ),
      Question(
        text: 'من هو النبي الذي ألقاه قومه في النار فكانت عليه برداً وسلاماً؟',
        options: ['موسى', 'عيسى', 'إبراهيم', 'إسماعيل'],
        correctIndex: 2,
        art: 'fire',
      ),
      Question(
        text: 'كم عدد الأنبياء أولي العزم من الرسل؟',
        options: ['3', '4', '5', '7'],
        correctIndex: 2,
        art: 'hand5',
      ),
      Question(
        text: 'ما هي السورة التي لا تبدأ بالبسملة؟',
        options: ['التوبة', 'الفاتحة', 'الكهف', 'يس'],
        correctIndex: 0,
        art: 'scroll',
      ),
    ],
  ),
];

// ======================= Fun feedback lines =======================
const List<String> kPraise = [
  'إجابة صحيحة! أحسنت 👏',
  'برافو عليك! 🎉',
  'صحيحة! دماغك شغالة 🔥',
  'ممتاز! استمر 💪',
  'عاش! إجابة مظبوطة ⭐',
];

const List<String> kOops = [
  'إجابة خاطئة.. ركّز أكثر 😅',
  'للأسف غلط! المرة الجاية 💫',
  'مش دي الإجابة 😬',
  'قريب.. بس مش صح 🙈',
];

// ======================= Sounds (built in code, no files) =======================
class Sfx {
  static final AudioPlayer _player = AudioPlayer();
  static bool enabled = true;

  static final Uint8List good = _wav([
    [660.0, 0.11],
    [880.0, 0.11],
    [1175.0, 0.2],
  ]);
  static final Uint8List bad = _wav([
    [220.0, 0.16],
    [165.0, 0.28],
  ]);
  static final Uint8List tap = _wav([
    [500.0, 0.05],
  ]);

  static Uint8List _wav(List<List<double>> notes) {
    const int rate = 22050;
    final List<int> samples = <int>[];
    for (final List<double> n in notes) {
      final int count = (rate * n[1]).round();
      for (int i = 0; i < count; i++) {
        final double t = i / rate;
        final double fadeIn = min(1.0, i / 150.0);
        final double fadeOut = min(1.0, (count - i) / 500.0);
        final double env = min(fadeIn, fadeOut);
        samples.add((sin(2 * pi * n[0] * t) * env * 0.45 * 32767).round());
      }
    }
    final ByteData d = ByteData(44 + samples.length * 2);
    void str(int off, String s) {
      for (int i = 0; i < s.length; i++) {
        d.setUint8(off + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    d.setUint32(4, 36 + samples.length * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    d.setUint32(16, 16, Endian.little);
    d.setUint16(20, 1, Endian.little);
    d.setUint16(22, 1, Endian.little);
    d.setUint32(24, rate, Endian.little);
    d.setUint32(28, rate * 2, Endian.little);
    d.setUint16(32, 2, Endian.little);
    d.setUint16(34, 16, Endian.little);
    str(36, 'data');
    d.setUint32(40, samples.length * 2, Endian.little);
    for (int i = 0; i < samples.length; i++) {
      d.setInt16(44 + i * 2, samples[i], Endian.little);
    }
    return d.buffer.asUint8List();
  }

  static Future<void> play(Uint8List bytes) async {
    if (!enabled) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(bytes));
    } catch (_) {}
  }
}

// ======================= Re-engagement notifications =======================
class Notifier {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static const List<String> _msgs = [
    'وحشتنا! ارجع لويتريا وكمّل التحدي 🧠',
    'دماغك محتاجة تمرين النهاردة 💪 تعالى العب شوية',
    'فيه أسئلة جديدة مستنياك في ويتريا 🔥',
  ];

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      const InitializationSettings settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      );
      await _plugin.initialize(settings);
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      _ready = true;
    } catch (_) {}
  }

  // Cancels old reminders and sets new ones 3 and 7 days from now.
  // Called every time the app opens, resumes or goes to background,
  // so a reminder only shows up if the player really stayed away.
  static Future<void> scheduleComeback() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
      const NotificationDetails details = NotificationDetails(
        android: AndroidNotificationDetails(
          'comeback',
          'تذكير باللعب',
          channelDescription: 'تذكير لما تغيب عن اللعبة فترة',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );
      final Random r = Random();
      final tz.TZDateTime now = tz.TZDateTime.now(tz.UTC);
      await _plugin.zonedSchedule(
        1,
        'ويتريا 🧠',
        _msgs[r.nextInt(_msgs.length)],
        now.add(const Duration(days: 3)),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      await _plugin.zonedSchedule(
        2,
        'ويتريا 🧠',
        _msgs[r.nextInt(_msgs.length)],
        now.add(const Duration(days: 7)),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {}
  }
}

// ======================= App =======================
class WitriaApp extends StatelessWidget {
  const WitriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ويتريا',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: kCream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kTeal,
          brightness: Brightness.light,
        ).copyWith(surface: kCream, primary: kTeal, secondary: kCoral),
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const GameRoot(),
    );
  }
}

enum _Screen { home, levels, quiz, result }

class GameRoot extends StatefulWidget {
  const GameRoot({super.key});

  @override
  State<GameRoot> createState() => _GameRootState();
}

class _GameRootState extends State<GameRoot> with WidgetsBindingObserver {
  _Screen _screen = _Screen.home;
  QuizCategory? _category;
  int _index = 0;
  int _startIndex = 0;
  int _score = 0;
  int _totalStars = 0;
  int? _selected;
  bool _answered = false;
  bool _quick = false;
  String _feedback = '';
  int _advanceToken = 0;
  final Random _rng = Random();
  final Map<String, Set<int>> _done = <String, Set<int>>{};

  static const List<String> _letters = ['أ', 'ب', 'ج', 'د'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.detached) {
      Notifier.scheduleComeback();
    }
  }

  void _startQuiz(QuizCategory category, {int startAt = 0, bool quick = false}) {
    Sfx.play(Sfx.tap);
    setState(() {
      _advanceToken++;
      _category = category;
      _quick = quick;
      _startIndex = startAt;
      _index = startAt;
      _score = 0;
      _selected = null;
      _answered = false;
      _feedback = '';
      _screen = _Screen.quiz;
    });
  }

  void _startQuick() {
    final List<Question> all = <Question>[];
    for (final QuizCategory c in kCategories) {
      all.addAll(c.questions);
    }
    all.shuffle(_rng);
    final QuizCategory quick = QuizCategory(
      name: 'تحدي سريع',
      emoji: '⚡',
      art: 'bulb',
      color: kSunny,
      lightText: false,
      questions: all.take(10).toList(),
    );
    _startQuiz(quick, quick: true);
  }

  void _goHome() {
    setState(() {
      _advanceToken++;
      _screen = _Screen.home;
      _category = null;
    });
  }

  void _goLevels() {
    setState(() {
      _advanceToken++;
      _screen = _quick ? _Screen.home : _Screen.levels;
    });
  }

  void _onAnswer(int i) {
    final QuizCategory? cat = _category;
    if (_answered || cat == null) return;
    final Question q = cat.questions[_index];
    final bool correct = i == q.correctIndex;
    Sfx.play(correct ? Sfx.good : Sfx.bad);
    setState(() {
      _answered = true;
      _selected = i;
      if (correct) {
        _score++;
        _totalStars++;
        if (!_quick) {
          _done.putIfAbsent(cat.name, () => <int>{}).add(_index);
        }
      }
      final List<String> lines = correct ? kPraise : kOops;
      _feedback = lines[_rng.nextInt(lines.length)];
    });
    final int token = ++_advanceToken;
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || token != _advanceToken) return;
      setState(() {
        if (_index >= cat.questions.length - 1) {
          _screen = _Screen.result;
        } else {
          _index++;
          _selected = null;
          _answered = false;
          _feedback = '';
        }
      });
    });
  }

  String _resultMessage(double ratio) {
    if (ratio >= 0.9) return 'عبقري! أداء أسطوري 🏆';
    if (ratio >= 0.7) return 'ممتاز! قريب جداً من العلامة الكاملة 🌟';
    if (ratio >= 0.5) return 'جيد! تحتاج شوية تدريب 💪';
    if (ratio >= 0.3) return 'لا بأس.. حاول مرة تانية 👍';
    return 'ولا يهمك! جرّب تاني وهتتحسن 🎯';
  }

  String _resultEmoji(double ratio) {
    if (ratio >= 0.9) return '🏆';
    if (ratio >= 0.7) return '🌟';
    if (ratio >= 0.5) return '💪';
    if (ratio >= 0.3) return '👍';
    return '🎯';
  }

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case _Screen.home:
        return _buildHome();
      case _Screen.levels:
        return _buildLevels();
      case _Screen.quiz:
        return _buildQuiz();
      case _Screen.result:
        return _buildResult();
    }
  }

  Widget _statChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kSunny,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kInk, width: 2.5),
        boxShadow: const [
          BoxShadow(color: kInk, offset: Offset(0, 3), blurRadius: 0),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: kInk,
        ),
      ),
    );
  }

  // ======================= Home =======================
  Widget _buildHome() {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  _statChip('⭐ $_totalStars'),
                  const Spacer(),
                  DoodleIconButton(
                    icon: Sfx.enabled ? Icons.volume_up : Icons.volume_off,
                    onTap: () => setState(() => Sfx.enabled = !Sfx.enabled),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 190,
                height: 133,
                child: CustomPaint(painter: DoodlePainter('brain')),
              ),
              Transform.rotate(
                angle: -0.02,
                child: const Text(
                  'ويتريا',
                  style: TextStyle(
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    color: kTeal,
                    shadows: [
                      Shadow(color: kInk, offset: Offset(4, 4), blurRadius: 0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'فكّر.. العب.. اتحدّى',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 22),
              DoodleButton(
                color: kCoral,
                onTap: _startQuick,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('⚡', style: TextStyle(fontSize: 26)),
                    SizedBox(width: 10),
                    Text(
                      'تحدي سريع (10 أسئلة)',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'الأقسام',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: kInk,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.82,
                children: [
                  for (final QuizCategory cat in kCategories)
                    _categoryCard(cat),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryCard(QuizCategory cat) {
    final Color fg = cat.lightText ? Colors.white : kInk;
    final int done = _done[cat.name]?.length ?? 0;
    return DoodleButton(
      color: cat.color,
      onTap: () {
        Sfx.play(Sfx.tap);
        setState(() {
          _category = cat;
          _screen = _Screen.levels;
        });
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kInk, width: 2.5),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: DoodlePainter(cat.art),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cat.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$done / ${cat.questions.length} مستوى',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ======================= Levels =======================
  Widget _buildLevels() {
    final QuizCategory cat = _category ?? kCategories.first;
    final Set<int> done = _done[cat.name] ?? <int>{};
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  DoodleIconButton(icon: Icons.arrow_back, onTap: _goHome),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${cat.emoji} ${cat.name}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: kInk,
                      ),
                    ),
                  ),
                  _statChip('⭐ $_totalStars'),
                ],
              ),
              const SizedBox(height: 18),
              for (int d = 0; d < 3; d++) ...[
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10, top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kDiffColors[d],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kInk, width: 2.5),
                    ),
                    child: Text(
                      kDiffNames[d],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: kInk,
                      ),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.start,
                  children: [
                    for (int i = 0; i < cat.questions.length; i++)
                      if (difficultyOf(i) == d)
                        _levelBubble(cat, i, done.contains(i)),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelBubble(QuizCategory cat, int i, bool done) {
    return GestureDetector(
      onTap: () => _startQuiz(cat, startAt: i),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: done ? kGood : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: kInk, width: 3),
          boxShadow: const [
            BoxShadow(color: kInk, offset: Offset(0, 4), blurRadius: 0),
          ],
        ),
        alignment: Alignment.center,
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 28)
            : Text(
                '${i + 1}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: kInk,
                ),
              ),
      ),
    );
  }

  // ======================= Quiz =======================
  Widget _buildQuiz() {
    final QuizCategory cat = _category ?? kCategories.first;
    final Question q = cat.questions[_index];
    final double progress = (_index + 1) / cat.questions.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DoodleIconButton(icon: Icons.arrow_back, onTap: _goLevels),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _quick
                          ? '⚡ سؤال ${_index + 1} من ${cat.questions.length}'
                          : 'مستوى ${_index + 1} · ${kDiffNames[difficultyOf(_index)]}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _statChip('⭐ $_score'),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kInk, width: 2.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(color: kTeal),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kInk, width: 3),
                    boxShadow: const [
                      BoxShadow(color: kInk, offset: Offset(5, 5), blurRadius: 0),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: kCream,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: DoodlePainter(q.art),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        flex: 4,
                        child: Center(
                          child: SingleChildScrollView(
                            child: Text(
                              q.text,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: kInk,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (int i = 0; i < q.options.length; i++) ...[
                DoodleButton(
                  color: _answerColor(i, q),
                  onTap: _answered ? null : () => _onAnswer(i),
                  vertical: 11,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _answerLetterBg(i, q),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _letters[i],
                          style: TextStyle(
                            color: _answerLetterFg(i, q),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          q.options[i],
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _answerTextColor(i, q),
                          ),
                        ),
                      ),
                      if (_answered && i == q.correctIndex)
                        const Text('✅', style: TextStyle(fontSize: 20))
                      else if (_answered && i == _selected)
                        const Text('❌', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                height: 46,
                child: _answered
                    ? Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _selected == q.correctIndex ? kGood : kBad,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: kInk, width: 2.5),
                        ),
                        child: Text(
                          _feedback,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _answerColor(int i, Question q) {
    if (!_answered) return Colors.white;
    if (i == q.correctIndex) return kGood;
    if (i == _selected) return kBad;
    return Colors.white;
  }

  Color _answerTextColor(int i, Question q) {
    if (!_answered) return kInk;
    if (i == q.correctIndex || i == _selected) return Colors.white;
    return kInk;
  }

  Color _answerLetterBg(int i, Question q) {
    if (!_answered) return kInk;
    if (i == q.correctIndex || i == _selected) return Colors.white;
    return kInk;
  }

  Color _answerLetterFg(int i, Question q) {
    if (!_answered) return Colors.white;
    if (i == q.correctIndex) return kGood;
    if (i == _selected) return kBad;
    return Colors.white;
  }

  // ======================= Result =======================
  Widget _buildResult() {
    final QuizCategory cat = _category ?? kCategories.first;
    final int played = cat.questions.length - _startIndex;
    final double ratio = played == 0 ? 0 : _score / played;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: ratio >= 0.5 ? kTeal : kCoral,
                  shape: BoxShape.circle,
                  border: Border.all(color: kInk, width: 4),
                  boxShadow: const [
                    BoxShadow(color: kInk, offset: Offset(6, 6), blurRadius: 0),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _resultEmoji(ratio),
                  style: const TextStyle(fontSize: 72),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '$_score من $played',
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _resultMessage(ratio),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kInk,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${cat.emoji} ${cat.name}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kInk.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 36),
              DoodleButton(
                color: kTeal,
                onTap: () {
                  if (_quick) {
                    _startQuick();
                  } else {
                    _startQuiz(cat, startAt: _startIndex);
                  }
                },
                child: const Center(
                  child: Text(
                    'العب تاني 🔁',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (!_quick) ...[
                DoodleButton(
                  color: kSunny,
                  onTap: () => setState(() => _screen = _Screen.levels),
                  child: const Center(
                    child: Text(
                      'المستويات 🗺️',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kInk,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              DoodleButton(
                color: Colors.white,
                onTap: _goHome,
                child: const Center(
                  child: Text(
                    'الرئيسية 🏠',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kInk,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= Doodle widgets =======================
class DoodleButton extends StatefulWidget {
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final double radius;
  final double vertical;

  const DoodleButton({
    super.key,
    required this.child,
    required this.color,
    this.onTap,
    this.radius = 18,
    this.vertical = 16,
  });

  @override
  State<DoodleButton> createState() => _DoodleButtonState();
}

class _DoodleButtonState extends State<DoodleButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform: Matrix4.translationValues(0, _down ? 5 : 0, 0),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: widget.vertical, horizontal: 16),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: kInk, width: 3),
          boxShadow: [
            BoxShadow(
              color: kInk,
              offset: Offset(0, _down ? 0 : 5),
              blurRadius: 0,
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class DoodleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const DoodleIconButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kInk, width: 2.5),
          boxShadow: const [
            BoxShadow(color: kInk, offset: Offset(0, 3), blurRadius: 0),
          ],
        ),