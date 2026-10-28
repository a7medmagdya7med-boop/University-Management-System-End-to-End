# دليل تقسيم SQL لمشروع University-Management-System-End-to-End

## نتيجة فحص المصدر
المصدر 11044 سطرًا، ويحتوي على إنشاء 21 جدولًا والتحقق من بنيتها، ثم Schema Audit، ثم إدخال البيانات التجريبية والتحقق منها لـ21 جدولًا، ثم Final Integrity Audit، ثم 20 Business Query وSmoke Checks. لا يحتوي على CREATE DATABASE أو ملف Power BI أو تعريفات Views جاهزة لـDirectQuery.
هذه الحزمة مستخرجة من SQL والصورة المرفقين؛ لم يتم فحص المحتوى الحالي للمستودع الخاص على GitHub.

## محتويات الحزمة
- ملف 00_Create_Database.sql: مساعد جديد لإنشاء قاعدة فارغة إذا لم تكن موجودة، وليس جزءًا من المصدر.
- مجلد Phase_4_SQL_Implementation_Verification/SQL/01_Schema: عدد 21 ملفًا. كل ملف يجمع CREATE TABLE والاختبارات التابعة له، ويحتفظ بـPK وFK وCHECK وUNIQUE وfiltered indexes في موضعها الأصلي.
- ملف 02_Schema_Audit.sql: تدقيق البنية بعد إنشاء كل الجداول.
- مجلد 03_Seed_Data: عدد 21 ملفًا، كل ملف يجمع INSERT واختبارات البيانات لنفس الجدول.
- ملف 04_Final_Database_Integrity_Audit.sql: تدقيق البنية والبيانات بعد اكتمال إدخال البيانات.
- مجلد Phase_5_Business_Queries_PowerBI_Analytics/SQL/01_Business_Queries: ملفات Q01 إلى Q20.
- ملف 02_ReadOnly_Smoke_Checks.sql: فحوص قراءة بعد اكتمال Phase 4.
- ملف SOURCE_MAP.csv: يربط كل ملف مستخرج بنطاق أسطره في المصدر.
- ملف UniversityManagementDB(2).original.sql: نسخة المصدر دون تعديل، للمرجعية فقط. لا تشغله بعد الملفات المقسمة.

أُضيف USE وGO في بداية كل ملف مستخرج وGO في نهايته. لم تُعدّل عبارات SQL الأصلية. استُبعد عنوان Phase 5 العام وSET NOCOUNT ON العام والنهاية الفارغة؛ لا يؤثر ذلك في نتائج الاستعلامات. لم تُنقل اختبارات seed إلى Phase 5؛ فهي تحقق من التنفيذ ضمن Phase 4.

## ترتيب التنفيذ
1. أنشئ قاعدة الاختبار بواسطة 00_Create_Database.sql، أو استخدم قاعدة فارغة مجهزة مسبقًا.
2. شغّل ملفات 01_Schema من 01 إلى 21 بالترتيب.
3. شغّل 02_Schema_Audit.sql وافحص النتائج قبل المتابعة.
4. شغّل ملفات 03_Seed_Data من 01 إلى 21 بالترتيب. راجع نتيجة التحقق بعد كل ملف وتوقف عند FAIL أو خطأ.
5. شغّل 04_Final_Database_Integrity_Audit.sql. افحص FAIL وREVIEW؛ لا تعتبر REVIEW مساوية لـPASS.
6. شغّل Phase 5 Smoke Checks ثم الاستعلامات المطلوبة Q01–Q20.

استخدم SSMS وExecute لكل ملف كامل، ولا تنسخ جزءًا من BEGIN TRY أو transaction أو CTE أو تعريف متغير. حافظ على GO فهو يفصل batches. لا تشغّل الملفات جميعًا مرة واحدة بلا مراجعة؛ قد يستمر العميل في batches لاحقة بعد خطأ.
هذه عملية static extraction وفحص تطابق نصي، ولم يتم تشغيلها على SQL Server؛ لا تُعد الحزمة دليلًا على نجاح الاختبارات فعليًا.
المصدر يستخدم STRING_AGG، ولذلك يحتاج SQL Server 2017 أو أحدث؛ تحقق أيضًا من compatibility level المناسب لعبارات WITHIN GROUP.
عدد من ملفات seed يرفض وجود بيانات سابقة عمدًا. لا تعاود تشغيلها على قاعدة ممتلئة، ولا تحذف بيانات لتجاوز الحماية. للاختبار استخدم قاعدة منفصلة فارغة.

## ترتيب الاعتماديات
ترتيب Schema:
Department → Course → Semester → Library → StudentClub → Professor → GraduationProject → ResearchProject → Book → DepartmentHead → Student → CourseResponsibility → GraduationProjectSupervision → ResearchProjectSupervision → StudentPhone → UniversityIDCard → Enrollment → Borrowing → ClubMembership → ResearchParticipation → ResearchCollaboration.

ترتيب Seed يختلف عمدًا:
Department → Professor → Semester → Library → StudentClub → Course → GraduationProject → ResearchProject → Book → DepartmentHead → Student → CourseResponsibility → GraduationProjectSupervision → ResearchProjectSupervision → StudentPhone → UniversityIDCard → Enrollment → Borrowing → ClubMembership → ResearchParticipation → ResearchCollaboration.

الأسهم هنا ترتيب تشغيل؛ لا تعني أن كل عنصر يعتمد مباشرة على العنصر السابق.
يحتاج Professor إلى Department، ويتضمن علاقة AdvisorProfessorID ذاتية؛ أبقِ دفعات الإدخال الداخلية كما هي.
يحتاج Book إلى Library؛ ويحتاج Student إلى GraduationProject؛ وتحتاج Enrollment إلى Student وCourse وSemester؛ وتحتاج Borrowing إلى Student وBook.
يجب إنشاء وتعبئة ResearchParticipation قبل ResearchCollaboration، الذي يتضمن composite FK على StudentID وResearchProjectID، إضافة إلى علاقاته الأخرى. أبقِ composite keys وfiltered unique indexes كما هي.

## خريطة استعلامات Phase 5
| الملف | الغرض |
|---|---|
| Q01 | توزيع الطلاب بحسب سنة الميلاد |
| Q02 | توزيع EnrollmentStatus |
| Q03 | سجل Semester |
| Q04 | تغطية UniversityIDCard |
| Q05 | الكتب بحسب Library |
| Q06 | الطلاب ومشروعات التخرج |
| Q07 | الأقسام ورؤساؤها |
| Q08 | مسؤوليات التدريس |
| Q09 | النتائج بحسب Semester |
| Q10 | إعارات الكتب وحالتها |
| Q11 | المقررات بلا Professor مسؤول |
| Q12 | الطلاب ذوو عضويات حالية متعددة |
| Q13 | مشروعات البحث بلا مشاركين |
| Q14 | الطلاب بلا UniversityIDCard |
| Q15 | عبء التدريس فوق المتوسط |
| Q16 | ترتيب الدرجات داخل Semester |
| Q17 | مقارنة الدرجة بمتوسط Course |
| Q18 | الإشراف والمشاركة البحثية |
| Q19 | أداء الإعارات والتأخر |
| Q20 | مقارنة ResearchCollaboration وResearchParticipation |

يعتمد Q10 وQ12 وQ19 على GETDATE؛ تتغير النتائج مع التاريخ. بيانات Borrowing التجريبية موصوفة وفق snapshot بتاريخ 2026-10-24. اختلاف الأعداد اليوم لا يثبت وجود خلل. عند المقارنة وثّق AsOfDate موحدًا في نسخة تحليل مستقلة.
فجوة UniversityIDCard مرتبطة بـOBD-01، وفجوة المشاركة دون Collaboration مرتبطة بـD-18؛ المصدر يعاملهما كقرارات مفتوحة أو معلومات، فلا تحولهما تلقائيًا إلى أخطاء التزام.

## استخدام Power BI
ملفات Q01–Q20 للاستعلام والتحليل في SSMS؛ لا تفترض إمكانية لصق ملفاتها كاملة في موصل DirectQuery، لأنها تتضمن USE وGO وبعضها DECLARE أو CTE وORDER BY.
اربط Power BI بالجداول المعتمدة، واضبط العلاقات والمقاييس وفق النموذج، أو أنشئ لاحقًا Views مستقلة مناسبة بعد مراجعة مستوى التفصيل ومنع double counting. لا تتضمن هذه الحزمة PBIX أو DAX أو Views جديدة.
احتفظ بملف PBIX ولقطات dashboard وتوثيق المقاييس في Phase 5. إنشاء Views إن لزم يأتي بعد الجداول، وتبقى اختبارات تلك Views بجوارها.

## بقية المراحل
تبقى Phase 0 لإعداد البيئة ومتطلبات SQL Server. يمكن نقل مساعد 00_Create_Database.sql إليها، مع تحديث تعليمات التنفيذ.
تبقى Phases 1–3 للنموذج المفاهيمي وERD وMapping وNormalization؛ لا تحتاج نسخًا مكررة من SQL التنفيذي.
تبقى Phase 6 لتقرير الإغلاق ونتائج الاختبارات والأدلة وروابط ملفات Phase 4 وPhase 5. لا تنقل Final Integrity Audit إليها وحدها؛ هو خطوة تحقق قابلة للتنفيذ في Phase 4، ويمكن الإشارة إليه من تقرير الإغلاق.

## فصل الملفات يدويًا عند الحاجة
افتح المصدر في SSMS أو محرر نصوص، وحدد نطاق الأسطر من SOURCE_MAP.csv، وانسخه إلى الملف المطابق. أضف USE [UniversityManagementDB] ثم GO في البداية وGO في النهاية، واحفظ UTF-8.
لا تقسّم اعتمادًا على كل GO أو INSERT؛ فهناك INSERT في جداول مؤقتة ومتغيرات جداول داخل الاختبارات. الحدود الصحيحة هي وحدة الجدول مع اختباراته، أو استعلام الأعمال الكامل.
الملفات جاهزة بالفعل، فلا حاجة لإعادة الفصل يدويًا.

## الرفع إلى GitHub
1. فك ZIP محليًا.
2. افتح النسخة المحلية من University-Management-System-End-to-End.
3. ادمج مجلدي Phase 4 وPhase 5 في المجلدين الموجودين بالاسم نفسه؛ احتفظ بملفات التوثيق الحالية. ضع مساعد إنشاء القاعدة في الجذر أو Phase 0.
4. احتفظ بـSOURCE_MAP.csv ودليل الاستخدام. يمكن حفظ المصدر الأصلي تحت archive للمرجعية، خارج ترتيب التشغيل.
5. في GitHub Desktop اختر المستودع، وافحص Changes، واكتب وصفًا مثل Split SQL scripts into Phase 4 implementation and Phase 5 business queries، ثم Commit وPush.
6. بديلًا عبر المتصفح: افتح المستودع ثم Add file ثم Upload files واسحب المجلدين بعد فك ZIP مع الاحتفاظ ببنيتهما، وراجع المسارات ثم Commit changes. رفع ZIP وحده لا ينشئ المجلدات والملفات داخله.
7. راجع ظهور ملفات SQL في Phase 4 وPhase 5 وافتح عينة للتأكد من قراءة العربية. أضف رابط الدليل وترتيب التشغيل إلى README الرئيسي.

لم تُرفع هذه الحزمة إلى GitHub ولم تُغيّر المستودع.