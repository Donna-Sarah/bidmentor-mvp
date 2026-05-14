-- ============================================================
-- BIDMENTOR - Schema additions / patches
-- Run after supabase/base-schema.sql
-- ============================================================

-- RPC: increment lesson view count (safe, no race condition)
create or replace function public.increment_lesson_view_count(lesson_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.lessons
  set view_count = view_count + 1
  where id = lesson_id;
end;
$$;

grant execute on function public.increment_lesson_view_count(uuid) to anon, authenticated;

-- Lesson content supports structured quizzes.
alter table public.lessons
  add column if not exists quiz jsonb;

-- Index for lesson slug lookups (used heavily)
create index if not exists idx_lessons_slug on public.lessons (slug);
create unique index if not exists idx_lessons_slug_unique on public.lessons (slug);
create index if not exists idx_lessons_tier_published on public.lessons (tier, is_published);
create index if not exists idx_lessons_priority on public.lessons (is_priority) where is_priority = true;

-- Index for glossary term lookups
create index if not exists idx_glossary_slug on public.glossary_terms (slug);
create index if not exists idx_glossary_category on public.glossary_terms (category);

-- Full-text search index on glossary (for future search API)
create index if not exists idx_glossary_fts on public.glossary_terms
  using gin(to_tsvector('simple', coalesce(term_vn, '') || ' ' || coalesce(term_en, '') || ' ' || coalesce(short_definition, '')));

-- ============================================================
-- SEED: Learning module lessons
-- Idempotent UPSERT: safe to rerun when lesson slugs already exist.
-- ============================================================

insert into public.lessons (
  slug,
  title,
  title_en,
  tier,
  category,
  tags,
  objective,
  explanation,
  content_mdx,
  common_mistakes,
  fatal_errors,
  related_slugs,
  quiz,
  is_published,
  is_priority
) values
(
  'dau-thau-la-gi',
  $title_1$Đấu thầu là gì? Tổng quan cho người mới$title_1$,
  $titleen_1$What is Procurement / Public Bidding?$titleen_1$,
  0,
  'quy-trinh',
  ARRAY['đấu thầu', 'HSMT', 'nhà thầu', 'chủ đầu tư', 'quy trình']::text[],
  $objective_1$Sau bài này bạn sẽ hiểu đấu thầu là gì, ai tham gia, quy trình tổng quan diễn ra như thế nào - và biết mình đang đứng ở đâu trong bức tranh lớn đó.$objective_1$,
  $explanation_1$Đấu thầu đơn giản là một cuộc thi: nhiều công ty cùng nộp hồ sơ để giành quyền thực hiện một dự án. Bên tổ chức cuộc thi gọi là Chủ đầu tư (Employer/Owner), bên tham gia gọi là Nhà thầu (Bidder/Contractor). Ai đáp ứng yêu cầu tốt nhất - về năng lực, giá cả, kỹ thuật - thường sẽ thắng. Quy trình này được thiết kế để minh bạch và công bằng, đặc biệt trong các dự án dùng ngân sách nhà nước.$explanation_1$,
  $content_1$## Đấu thầu là gì - giải thích không cần luật

Hãy hình dung thế này: một bệnh viện cần mua 200 máy tính mới. Thay vì gọi thẳng một nhà cung cấp quen, họ phát thông báo ra ngoài: "Chúng tôi cần mua 200 máy tính, ai muốn bán thì nộp hồ sơ." Nhiều công ty cùng nộp. Bệnh viện chọn công ty đáp ứng đủ yêu cầu với giá tốt nhất.

Đó là đấu thầu.

Quy mô có thể từ vài trăm triệu đến hàng nghìn tỷ đồng. Loại hàng hóa/dịch vụ có thể là: xây dựng, thiết bị y tế, phần mềm, tư vấn, vận hành hệ thống…

> **Lưu ý thực tế:** Ở Việt Nam, đấu thầu dùng vốn nhà nước bắt buộc phải tuân theo Luật Đấu thầu 2023. Đấu thầu tư nhân linh hoạt hơn nhưng nhiều công ty vẫn áp dụng quy trình tương tự.

---

## Ai tham gia?

### Bên A - Chủ đầu tư (Employer / Owner / Contracting Authority)
Là đơn vị có nhu cầu mua hàng hóa, dịch vụ hoặc xây dựng công trình. Họ:
- Phát hành HSMT (Hồ sơ mời thầu - Bidding Document)
- Đặt ra các yêu cầu về năng lực, kỹ thuật, tài chính
- Chấm điểm và lựa chọn nhà thầu trúng thầu

Ví dụ: Sở Y tế Hà Nội, Tập đoàn Điện lực EVN, một ngân hàng thương mại lớn.

### Bên B - Nhà thầu (Bidder / Contractor / Tenderer)
Là công ty (hoặc liên danh nhiều công ty) nộp hồ sơ để cạnh tranh. Họ:
- Mua/nhận HSMT
- Chuẩn bị hồ sơ dự thầu (Bid Document)
- Nộp đúng hạn
- Chờ kết quả

> **Lưu ý thực tế:** Một nhà thầu có thể vừa là tổng thầu, vừa thuê lại nhà thầu phụ (subcontractor) - nhưng subcontractor thường không được tính kinh nghiệm trong hồ sơ chính.

---

## Tại sao phải đấu thầu?

3 lý do chính:

**1. Cạnh tranh** - Nhiều bên cùng chào giá → Chủ đầu tư có nhiều lựa chọn hơn, thường được giá tốt hơn.

**2. Minh bạch** - Quy trình công khai, tiêu chí chấm rõ ràng → Khó "thông thầu" nếu thực hiện đúng.

**3. Chọn được đơn vị phù hợp nhất** - Không chỉ rẻ nhất, mà còn đủ năng lực thực hiện.

---

## Các hình thức đấu thầu phổ biến ở Việt Nam

| Hình thức | Nghĩa đơn giản | Khi nào dùng |
|---|---|---|
| Đấu thầu rộng rãi | Ai cũng có thể tham gia | Phổ biến nhất, gói thầu thông thường |
| Đấu thầu hạn chế | Chỉ mời một số nhà thầu nhất định | Gói đặc thù, ít nhà cung cấp trên thị trường |
| Chỉ định thầu | Chọn thẳng 1 nhà thầu | Khẩn cấp, bí mật quốc gia, giá trị nhỏ |
| Mua sắm trực tiếp | Mua lại từ nhà thầu đã từng làm | Hàng hóa giống hệt, trong thời hạn nhất định |

---

## Quy trình đấu thầu - 6 bước tổng quan
Bước 1: Chủ đầu tư phát hành HSMT
↓
Bước 2: Nhà thầu nhận HSMT, nghiên cứu, gửi clarification (nếu có)
↓
Bước 3: Nhà thầu chuẩn bị và nộp hồ sơ dự thầu
↓
Bước 4: Chủ đầu tư mở thầu, chấm hồ sơ kỹ thuật
↓
Bước 5: Chủ đầu tư chấm giá, thương thảo hợp đồng
↓
Bước 6: Ký hợp đồng với nhà thầu trúng thầu

> **Lưu ý thực tế:** Gói thầu quốc tế (International Competitive Bidding - ICB) theo chuẩn World Bank, ADB thường có thêm bước Pre-qualification (sơ tuyển năng lực) trước khi phát HSMT chính thức.

---

## Đấu thầu công vs đấu thầu tư - khác nhau chỗ nào?

| | Đấu thầu công (dùng vốn nhà nước) | Đấu thầu tư (doanh nghiệp tư nhân) |
|---|---|---|
| Luật áp dụng | Luật Đấu thầu 2023, Nghị định 24/2024 | Không bắt buộc theo Luật Đấu thầu |
| Tính công khai | Đăng trên hệ thống NSDT quốc gia | Có thể chỉ mời một số nhà thầu |
| Thủ tục | Chặt chẽ, nhiều biểu mẫu | Linh hoạt hơn |
| Rủi ro sai sót | Cao hơn (lỗi nhỏ cũng có thể bị loại) | Thường được thương lượng |

---

## Cảm giác "ngợp" khi mới vào - hoàn toàn bình thường

HSMT dài 200–500 trang là chuyện bình thường. Thuật ngữ tiếng Anh lẫn tiếng Việt lẫn lộn. Luật dẫn chiếu sang luật khác. Yêu cầu mơ hồ.

Hầu hết người mới đều cảm thấy: *"Mình đọc mà không hiểu người ta đang nói gì."*

Cảm giác đó không có nghĩa là bạn không phù hợp. Có nghĩa là bạn chưa có hệ thống.

BidMentor giúp bạn xây hệ thống đó: từ cách đọc HSMT, hiểu thuật ngữ, nhận ra điều quan trọng - đến tránh những lỗi khiến hồ sơ bị loại ngay từ vòng đầu.$content_1$,
  $mistakes_1$[
  {
    "title": "Nhầm giữa HSMT và hồ sơ dự thầu",
    "description": "HSMT (Hồ sơ mời thầu) là tài liệu Chủ đầu tư phát ra để nêu yêu cầu. Hồ sơ dự thầu là tài liệu Nhà thầu chuẩn bị để nộp lại. Nhầm hai khái niệm này dẫn đến hiểu sai rất nhiều hướng dẫn tiếp theo.",
    "severity": "medium"
  },
  {
    "title": "Nghĩ rằng giá thấp nhất là thắng",
    "description": "Đấu thầu không phải đấu giá. Hồ sơ phải đáp ứng đủ yêu cầu kỹ thuật và năng lực trước, sau đó mới xét giá. Nhiều gói còn chấm theo phương pháp kỹ thuật-tài chính tổng hợp.",
    "severity": "high"
  },
  {
    "title": "Bắt đầu làm hồ sơ trước khi đọc kỹ HSMT",
    "description": "Nhiều người mới nhận HSMT là bắt đầu gom tài liệu luôn. Kết quả: mất thời gian chuẩn bị tài liệu không đúng yêu cầu, hoặc bỏ sót điều kiện loại trực tiếp.",
    "severity": "high"
  }
]$mistakes_1$::jsonb,
  $fatal_1$[]$fatal_1$::jsonb,
  ARRAY['cau-truc-hsmt-doc-tu-dau', 'top-loi-bi-loai-chi-tu', 'bao-lanh-du-thau-khong-duoc-sai']::text[],
  $quiz_1$[
  {
    "question": "Ai là người phát hành HSMT (Hồ sơ mời thầu)?",
    "options": [
      "Nhà thầu",
      "Chủ đầu tư",
      "Bộ Kế hoạch và Đầu tư",
      "Ngân hàng bảo lãnh"
    ],
    "correct_answer": "Chủ đầu tư",
    "explanation": "Chủ đầu tư (Employer/Owner) là bên có nhu cầu, họ phát hành HSMT để mời các nhà thầu tham gia cạnh tranh."
  },
  {
    "question": "Hình thức đấu thầu nào phổ biến nhất ở Việt Nam?",
    "options": [
      "Chỉ định thầu",
      "Đấu thầu hạn chế",
      "Đấu thầu rộng rãi",
      "Mua sắm trực tiếp"
    ],
    "correct_answer": "Đấu thầu rộng rãi",
    "explanation": "Đấu thầu rộng rãi cho phép tất cả nhà thầu đủ điều kiện tham gia, đây là hình thức mặc định cho phần lớn gói thầu thông thường."
  },
  {
    "question": "Điều nào sau đây ĐÚNG về đấu thầu?",
    "options": [
      "Nhà thầu chào giá thấp nhất luôn thắng",
      "Hồ sơ phải đáp ứng yêu cầu kỹ thuật và năng lực trước khi xét giá",
      "Đấu thầu tư nhân phải tuân theo Luật Đấu thầu 2023",
      "Subcontractor được tính đầy đủ kinh nghiệm như tổng thầu"
    ],
    "correct_answer": "Hồ sơ phải đáp ứng yêu cầu kỹ thuật và năng lực trước khi xét giá",
    "explanation": "Đây là nguyên tắc cốt lõi: comply first, then compete on price. Hồ sơ không đạt kỹ thuật sẽ bị loại trước khi mở giá."
  }
]$quiz_1$::jsonb,
  true,
  false
),
(
  'cau-truc-hsmt-doc-tu-dau',
  $title_2$Cấu trúc HSMT - đọc từ đâu, theo thứ tự nào$title_2$,
  $titleen_2$Understanding Bidding Document Structure$titleen_2$,
  0,
  'quy-trinh',
  ARRAY['HSMT', 'BDS', 'qualification', 'deadline', 'bảo lãnh dự thầu']::text[],
  $objective_2$Sau bài này bạn biết cấu trúc điển hình của một HSMT, biết đọc phần nào trước, phần nào có thể lướt - và không bắt đầu làm hồ sơ trước khi nắm đủ thông tin quan trọng.$objective_2$,
  $explanation_2$HSMT (Hồ sơ mời thầu) thường dài từ 100 đến 500 trang, được chia thành nhiều phần/volume. Đừng đọc từ trang 1 theo thứ tự - bạn sẽ mất hàng giờ vào những chỗ không quan trọng trước. Thay vào đó, có 3 thứ bạn phải tìm và đọc kỹ trong 30 phút đầu tiên: điều kiện tham gia, deadline, và bảo lãnh dự thầu. Nếu một trong ba cái đó bạn không đáp ứng hoặc bỏ sót, phần còn lại của HSMT không còn ý nghĩa nữa.$explanation_2$,
  $content_2$## HSMT là gì và thường dài bao nhiêu?

HSMT (Hồ sơ mời thầu) - tiếng Anh là Bidding Document hoặc Tender Document - là toàn bộ tài liệu Chủ đầu tư phát ra để:
- Mô tả yêu cầu của gói thầu
- Đặt ra điều kiện tham gia
- Hướng dẫn cách chuẩn bị và nộp hồ sơ
- Quy định tiêu chí chấm điểm

Độ dài thực tế:
- Gói thầu mua sắm hàng hóa nhỏ: 50–100 trang
- Gói thầu xây lắp trung bình: 200–400 trang
- Gói thầu EPC/tổng thầu lớn: 500–1.000+ trang

> **Lưu ý thực tế:** Nhiều HSMT lớn còn kèm theo Technical Specifications (Yêu cầu kỹ thuật) như một tài liệu riêng, có thể dày hơn cả phần chính. Đừng bỏ qua phần này.

---

## Cấu trúc điển hình của một HSMT

Tùy gói thầu, HSMT có thể được tổ chức theo 2 kiểu phổ biến:

### Kiểu 1 - Theo Section (phổ biến với gói thầu trong nước)
Section 1:  Invitation to Bid / Thư mời thầu
Section 2:  Instructions to Bidders (ITB) / Chỉ dẫn nhà thầu
Section 3:  Bid Data Sheet (BDS) / Bảng dữ liệu đấu thầu
Section 4:  Evaluation and Qualification Criteria / Tiêu chí chấm điểm
Section 5:  Bidding Forms / Các biểu mẫu
Section 6:  Employer's Requirements / Yêu cầu của Chủ đầu tư
Section 7:  General Conditions of Contract (GCC)
Section 8:  Special Conditions of Contract (SCC)
Section 9:  Contract Forms / Mẫu hợp đồng

### Kiểu 2 - Theo Volume (phổ biến với gói thầu quốc tế, World Bank, ADB)
Volume 1:   Bidding Procedures (Quy trình đấu thầu)
Volume 2:   Employer's Requirements / Technical Specifications
Volume 3:   Conditions of Contract & Contract Forms

> **Lưu ý thực tế:** Dù HSMT được tổ chức theo kiểu nào, logic vẫn giống nhau: phần đầu nói về quy trình và điều kiện tham gia, phần giữa nói về yêu cầu kỹ thuật, phần cuối là điều khoản hợp đồng.

---

## 3 thứ phải đọc trong 30 phút đầu

Khi nhận HSMT, trước khi làm bất cứ điều gì khác, hãy tìm và đọc kỹ 3 mục này:

### Thứ 1 - Điều kiện tham gia (Eligibility / Qualification Requirements)

Thường nằm ở: Section 2 (ITB), Section 4, hoặc Annex to ITB.

Cần check:
- Loại hình doanh nghiệp được phép tham gia
- Yêu cầu năng lực tài chính (doanh thu, vốn lưu động)
- Yêu cầu kinh nghiệm tương tự (số hợp đồng, giá trị, loại công việc)
- Nhân sự chủ chốt (key personnel)
- Thiết bị (nếu là gói xây lắp)

**Tại sao đọc trước?** Nếu công ty bạn không đáp ứng điều kiện tham gia, không cần đọc thêm gì nữa - hoặc phải xem xét liên danh (JV).

---

### Thứ 2 - Deadline & thời hạn hiệu lực (Deadline + Bid Validity)

Thường nằm ở: BDS (Bid Data Sheet) - là bảng tóm tắt các thông số quan trọng của gói thầu.

Cần xác định ngay:
- Ngày giờ nộp thầu (Submission Deadline)
- Thời hạn hiệu lực hồ sơ (Bid Validity Period) - thường 90–120 ngày
- Deadline gửi câu hỏi làm rõ (Clarification Deadline)

**Tại sao đọc trước?** Để biết bạn có đủ thời gian chuẩn bị không. Một gói thầu deadline 14 ngày nữa với yêu cầu phức tạp là tín hiệu cần cân nhắc kỹ.

---

### Thứ 3 - Bảo lãnh dự thầu (Bid Security / Bid Bond)

Thường nằm ở: BDS + Section 2 (ITB) + Bid Security Form.

Cần xác định:
- Số tiền bảo lãnh (thường 1–3% giá gói thầu)
- Hình thức: tiền mặt hay bảo lãnh ngân hàng
- Ngân hàng được chấp nhận
- Thời hạn hiệu lực bảo lãnh

**Tại sao đọc trước?** Xin bảo lãnh ngân hàng mất thời gian (thường 3–5 ngày làm việc). Nếu bạn không tính toán từ đầu, dễ bị trễ deadline chỉ vì chưa có bảo lãnh.

---

## Phần nào đọc kỹ, phần nào có thể lướt?

| Phần | Mức độ | Lý do |
|---|---|---|
| BDS (Bid Data Sheet) | ĐỌC KỸ NGAY | Tóm tắt toàn bộ thông số quan trọng |
| Eligibility / Qualification Criteria | ĐỌC KỸ NGAY | Xác định có đủ điều kiện không |
| Technical Requirements | ĐỌC KỸ | Hiểu scope công việc thật sự |
| Evaluation Criteria | ĐỌC KỸ | Hiểu mình bị chấm theo tiêu chí gì |
| Bidding Forms | ĐỌC VÀ DÙNG | Phải điền theo đúng mẫu |
| GCC (General Conditions) | CÓ THỂ LƯỚT | Điều khoản chuẩn, ít thay đổi |
| SCC (Special Conditions) | ĐỌC KỸ | Đây là chỗ Chủ đầu tư sửa điều khoản - nhiều bẫy nằm ở đây |
| Technical Specifications chi tiết | ĐỌC KỸ KHI LÀM HỒ SƠ | Không cần đọc toàn bộ ngay từ đầu |

> **Lưu ý thực tế:** SCC (Special Conditions of Contract) là phần nhiều người bỏ qua vì nghĩ "điều khoản hợp đồng đọc sau cũng được". Sai. SCC có thể chứa các điều khoản bất lợi nghiêm trọng như phạt vượt deadline rất nặng, hoặc điều kiện nghiệm thu khắt khe.

---

## Cách đánh dấu và ghi chú khi đọc HSMT

Một workflow đơn giản hiệu quả:

**Bước 1:** Đọc BDS trước - highlight tất cả số liệu quan trọng (deadline, giá trị, validity period).

**Bước 2:** Đọc Qualification Criteria - dùng 3 màu:
- 🟢 Xanh: đã có, đủ
- 🟡 Vàng: có nhưng cần xác nhận/bổ sung
- 🔴 Đỏ: chưa có hoặc không đáp ứng

**Bước 3:** Tạo một file ghi chú riêng (có thể dùng Excel hoặc Notion) với 3 cột:
- Yêu cầu
- Tài liệu chứng minh
- Trạng thái (có / thiếu / cần bổ sung)

**Bước 4:** Chỉ bắt đầu gom tài liệu sau khi đã xong Bước 2 và 3.

---

## Warning quan trọng nhất

> ❌ **Đừng bắt đầu làm hồ sơ trước khi đọc xong phần yêu cầu năng lực.**

Lý do: Nhiều nhà thầu mới nhận HSMT là bắt đầu gom CV nhân sự, chuẩn bị báo cáo tài chính… trong khi chưa đọc kỹ Qualification Criteria. Kết quả: mất 3–5 ngày chuẩn bị tài liệu không đúng format hoặc không đúng yêu cầu, hoặc phát hiện ra mình không đủ điều kiện khi chỉ còn 2 ngày trước deadline.

**Ví dụ thật (minh họa):**
HSMT yêu cầu "similar contract value at least USD 2 million trong 5 năm gần nhất". Nhà thầu có hợp đồng USD 1.8 triệu nhưng không đọc kỹ, cứ điền vào. Đến vòng chấm năng lực thì bị loại vì không đáp ứng ngưỡng tối thiểu.$content_2$,
  $mistakes_2$[
  {
    "title": "Đọc HSMT từ trang 1 theo thứ tự",
    "description": "Cách đọc tuần tự từ trang 1 khiến bạn mất nhiều giờ vào phần mô tả chung trước khi tới được thông tin quan trọng. Nên nhảy thẳng đến BDS và Qualification Criteria trước.",
    "severity": "medium"
  },
  {
    "title": "Bỏ qua SCC (Special Conditions of Contract)",
    "description": "Nhiều nhà thầu nghĩ GCC là điều khoản chuẩn thì SCC cũng vậy. Thực ra SCC là nơi Chủ đầu tư sửa đổi, bổ sung - có thể chứa điều khoản phạt nặng hoặc điều kiện bất lợi.",
    "severity": "high"
  },
  {
    "title": "Không tạo checklist yêu cầu ngay từ đầu",
    "description": "Đọc HSMT mà không ghi chú có hệ thống dẫn đến bỏ sót yêu cầu. Khi gần deadline mới phát hiện thiếu tài liệu thì không còn thời gian xử lý.",
    "severity": "high"
  },
  {
    "title": "Không check thời hạn xin bảo lãnh ngân hàng",
    "description": "Bảo lãnh ngân hàng thường mất 3–5 ngày làm việc để xử lý. Nếu phát hiện muộn, rất dễ trễ deadline chỉ vì thiếu bảo lãnh.",
    "severity": "fatal"
  }
]$mistakes_2$::jsonb,
  $fatal_2$[]$fatal_2$::jsonb,
  ARRAY['dau-thau-la-gi', 'bao-lanh-du-thau-khong-duoc-sai', 'deadline-hieu-luc-ho-so', 'top-loi-bi-loai-chi-tu']::text[],
  $quiz_2$[
  {
    "question": "Trong 30 phút đầu đọc HSMT, bạn nên ưu tiên tìm phần nào?",
    "options": [
      "Technical Specifications chi tiết",
      "General Conditions of Contract",
      "BDS, Điều kiện tham gia, và Bảo lãnh dự thầu",
      "Danh sách biểu mẫu cần điền"
    ],
    "correct_answer": "BDS, Điều kiện tham gia, và Bảo lãnh dự thầu",
    "explanation": "Ba thứ này quyết định bạn có đủ điều kiện tham gia không và có đủ thời gian chuẩn bị không. Phần còn lại đọc sau."
  },
  {
    "question": "SCC (Special Conditions of Contract) quan trọng vì lý do gì?",
    "options": [
      "Đây là phần dài nhất trong HSMT",
      "Đây là nơi Chủ đầu tư sửa đổi điều khoản chuẩn - có thể chứa điều khoản bất lợi",
      "SCC quy định tiêu chí chấm điểm kỹ thuật",
      "SCC chỉ quan trọng sau khi trúng thầu"
    ],
    "correct_answer": "Đây là nơi Chủ đầu tư sửa đổi điều khoản chuẩn - có thể chứa điều khoản bất lợi",
    "explanation": "GCC là template chuẩn, SCC là phần Chủ đầu tư customize. Nhiều bẫy về phạt vi phạm, điều kiện nghiệm thu nằm ở SCC."
  },
  {
    "question": "Khi nào nên bắt đầu gom tài liệu chuẩn bị hồ sơ?",
    "options": [
      "Ngay khi nhận được HSMT",
      "Sau khi đọc xong toàn bộ HSMT từ đầu đến cuối",
      "Sau khi đọc xong phần Qualification Criteria và lập checklist yêu cầu",
      "Sau khi gửi câu hỏi làm rõ và nhận trả lời"
    ],
    "correct_answer": "Sau khi đọc xong phần Qualification Criteria và lập checklist yêu cầu",
    "explanation": "Phải biết chính xác yêu cầu trước khi gom tài liệu, tránh lãng phí thời gian chuẩn bị sai."
  }
]$quiz_2$::jsonb,
  true,
  false
),
(
  'top-loi-bi-loai-chi-tu',
  $title_3$Top lỗi bị loại chí tử trong đấu thầu$title_3$,
  $titleen_3$Fatal Errors in Bidding - The Complete List$titleen_3$,
  1,
  'fatal-errors',
  ARRAY['lỗi chí tử', 'fatal errors', 'bảo lãnh dự thầu', 'deadline', 'compliance']::text[],
  $objective_3$Sau bài này bạn biết những lỗi nào khiến hồ sơ bị loại ngay lập tức - không thể cứu vãn - và có checklist 10 mục để kiểm tra trước khi nộp.$objective_3$,
  $explanation_3$Trong đấu thầu, có hai loại lỗi: lỗi có thể được yêu cầu làm rõ hoặc bổ sung, và lỗi chí tử - tức là lỗi mà Chủ đầu tư bắt buộc phải loại hồ sơ ngay, không cần xem xét thêm. Lỗi chí tử thường liên quan đến bảo lãnh, tư cách pháp lý, deadline, hoặc không tuân thủ yêu cầu bắt buộc. Biết trước những lỗi này là bước đầu tiên để không bao giờ mắc phải.$explanation_3$,
  $content_3$## "Lỗi chí tử" là gì?

Lỗi chí tử (fatal error / ground for rejection) là những sai sót khiến hồ sơ bị loại **ngay lập tức**, không phụ thuộc vào hồ sơ có tốt đến đâu ở các phần khác.

Tại sao không thể cứu? Vì Luật Đấu thầu và HSMT quy định rõ: với những lỗi này, Chủ đầu tư **bắt buộc** phải loại - không có quyền xem xét ngoại lệ. Ngay cả khi hội đồng chấm thầu muốn bỏ qua, họ cũng không thể làm vậy mà không vi phạm quy định.

> **Lưu ý thực tế:** Một số lỗi là fatal theo Luật Đấu thầu 2023. Một số khác là fatal vì HSMT quy định rõ "non-compliant" hoặc "shall be rejected". Cần đọc cả hai nguồn.

---

## Nhóm 1 - Lỗi hồ sơ pháp lý

### Lỗi 1: Bảo lãnh dự thầu sai hoặc thiếu

Đây là lỗi chí tử phổ biến nhất.

Các dạng sai:
- Thiếu bảo lãnh (quên không nộp kèm)
- Số tiền thấp hơn yêu cầu (ví dụ: HSMT yêu cầu 500 triệu, nộp 490 triệu)
- Thời hạn hiệu lực bảo lãnh không đủ (phải cover bid validity + thường thêm 30 ngày)
- Sai hình thức (HSMT yêu cầu bank guarantee nhưng nộp tiền mặt hoặc ngược lại)
- Không đúng mẫu (HSMT có mẫu kèm theo nhưng dùng mẫu của ngân hàng)
- Ngân hàng phát hành không nằm trong danh sách được chấp nhận

**Ví dụ thật (minh họa):**
HSMT yêu cầu bid security có hiệu lực đến ngày 30/9/2024 (bid validity 90 ngày + 30 ngày buffer). Nhà thầu xin bảo lãnh hiệu lực đến 31/8/2024. Hồ sơ bị loại ngay vòng mở thầu.

---

### Lỗi 2: Tư cách pháp lý không hợp lệ

- Công ty đang trong tình trạng giải thể, phá sản, hoặc bị đình chỉ hoạt động
- Người ký hồ sơ không có thẩm quyền (không phải đại diện pháp luật hoặc không có giấy ủy quyền hợp lệ)
- Công ty bị cấm tham gia đấu thầu (theo danh sách đen của Bộ KH&ĐT)
- Nhà thầu có liên quan đến đơn vị tư vấn lập HSMT (conflict of interest)

---

### Lỗi 3: Chữ ký và con dấu sai

- Thiếu chữ ký trên Đơn dự thầu (Bid Submission Form / Letter of Bid)
- Chữ ký không đúng người (ký tắt, ký thay không có ủy quyền)
- Thiếu con dấu (với doanh nghiệp VN vẫn còn yêu cầu dấu)
- Đơn dự thầu không điền đúng thông tin (để trống giá, để trống ngày)

---

## Nhóm 2 - Lỗi nộp hồ sơ

### Lỗi 4: Nộp trễ deadline

**Không có ngoại lệ.** Dù trễ 1 phút, hồ sơ vẫn bị từ chối không mở.

Các tình huống thường gặp:
- Tắc đường khi mang hồ sơ cứng
- Upload chậm trên hệ thống e-procurement
- Nhầm múi giờ (với gói thầu quốc tế)
- Hệ thống lỗi nhưng không có bằng chứng ghi nhận

> **Lưu ý thực tế:** Với đấu thầu online, nên upload hoàn chỉnh trước deadline ít nhất 2–3 tiếng. Upload đến phút chót rủi ro rất cao nếu đường truyền chậm hoặc hệ thống có vấn đề.

---

### Lỗi 5: Thiếu volume / phần hồ sơ bắt buộc

HSMT thường yêu cầu nộp đủ: Technical Proposal + Financial Proposal (hoặc Vol 1 + Vol 2).

Nếu thiếu một phần, hồ sơ bị loại toàn bộ - kể cả phần còn lại hoàn hảo.

---

### Lỗi 6: Sai địa điểm nộp hoặc sai hòm thư (với đấu thầu online)

- Nộp hồ sơ cứng đến sai địa điểm
- Upload lên sai gói thầu trên hệ thống
- Gửi email thay vì upload (nếu HSMT yêu cầu nộp qua cổng)

---

## Nhóm 3 - Lỗi năng lực

### Lỗi 7: Không đáp ứng ngưỡng kinh nghiệm tương tự tối thiểu

Qualification Criteria thường có ngưỡng tối thiểu (minimum threshold). Nếu không đạt ngưỡng này, hồ sơ bị loại - không cần xem điểm kỹ thuật.

Ví dụ: "Minimum 2 similar contracts, each with contract value not less than USD 1 million, completed within the last 5 years."

Các lỗi phổ biến:
- Hợp đồng chưa có nghiệm thu/completion certificate
- Hợp đồng là subcontract (không được tính)
- Hợp đồng ngoài thời hạn quy định
- Similar nature không phù hợp (sai loại công việc)

---

### Lỗi 8: Không đáp ứng yêu cầu tài chính tối thiểu

Thường là: doanh thu hàng năm (average annual turnover) hoặc vốn lưu động (net working capital / liquid assets).

Ví dụ: "Average annual turnover of at least USD 5 million over the last 3 years."

Nếu không đáp ứng → bị loại thẳng ở vòng chấm năng lực.

---

## Nhóm 4 - Lỗi kỹ thuật

### Lỗi 9: Không tuân thủ yêu cầu kỹ thuật bắt buộc (Material Deviation)

Một số yêu cầu kỹ thuật được đánh dấu là "mandatory" hoặc "shall" - không phải "should" hay "may". Không đáp ứng những yêu cầu này tạo ra "material deviation" và dẫn đến bị loại.

Ví dụ: HSMT yêu cầu thiết bị phải đạt chuẩn ISO 9001, nhà thầu đề xuất thiết bị chưa có chứng chỉ này.

---

### Lỗi 10: Đề xuất thay thế không được phép (Unauthorized Alternative)

Nhà thầu đề xuất giải pháp thay thế (alternative) trong khi HSMT không cho phép alternative bid → bị loại toàn bộ hồ sơ hoặc chỉ loại phần alternative.

---

## Checklist 10 mục trước khi nộp thầu

Dán lên bàn làm việc. Check từng mục trước khi nộp:
☐ 1. Bảo lãnh dự thầu: đủ số tiền, đúng hình thức, đủ thời hạn, đúng mẫu, ngân hàng hợp lệ
☐ 2. Đơn dự thầu (Letter of Bid): có chữ ký đúng người, có con dấu (nếu yêu cầu), điền đầy đủ
☐ 3. Nộp đúng deadline: set reminder trước 3 tiếng, không chờ phút chót
☐ 4. Nộp đủ volume: Technical + Financial (hoặc theo yêu cầu HSMT)
☐ 5. Đúng địa điểm / đúng cổng nộp
☐ 6. Kinh nghiệm tương tự: đủ số lượng, đủ giá trị, trong thời hạn, có nghiệm thu
☐ 7. Tài chính: doanh thu / vốn lưu động đáp ứng ngưỡng tối thiểu
☐ 8. Nhân sự chủ chốt: đủ theo yêu cầu, CV đúng format, có chữ ký xác nhận
☐ 9. Không có material deviation trong đề xuất kỹ thuật
☐ 10. Người ký hồ sơ có thẩm quyền (hoặc có giấy ủy quyền kèm theo)$content_3$,
  $mistakes_3$[
  {
    "title": "Nhầm ngày hiệu lực bảo lãnh với ngày hiệu lực hồ sơ",
    "description": "Thời hạn hiệu lực bảo lãnh phải DÀI HƠN bid validity period - thường thêm 30 ngày. Nhiều người xin bảo lãnh bằng đúng bid validity là đã sai.",
    "severity": "fatal"
  },
  {
    "title": "Upload hồ sơ online vào phút chót",
    "description": "Hệ thống e-procurement chậm, file nặng, đường truyền lỗi - tất cả đều có thể khiến bạn trễ deadline dù đã ngồi trước màn hình. Upload xong toàn bộ trước ít nhất 2-3 tiếng.",
    "severity": "fatal"
  },
  {
    "title": "Tự tin rằng hợp đồng subcontract được tính kinh nghiệm",
    "description": "Hầu hết HSMT chỉ chấp nhận hợp đồng mà công ty bạn là prime contractor (tổng thầu). Hợp đồng subcontract (nhà thầu phụ) thường không được tính.",
    "severity": "fatal"
  },
  {
    "title": "Ký hồ sơ bằng chữ ký scan thay vì chữ ký gốc",
    "description": "Với hồ sơ cứng, một số Chủ đầu tư yêu cầu chữ ký tươi (wet signature). Chữ ký scan hoặc chữ ký in không hợp lệ.",
    "severity": "high"
  }
]$mistakes_3$::jsonb,
  $fatal_3$[
  {
    "description": "Bảo lãnh dự thầu thiếu hoặc không hợp lệ (sai số tiền, sai thời hạn, sai hình thức, sai mẫu)",
    "law_reference": "Điều 14, Luật Đấu thầu 2023 - cần verify"
  },
  {
    "description": "Nộp hồ sơ sau thời điểm đóng thầu (submission deadline)",
    "law_reference": "Điều 15, Luật Đấu thầu 2023 - cần verify"
  },
  {
    "description": "Nhà thầu không đáp ứng điều kiện tư cách hợp lệ (đang bị cấm thầu, giải thể, phá sản)",
    "law_reference": "Điều 5, Luật Đấu thầu 2023 - cần verify"
  },
  {
    "description": "Không đáp ứng ngưỡng tối thiểu về kinh nghiệm tương tự theo quy định HSMT",
    "law_reference": "Quy định tại HSMT - không có điều luật cụ thể"
  },
  {
    "description": "Thiếu chữ ký hoặc chữ ký không hợp lệ trên Đơn dự thầu",
    "law_reference": "Theo quy định cụ thể của từng HSMT"
  },
  {
    "description": "Hồ sơ có material deviation so với yêu cầu kỹ thuật bắt buộc",
    "law_reference": "Theo tiêu chí đánh giá quy định trong HSMT"
  },
  {
    "description": "Nhà thầu có conflict of interest với đơn vị tư vấn lập HSMT",
    "law_reference": "Điều 16, Luật Đấu thầu 2023 - cần verify"
  },
  {
    "description": "Không đủ năng lực tài chính tối thiểu (annual turnover / working capital)",
    "law_reference": "Theo tiêu chí đánh giá quy định trong HSMT"
  }
]$fatal_3$::jsonb,
  ARRAY['bao-lanh-du-thau-khong-duoc-sai', 'kinh-nghiem-tuong-tu-yeu-cau-kho-nhat', 'deadline-hieu-luc-ho-so', 'cau-truc-hsmt-doc-tu-dau']::text[],
  $quiz_3$[
  {
    "question": "Hồ sơ bị loại vì \"lỗi chí tử\" nghĩa là gì?",
    "options": [
      "Hồ sơ bị trừ điểm nặng nhưng vẫn được xem xét",
      "Hồ sơ bị loại ngay lập tức, không thể cứu vãn dù các phần khác hoàn hảo",
      "Hồ sơ được giữ lại nhưng phải bổ sung tài liệu trong 5 ngày",
      "Chủ đầu tư có quyền quyết định bỏ qua tùy trường hợp"
    ],
    "correct_answer": "Hồ sơ bị loại ngay lập tức, không thể cứu vãn dù các phần khác hoàn hảo",
    "explanation": "Fatal error là grounds for mandatory rejection. Chủ đầu tư không có quyền xem xét ngoại lệ."
  },
  {
    "question": "Thời hạn hiệu lực bảo lãnh dự thầu phải tính như thế nào?",
    "options": [
      "Bằng đúng bid validity period",
      "Ngắn hơn bid validity để tiết kiệm phí ngân hàng",
      "Dài hơn bid validity period - thường thêm 28-30 ngày",
      "Không quan trọng miễn là còn hiệu lực khi nộp thầu"
    ],
    "correct_answer": "Dài hơn bid validity period - thường thêm 28-30 ngày",
    "explanation": "Bảo lãnh phải cover hết bid validity và thêm buffer để Chủ đầu tư có thời gian yêu cầu gia hạn nếu cần."
  },
  {
    "question": "Hợp đồng subcontract có được tính vào kinh nghiệm tương tự không?",
    "options": [
      "Được tính đầy đủ như hợp đồng tổng thầu",
      "Được tính 50% giá trị",
      "Thường KHÔNG được tính - phần lớn HSMT chỉ chấp nhận prime contractor",
      "Tùy Chủ đầu tư quyết định"
    ],
    "correct_answer": "Thường KHÔNG được tính - phần lớn HSMT chỉ chấp nhận prime contractor",
    "explanation": "Đây là một trong những bẫy phổ biến nhất. Cần đọc kỹ định nghĩa \"similar experience\" trong từng HSMT cụ thể."
  }
]$quiz_3$::jsonb,
  true,
  true
),
(
  'bao-lanh-du-thau-khong-duoc-sai',
  $title_4$Bảo lãnh dự thầu - không được sai$title_4$,
  $titleen_4$Bid Security / Bid Bond - Zero Tolerance$titleen_4$,
  1,
  'bao-lanh',
  ARRAY['bảo lãnh dự thầu', 'bid security', 'bid bond', 'ngân hàng', 'fatal errors']::text[],
  $objective_4$Sau bài này bạn biết bảo lãnh dự thầu là gì, 2 hình thức khác nhau ra sao, và cách đọc yêu cầu bảo lãnh trong HSMT để không bao giờ mắc lỗi chí tử này.$objective_4$,
  $explanation_4$Bảo lãnh dự thầu (Bid Security / Bid Bond) là một khoản tiền đảm bảo bạn cam kết nghiêm túc khi tham gia thầu. Nếu bạn thắng mà không ký hợp đồng, hoặc rút hồ sơ sau deadline, khoản này sẽ bị tịch thu. Đây là yêu cầu "zero tolerance" trong đấu thầu - sai một chi tiết nhỏ là bị loại ngay, không có cơ hội sửa.$explanation_4$,
  $content_4$## Bảo lãnh dự thầu là gì? (ELI5)

Hãy nghĩ như thế này: bạn đang đặt cọc để nói với Chủ đầu tư rằng "Tôi tham gia thật sự, không phải cho vui."

Bảo lãnh dự thầu (Bid Security) là khoản tiền hoặc cam kết tài chính mà nhà thầu phải nộp kèm hồ sơ. Mục đích:
- Đảm bảo nhà thầu không rút hồ sơ tùy tiện sau khi đã nộp
- Đảm bảo nhà thầu sẽ ký hợp đồng nếu trúng thầu
- Đảm bảo nhà thầu sẽ nộp Performance Bond (bảo lãnh thực hiện hợp đồng) đúng hạn

Khoản này thường chiếm **1–3% giá gói thầu**. Với gói thầu lớn, đây là số tiền không nhỏ.

---

## 2 hình thức bảo lãnh dự thầu

### Hình thức 1 - Tiền mặt (Cash Deposit)

Nhà thầu chuyển tiền vào tài khoản được chỉ định trong HSMT.

**Ưu điểm:**
- Đơn giản, nhanh
- Không cần qua ngân hàng phát hành

**Nhược điểm:**
- Tiền bị "đóng băng" trong suốt bid validity period
- Rủi ro nếu Chủ đầu tư chậm hoàn trả

**Khi nào dùng:** Gói thầu trong nước, giá trị nhỏ, HSMT cho phép cash deposit.

---

### Hình thức 2 - Bảo lãnh ngân hàng (Bank Guarantee / Letter of Guarantee)

Ngân hàng cam kết thay mặt nhà thầu: nếu nhà thầu vi phạm, ngân hàng sẽ trả tiền theo yêu cầu của Chủ đầu tư.

**Ưu điểm:**
- Không phải đóng băng tiền mặt
- Chuyên nghiệp, được ưa chuộng trong đấu thầu quốc tế

**Nhược điểm:**
- Phải mất 3–5 ngày làm việc để ngân hàng xử lý
- Có phí phát hành (thường 0.1–0.3%/năm)
- Phải đáp ứng hạn mức tín dụng tại ngân hàng

**Khi nào dùng:** Gói thầu quốc tế, gói thầu lớn, hoặc khi HSMT yêu cầu.

> **Lưu ý thực tế:** Đa số HSMT quốc tế theo chuẩn World Bank, ADB chỉ chấp nhận Bank Guarantee - không nhận tiền mặt. Đọc kỹ trước khi quyết định hình thức nào.

---

## 5 thứ phải check khi đọc yêu cầu bảo lãnh trong HSMT

Mỗi lần đọc HSMT, hãy tìm phần Bid Security và check đủ 5 điểm này:

### Check 1 - Số tiền (Amount)

HSMT thường ghi theo 2 cách:
- Cách 1: Số tiền cố định - ví dụ: "Bid Security: USD 50,000"
- Cách 2: Tỷ lệ phần trăm - ví dụ: "2% of bid price" (khi đó bạn tính dựa trên giá bạn dự định chào)

**Lưu ý:** Số tiền phải bằng ĐÚNG hoặc cao hơn yêu cầu. Thấp hơn dù chỉ 1 USD cũng bị loại.

---

### Check 2 - Thời hạn hiệu lực (Validity Period)

Công thức chuẩn:
Hiệu lực bảo lãnh = Bid Validity Period + 28 ngày (hoặc 30 ngày, tùy HSMT)

Ví dụ:
- Submission Deadline: 01/07/2024
- Bid Validity: 90 ngày → hết hạn 29/09/2024
- Hiệu lực bảo lãnh tối thiểu: 29/10/2024 (thêm 30 ngày)

> **Lưu ý thực tế:** Một số HSMT ghi rõ ngày hết hạn cụ thể thay vì công thức. Trong trường hợp đó, dùng ngày đó luôn - không cần tự tính.

---

### Check 3 - Hình thức (Form)

HSMT thường ghi rõ:
- Chấp nhận cash deposit, bank guarantee, hay cả hai?
- Nếu bank guarantee: unconditional hay conditional?

**Unconditional (on demand)** = Chủ đầu tư gọi phát là ngân hàng trả, không cần chứng minh vi phạm. Đây là loại được yêu cầu trong hầu hết HSMT quốc tế.

**Conditional** = Ngân hàng chỉ trả khi có bằng chứng nhà thầu vi phạm. Ít phổ biến hơn.

---

### Check 4 - Mẫu bảo lãnh (Form Template)

Nhiều HSMT kèm theo mẫu Bid Security Form. Nếu có mẫu → **bắt buộc phải dùng đúng mẫu đó**.

Không được tự ý dùng mẫu của ngân hàng nếu HSMT đã cung cấp mẫu riêng.

**Ví dụ thật (minh họa):**
HSMT cung cấp Bid Security Form ở Annex A với ngôn ngữ cụ thể: "This guarantee shall expire on [date]..." Ngân hàng của nhà thầu tự soạn mẫu khác, dùng ngôn ngữ khác. Hồ sơ bị loại vì không tuân thủ mẫu quy định.

---

### Check 5 - Ngân hàng được chấp nhận (Eligible Bank)

HSMT có thể giới hạn:
- Chỉ ngân hàng có trụ sở/chi nhánh trong nước
- Chỉ ngân hàng trong danh sách được phê duyệt
- Ngân hàng có rating tối thiểu (với gói thầu quốc tế)

**Lưu ý:** Với gói thầu ADB/World Bank, thường yêu cầu "reputable bank" - ngân hàng quốc tế uy tín. Một số ngân hàng nhỏ của Việt Nam có thể không được chấp nhận.

---

## Khi nào bảo lãnh bị tịch thu?

Có 3 trường hợp chính:

**1. Nhà thầu rút hồ sơ sau deadline**
Sau khi hết thời gian rút hồ sơ (thường trùng hoặc gần submission deadline), bạn không được rút mà không mất bảo lãnh.

**2. Nhà thầu trúng thầu nhưng từ chối ký hợp đồng**
Đây là vi phạm nghiêm trọng nhất. Bảo lãnh bị tịch thu ngay.

**3. Nhà thầu trúng thầu nhưng không nộp Performance Bond đúng hạn**
Sau khi trúng thầu, nhà thầu phải nộp bảo lãnh thực hiện hợp đồng (Performance Bond) trong thời hạn quy định. Trễ hạn này cũng có thể dẫn đến tịch thu bid security.

---

## Ví dụ đoạn yêu cầu bảo lãnh trong HSMT thật (minh họa)
ITB Clause 19.1:
The Bidder shall furnish as part of its Bid, a Bid Security
in the amount of USD 30,000 (thirty thousand US dollars)
or equivalent in a freely convertible currency.
BDS ITB 19.1:
The Bid Security amount is: USD 30,000
The Bid Security shall be valid for 28 days beyond the
Bid Validity Period.
Acceptable form: Bank Guarantee only.
Bank Guarantee form: As per Annex A.
Issuing bank must be: a reputable bank located in the
Employer's country or abroad.

**Phân tích từng dòng:**
- Số tiền: USD 30,000 - fixed amount, không phải %
- Thời hạn: bid validity + 28 ngày
- Hình thức: Bank Guarantee ONLY - không nhận tiền mặt
- Mẫu: Annex A - phải dùng đúng mẫu
- Ngân hàng: reputable bank - cần confirm ngân hàng của mình có được chấp nhận không$content_4$,
  $mistakes_4$[
  {
    "title": "Xin bảo lãnh hiệu lực bằng đúng bid validity",
    "description": "Phải cộng thêm 28-30 ngày buffer. Rất nhiều nhà thầu tính bid validity = 90 ngày rồi xin bảo lãnh 90 ngày - sai. Phải là 90 + 28 = 118 ngày trở lên.",
    "severity": "fatal"
  },
  {
    "title": "Xin bảo lãnh quá sát deadline nộp thầu",
    "description": "Ngân hàng cần 3-5 ngày làm việc. Nếu bắt đầu xin bảo lãnh 2 ngày trước deadline, rủi ro rất cao. Nên xin trước ít nhất 5-7 ngày làm việc.",
    "severity": "high"
  },
  {
    "title": "Không kiểm tra ngân hàng có nằm trong danh sách được chấp nhận không",
    "description": "Với gói thầu ADB/WB, không phải ngân hàng nào cũng được chấp nhận. Confirm trước khi xin phát hành.",
    "severity": "fatal"
  },
  {
    "title": "Dùng mẫu của ngân hàng thay vì mẫu đính kèm HSMT",
    "description": "Khi HSMT đã cung cấp Bid Security Form template, bắt buộc phải dùng đúng mẫu đó. Ngân hàng thường có mẫu riêng - hãy yêu cầu họ điều chỉnh theo mẫu HSMT.",
    "severity": "fatal"
  }
]$mistakes_4$::jsonb,
  $fatal_4$[
  {
    "description": "Thiếu bảo lãnh dự thầu - không nộp kèm hồ sơ",
    "law_reference": "Điều 14, Luật Đấu thầu 2023 - cần verify"
  },
  {
    "description": "Số tiền bảo lãnh thấp hơn yêu cầu HSMT",
    "law_reference": "Theo quy định cụ thể của HSMT"
  },
  {
    "description": "Thời hạn hiệu lực bảo lãnh không đủ (ngắn hơn bid validity + buffer)",
    "law_reference": "Theo quy định cụ thể của HSMT"
  },
  {
    "description": "Ngân hàng phát hành không thuộc danh sách được Chủ đầu tư chấp nhận",
    "law_reference": "Theo quy định cụ thể của HSMT"
  },
  {
    "description": "Không dùng đúng mẫu bảo lãnh khi HSMT đã cung cấp template",
    "law_reference": "Theo quy định cụ thể của HSMT"
  }
]$fatal_4$::jsonb,
  ARRAY['top-loi-bi-loai-chi-tu', 'deadline-hieu-luc-ho-so', 'cau-truc-hsmt-doc-tu-dau']::text[],
  $quiz_4$[
  {
    "question": "Thời hạn hiệu lực bảo lãnh dự thầu nên tính như thế nào?",
    "options": [
      "Từ ngày nộp thầu đến ngày hết bid validity",
      "Bằng đúng bid validity period",
      "Bid validity period cộng thêm 28-30 ngày buffer",
      "6 tháng là đủ cho mọi trường hợp"
    ],
    "correct_answer": "Bid validity period cộng thêm 28-30 ngày buffer",
    "explanation": "Buffer thêm để Chủ đầu tư có thời gian yêu cầu gia hạn nếu quá trình chấm thầu kéo dài."
  },
  {
    "question": "Khi HSMT kèm theo mẫu Bid Security Form, nhà thầu phải làm gì?",
    "options": [
      "Dùng mẫu đó hoặc mẫu tương đương của ngân hàng đều được",
      "Bắt buộc dùng đúng mẫu HSMT cung cấp, yêu cầu ngân hàng điều chỉnh theo",
      "Dùng mẫu nào cũng được miễn là có đủ thông tin",
      "Chỉ áp dụng với gói thầu quốc tế, gói trong nước linh hoạt hơn"
    ],
    "correct_answer": "Bắt buộc dùng đúng mẫu HSMT cung cấp, yêu cầu ngân hàng điều chỉnh theo",
    "explanation": "Đây là yêu cầu bắt buộc. Ngân hàng hoàn toàn có thể phát hành theo mẫu HSMT nếu bạn yêu cầu."
  },
  {
    "question": "Bảo lãnh dự thầu bị tịch thu trong trường hợp nào?",
    "options": [
      "Nhà thầu không trúng thầu",
      "Hồ sơ bị loại ở vòng kỹ thuật",
      "Nhà thầu trúng thầu nhưng từ chối ký hợp đồng",
      "Nhà thầu nộp hồ sơ trễ 1 ngày"
    ],
    "correct_answer": "Nhà thầu trúng thầu nhưng từ chối ký hợp đồng",
    "explanation": "Bảo lãnh bị tịch thu khi nhà thầu vi phạm cam kết: rút hồ sơ sau deadline, từ chối ký hợp đồng, hoặc không nộp Performance Bond đúng hạn."
  }
]$quiz_4$::jsonb,
  true,
  true
),
(
  'kinh-nghiem-tuong-tu-yeu-cau-kho-nhat',
  $title_5$Kinh nghiệm tương tự - yêu cầu khó nhất$title_5$,
  $titleen_5$Similar Experience - The Hardest Requirement$titleen_5$,
  1,
  'kinh-nghiem',
  ARRAY['kinh nghiệm tương tự', 'similar experience', 'completion certificate', 'subcontract', 'JV']::text[],
  $objective_5$Sau bài này bạn biết "kinh nghiệm tương tự" là gì, cần chứng minh bằng tài liệu nào, và tránh được 4 bẫy phổ biến nhất khiến hợp đồng không được tính.$objective_5$,
  $explanation_5$"Kinh nghiệm tương tự" (similar experience) là yêu cầu Chủ đầu tư muốn biết: bạn đã từng làm công việc giống như thế này chưa, và làm ở quy mô ra sao. Đây thường là yêu cầu khó nhất vì nó vừa đòi hỏi đúng loại công việc (similar nature), vừa đòi hỏi đúng quy mô (similar scale), vừa cần đầy đủ tài liệu chứng minh. Thiếu một trong ba là bị loại.$explanation_5$,
  $content_5$## "Kinh nghiệm tương tự" thực sự nghĩa là gì?

Khi HSMT yêu cầu "similar experience", họ muốn biết 2 điều:

### Chiều 1 - Similar Nature (Tương đồng về bản chất công việc)
Loại công việc bạn đã làm có giống loại công việc trong gói thầu này không?

Ví dụ:
- Gói thầu: Xây dựng bệnh viện → cần kinh nghiệm xây dựng công trình y tế, không phải xây nhà ở
- Gói thầu: Cung cấp phần mềm ERP → cần kinh nghiệm triển khai ERP, không phải làm website
- Gói thầu: Vận hành và bảo trì hệ thống điện → cần O&M electrical, không phải thi công mới

### Chiều 2 - Similar Scale (Tương đồng về quy mô/giá trị)
Hợp đồng của bạn đã làm có giá trị/quy mô đủ lớn không?

HSMT thường quy định ngưỡng tối thiểu:
- "At least 1 contract with value not less than USD 2 million"
- "Minimum 2 contracts of similar nature, each completed within 5 years"

> **Lưu ý thực tế:** Một số HSMT còn yêu cầu cả "similar complexity" (độ phức tạp tương đương). Đọc kỹ từng từ trong phần qualification criteria, không chỉ đọc lướt tiêu đề.

---

## Ví dụ đoạn yêu cầu trong HSMT thật (minh họa)
Section 4 - Qualification Criteria
4.2 Experience
The Bidder shall have experience as prime contractor
(or member of JV) in the implementation of at least
TWO (2) contracts within the last FIVE (5) years, each
with a value of at least USD 1,500,000, that have been
successfully completed and are similar to the proposed
Works (supply and installation of mechanical and
electrical systems in commercial or industrial buildings).

**Phân tích:**
- Số lượng: tối thiểu 2 hợp đồng
- Thời gian: hoàn thành trong 5 năm gần nhất (từ bid submission date)
- Giá trị: mỗi hợp đồng ít nhất USD 1,500,000
- Tư cách: phải là prime contractor hoặc thành viên JV (không phải subcontractor)
- Similar nature: M&E systems trong commercial/industrial buildings
- Điều kiện: đã hoàn thành (successfully completed)

---

## Tài liệu cần chuẩn bị để chứng minh kinh nghiệm

### 1. Hợp đồng (Contract / Purchase Order)

Cần thể hiện:
- Tên nhà thầu (phải khớp với tên công ty hiện tại)
- Loại công việc (similar nature)
- Giá trị hợp đồng (similar scale)
- Ngày ký

> **Lưu ý:** Nếu công ty đổi tên hoặc sáp nhập, cần có giấy tờ chứng minh kế thừa pháp lý.

---

### 2. Nghiệm thu / Completion Certificate (Acceptance Certificate)

Đây thường là tài liệu quan trọng nhất và hay bị thiếu nhất.

Tài liệu này chứng minh hợp đồng đã **hoàn thành**, không chỉ đang thực hiện.

Các tên gọi khác nhau:
- Completion Certificate
- Acceptance Certificate
- Taking Over Certificate
- Certificate of Final Completion
- Biên bản nghiệm thu hoàn thành

**Ví dụ thật (minh họa):**
Nhà thầu có hợp đồng trị giá USD 3 triệu, đang thực hiện dở dang (80% khối lượng xong). HSMT yêu cầu hợp đồng "successfully completed" - hợp đồng này không được tính.

---

### 3. Biên bản bàn giao (Handover Record / Delivery Record)

Với một số loại hàng hóa/thiết bị, Chủ đầu tư có thể yêu cầu biên bản bàn giao thay vì hoặc kèm theo completion certificate.

---

### 4. Tài liệu bổ sung (tùy HSMT yêu cầu)

Một số HSMT còn yêu cầu:
- Reference letter từ chủ đầu tư cũ
- Performance evaluation
- Invoices để chứng minh giá trị thanh toán thực tế

---

## 4 bẫy phổ biến nhất

### Bẫy 1 - Hợp đồng subcontract không được tính

Đây là bẫy phổ biến nhất và gây thiệt hại nhiều nhất.

**Vấn đề:** Công ty bạn từng làm thầu phụ (subcontractor) cho một tổng thầu lớn, thực hiện công việc tương tự với giá trị hàng triệu USD. Nhưng hợp đồng ký với tổng thầu, không phải với Chủ đầu tư.

**Kết quả:** Hầu hết HSMT không chấp nhận subcontract experience.

**Cách xử lý:** Nếu thiếu kinh nghiệm prime contractor, xem xét tham gia liên danh (JV) với công ty có đủ kinh nghiệm.

---

### Bẫy 2 - Hợp đồng chưa có nghiệm thu

**Vấn đề:** Hợp đồng đã hoàn thành thực tế, khách hàng hài lòng, nhưng chưa có tài liệu nghiệm thu chính thức.

**Kết quả:** Không thể chứng minh "successfully completed" → không được tính.

**Cách xử lý:** Chủ động xin completion certificate từ các khách hàng cũ ngay cả khi dự án đã xong từ lâu. Đây là việc nên làm thường xuyên, không đợi đến khi cần.

---

### Bẫy 3 - Hợp đồng quá cũ (ngoài time window)

**Vấn đề:** HSMT yêu cầu "completed within the last 5 years". Ngày hoàn thành hợp đồng được tính từ ngày trong completion certificate, không phải ngày ký hợp đồng.

**Cách tính:** Nếu submission deadline là 01/07/2024, time window là từ 01/07/2019.

**Bẫy:** Hợp đồng hoàn thành tháng 6/2019 - ngoài window 1 tháng, không được tính.

---

### Bẫy 4 - Similar nature không đúng

**Vấn đề:** Nhà thầu tự diễn giải rộng hơn yêu cầu. Ví dụ: HSMT yêu cầu kinh nghiệm "supply and installation of HVAC systems", nhà thầu khai kinh nghiệm "general building construction" - không đủ specific.

**Cách xử lý:** Đọc kỹ định nghĩa "similar" trong HSMT. Nếu không rõ, gửi câu hỏi clarification để Chủ đầu tư xác nhận loại kinh nghiệm nào được chấp nhận.

---

## Khi nào nên xem xét liên danh (JV)?

Nếu sau khi review bạn thấy:
- Thiếu kinh nghiệm tương tự
- Giá trị hợp đồng chưa đủ ngưỡng
- Chỉ có subcontract experience

→ Đây là tín hiệu nên tìm đối tác liên danh.

Trong JV, kinh nghiệm của **các thành viên** được cộng lại. Một thành viên có thể "cover" phần kinh nghiệm mà thành viên kia thiếu.

> **Lưu ý thực tế:** JV có phức tạp riêng của nó (ký kết JV Agreement, phân chia scope, ai ký hồ sơ). Sẽ có bài riêng về JV trong Tier 3.$content_5$,
  $mistakes_5$[
  {
    "title": "Khai hợp đồng subcontract như prime contractor experience",
    "description": "Nếu bị phát hiện trong quá trình verify, hồ sơ không chỉ bị loại mà còn có thể bị đánh giá là gian lận. Phải ghi rõ vai trò (prime/sub) và chỉ khai những gì được chấp nhận.",
    "severity": "fatal"
  },
  {
    "title": "Không chuẩn bị completion certificate trước",
    "description": "Xin completion certificate từ khách hàng cũ mất thời gian - đặc biệt với khách hàng lớn. Nên chủ động xin sau khi hoàn thành mỗi dự án, không đợi đến khi cần làm hồ sơ.",
    "severity": "high"
  },
  {
    "title": "Không clarify định nghĩa 'similar' khi không chắc",
    "description": "Tự diễn giải rộng hơn rồi nộp là rủi ro cao. Nếu không chắc kinh nghiệm của mình có được chấp nhận không, hãy hỏi Chủ đầu tư qua kênh clarification.",
    "severity": "high"
  },
  {
    "title": "Tính ngày completion sai (dùng ngày ký hợp đồng thay vì ngày nghiệm thu)",
    "description": "Time window được tính từ ngày hoàn thành (ngày trên completion certificate), không phải ngày ký hợp đồng. Hợp đồng ký năm 2016 nhưng nghiệm thu năm 2019 vẫn trong window 5 năm tính đến 2024.",
    "severity": "medium"
  }
]$mistakes_5$::jsonb,
  $fatal_5$[
  {
    "description": "Không đáp ứng số lượng hợp đồng tương tự tối thiểu theo yêu cầu HSMT",
    "law_reference": "Theo tiêu chí đánh giá quy định trong HSMT"
  },
  {
    "description": "Giá trị hợp đồng tương tự không đạt ngưỡng tối thiểu",
    "law_reference": "Theo tiêu chí đánh giá quy định trong HSMT"
  },
  {
    "description": "Hợp đồng khai là kinh nghiệm không có completion certificate (chưa hoàn thành)",
    "law_reference": "Theo tiêu chí đánh giá quy định trong HSMT"
  }
]$fatal_5$::jsonb,
  ARRAY['top-loi-bi-loai-chi-tu', 'quy-trinh-clarification', 'deadline-hieu-luc-ho-so']::text[],
  $quiz_5$[
  {
    "question": "HSMT yêu cầu \"2 contracts completed within 5 years\". Hợp đồng A ký năm 2017, nghiệm thu tháng 8/2019. Bid deadline là tháng 8/2024. Hợp đồng A có được tính không?",
    "options": [
      "Không - hợp đồng ký từ năm 2017, ngoài window 5 năm",
      "Có - ngày nghiệm thu (8/2019) nằm trong window 5 năm tính đến 8/2024",
      "Tùy Chủ đầu tư quyết định",
      "Không - vì đã quá 3 năm kể từ khi hoàn thành"
    ],
    "correct_answer": "Có - ngày nghiệm thu (8/2019) nằm trong window 5 năm tính đến 8/2024",
    "explanation": "Time window tính từ ngày completion certificate, không phải ngày ký hợp đồng. Tháng 8/2019 đến tháng 8/2024 là đúng 5 năm, hợp lệ."
  },
  {
    "question": "Công ty bạn đã làm subcontractor cho một dự án USD 5 triệu. Khi khai kinh nghiệm, bạn nên xử lý như thế nào?",
    "options": [
      "Khai đầy đủ vì thực tế bạn đã thực hiện công việc",
      "Không khai - subcontract thường không được chấp nhận, tránh rủi ro bị loại vì gian lận",
      "Khai một nửa giá trị để an toàn",
      "Khai nếu có xác nhận từ tổng thầu"
    ],
    "correct_answer": "Không khai - subcontract thường không được chấp nhận, tránh rủi ro bị loại vì gian lận",
    "explanation": "Hầu hết HSMT không chấp nhận subcontract. Khai mà biết không được tính là rủi ro. Nên xem xét tìm đối tác JV thay vì khai không trung thực."
  },
  {
    "question": "Tài liệu nào quan trọng nhất để chứng minh hợp đồng \"successfully completed\"?",
    "options": [
      "Hóa đơn thanh toán cuối",
      "Hợp đồng gốc có chữ ký",
      "Completion Certificate / Acceptance Certificate từ Chủ đầu tư",
      "Email xác nhận của khách hàng"
    ],
    "correct_answer": "Completion Certificate / Acceptance Certificate từ Chủ đầu tư",
    "explanation": "Completion/Acceptance Certificate là bằng chứng pháp lý duy nhất được hầu hết Chủ đầu tư chấp nhận để xác nhận hợp đồng đã hoàn thành."
  }
]$quiz_5$::jsonb,
  true,
  true
),
(
  'deadline-hieu-luc-ho-so',
  $title_6$Deadline & hiệu lực hồ sơ$title_6$,
  $titleen_6$Submission Deadline & Bid Validity Period$titleen_6$,
  1,
  'deadline',
  ARRAY['deadline', 'bid validity', 'submission deadline', 'clarification', 'e-procurement']::text[],
  $objective_6$Sau bài này bạn biết 3 loại deadline cần track trong đấu thầu, cách tính bid validity đúng, và biết lập timeline thực tế cho một gói thầu để không bao giờ bị trễ.$objective_6$,
  $explanation_6$Trong đấu thầu, "deadline" không chỉ là một ngày duy nhất - có ít nhất 3 mốc thời gian quan trọng bạn phải theo dõi song song. Ngoài ra còn có "bid validity period" - thời gian hồ sơ của bạn có hiệu lực sau khi nộp, thường là 90–120 ngày. Hiểu rõ và quản lý tốt những mốc này là kỹ năng cơ bản của người làm thầu chuyên nghiệp.$explanation_6$,
  $content_6$## 3 loại deadline cần track

### Deadline 1 - Clarification Deadline

Là ngày cuối cùng bạn được gửi câu hỏi làm rõ HSMT đến Chủ đầu tư.

Thường sớm hơn submission deadline **7–14 ngày**.

Tại sao quan trọng:
- Nếu HSMT có điều khoản mơ hồ hoặc yêu cầu không rõ ràng, đây là cơ hội duy nhất để hỏi
- Câu trả lời của Chủ đầu tư có giá trị pháp lý như Addendum (được gửi đến tất cả nhà thầu)
- Bỏ lỡ deadline này = mất quyền hỏi = phải tự diễn giải = rủi ro

> **Lưu ý thực tế:** Không nên hỏi quá sát deadline clarification. Gửi sớm để Chủ đầu tư có thời gian trả lời trước khi bạn làm xong hồ sơ.

---

### Deadline 2 - Submission Deadline (Ngày nộp thầu)

Ngày giờ chính xác bạn phải nộp hồ sơ hoàn chỉnh.

Thông tin cần ghi rõ:
- Ngày (ví dụ: 15/08/2024)
- Giờ (ví dụ: 09:00 AM - theo giờ địa phương của Chủ đầu tư)
- Múi giờ (quan trọng với gói thầu quốc tế)
- Địa điểm nộp cứng (nếu có) hoặc cổng nộp online

**Không có ngoại lệ.** Trễ 1 phút là bị từ chối không mở hồ sơ.

---

### Deadline 3 - Bid Validity Period (Thời hạn hiệu lực hồ sơ)

Không phải deadline theo nghĩa nộp, mà là khoảng thời gian hồ sơ của bạn **phải duy trì hiệu lực** sau khi nộp.

Ý nghĩa: Trong suốt thời gian này, bạn cam kết:
- Không rút hồ sơ
- Giá chào không thay đổi
- Nếu được chọn, sẵn sàng ký hợp đồng

Thường là **90–120 ngày** kể từ submission deadline.

> **Lưu ý thực tế:** Nếu quá trình chấm thầu kéo dài, Chủ đầu tư có thể yêu cầu gia hạn bid validity. Bạn có quyền từ chối (và mất bid security) hoặc đồng ý (kèm theo gia hạn bid security tương ứng).

---

## Cách tính bid validity đúng
Ngày bắt đầu tính: Submission Deadline
Ngày kết thúc: Submission Deadline + Bid Validity Period (tính theo ngày lịch)
Ví dụ:

Submission Deadline: 01/09/2024
Bid Validity: 90 ngày
Hết hạn bid validity: 30/11/2024

Hiệu lực Bid Security tối thiểu: 30/11/2024 + 28 ngày = 28/12/2024

---

## Hiệu lực bảo lãnh phải cover bid validity + buffer

Đây là điểm nhiều người nhầm:
❌ SAI: Hiệu lực bảo lãnh = Bid Validity Period
✅ ĐÚNG: Hiệu lực bảo lãnh = Bid Validity Period + 28 ngày (hoặc theo HSMT)

Lý do: Sau khi bid validity hết, Chủ đầu tư cần thêm thời gian để xử lý các thủ tục. Buffer 28 ngày là thông lệ phổ biến trong chuẩn World Bank/ADB.

---

## Timeline planning - nên bắt đầu bao lâu trước deadline?

Nguyên tắc: Làm ngược từ deadline ra ngoài.
[SUBMISSION DEADLINE]
|
-2 giờ: Upload hoàn chỉnh (với đấu thầu online)
|
-1 ngày: Final review toàn bộ hồ sơ, in ấn/đóng gói (nếu cứng)
|
-2 ngày: Internal sign-off, đóng dấu chữ ký
|
-3 ngày: Hoàn chỉnh toàn bộ nội dung hồ sơ
|
-5 ngày: Nhận bảo lãnh ngân hàng (xin trước 5-7 ngày làm việc)
|
-7 ngày: Draft hoàn chỉnh, review lần 1
|
-[N] ngày: Bắt đầu làm hồ sơ (tùy độ phức tạp)

---

## Ví dụ timeline thực tế: gói thầu 21 ngày

Gói thầu phát hành ngày 01/08/2024, submission deadline 22/08/2024 (21 ngày).
01/08 - Nhận HSMT. Đọc ngay BDS + Qualification Criteria.
02/08 - Lập checklist yêu cầu. Phân tích GAP năng lực.
03/08 - Gửi câu hỏi clarification (nếu có điều cần làm rõ).
04/08 - Bắt đầu gom tài liệu pháp lý, kinh nghiệm.
05/08 - Xin phát hành bảo lãnh ngân hàng (cần 5 ngày làm việc → có ngày 12/08).
06-12/08 - Viết Technical Proposal, chuẩn bị Financial Proposal.
12/08 - Nhận bảo lãnh ngân hàng. Kiểm tra kỹ trước khi nhận.
13-15/08 - Hoàn thiện tất cả nội dung, gộp hồ sơ.
16-19/08 - Review kỹ lần 2, ký tên đóng dấu, đóng gói.
20/08 - Final check toàn bộ theo checklist 10 mục.
21/08 sáng - Upload hoàn chỉnh (cả ngày để xử lý sự cố kỹ thuật).
22/08 - Submission deadline. Không làm gì thêm với hồ sơ.

> **Lưu ý thực tế:** 21 ngày là timeline rất ngắn. Với gói thầu phức tạp (nhiều yêu cầu kỹ thuật, nhiều volume), 21 ngày thường không đủ để làm hồ sơ chất lượng. Đây là tín hiệu cần cân nhắc có tham gia không, hoặc phải huy động đủ nguồn lực ngay từ ngày đầu.

---

## Rủi ro đặc thù với đấu thầu online (e-procurement)

Hệ thống đấu thầu điện tử ở Việt Nam (NSDT, IDA…) có những rủi ro riêng:

**1. Upload chậm:** File lớn + đường truyền chậm = upload không xong trước deadline.
Giải pháp: Nén file, upload từng phần, và upload xong toàn bộ trước ít nhất 2–3 tiếng.

**2. Hệ thống quá tải:** Nhiều nhà thầu upload cùng lúc gần deadline.
Giải pháp: Upload sớm, tránh giờ cao điểm.

**3. Lỗi kỹ thuật:** Hệ thống có thể lỗi đột ngột.
Giải pháp: Nếu gặp lỗi, chụp màn hình lập tức có timestamp, và liên hệ ngay đơn vị quản lý hệ thống. Đây là bằng chứng nếu cần khiếu nại.

**4. Upload nhầm gói thầu:** Hệ thống có nhiều gói thầu cùng lúc.
Giải pháp: Confirm lại ID gói thầu trước khi submit.$content_6$,
  $mistakes_6$[
  {
    "title": "Quên track clarification deadline",
    "description": "Nhiều người chỉ nhớ submission deadline. Đến khi có câu hỏi thì clarification deadline đã qua. Phải ghi cả 3 deadline vào lịch ngay khi nhận HSMT.",
    "severity": "high"
  },
  {
    "title": "Tính bid validity từ ngày nhận HSMT thay vì submission deadline",
    "description": "Bid validity bắt đầu tính từ ngày nộp thầu (submission deadline), không phải ngày nhận hoặc ngày ký. Tính sai dẫn đến xin bảo lãnh sai thời hạn.",
    "severity": "high"
  },
  {
    "title": "Upload online vào giờ chót",
    "description": "Đây là nguyên nhân phổ biến nhất khiến nhà thầu bỏ lỡ deadline dù chuẩn bị xong hồ sơ. Upload xong trước ít nhất 2-3 tiếng là nguyên tắc cứng.",
    "severity": "fatal"
  },
  {
    "title": "Không lập timeline ngay khi nhận HSMT",
    "description": "Nhận HSMT rồi để đó, đến tuần cuối mới bắt tay làm. Khi đó thường phát hiện thiếu tài liệu quan trọng mà không còn thời gian bổ sung.",
    "severity": "high"
  }
]$mistakes_6$::jsonb,
  $fatal_6$[
  {
    "description": "Nộp hồ sơ sau thời điểm đóng thầu - dù chỉ 1 phút",
    "law_reference": "Điều 15, Luật Đấu thầu 2023 - cần verify"
  }
]$fatal_6$::jsonb,
  ARRAY['bao-lanh-du-thau-khong-duoc-sai', 'top-loi-bi-loai-chi-tu', 'quy-trinh-clarification', 'cau-truc-hsmt-doc-tu-dau']::text[],
  $quiz_6$[
  {
    "question": "Bid validity period bắt đầu được tính từ ngày nào?",
    "options": [
      "Ngày phát hành HSMT",
      "Ngày nhà thầu nhận HSMT",
      "Ngày submission deadline (ngày nộp thầu)",
      "Ngày Chủ đầu tư mở thầu"
    ],
    "correct_answer": "Ngày submission deadline (ngày nộp thầu)",
    "explanation": "Bid validity tính từ ngày nộp thầu. Đây là mốc chuẩn để tính ngày hết hạn và hiệu lực bảo lãnh."
  },
  {
    "question": "Với gói thầu online, khi nào nên hoàn tất việc upload hồ sơ?",
    "options": [
      "Đúng submission deadline",
      "Trước submission deadline 30 phút là đủ",
      "Trước submission deadline ít nhất 2-3 tiếng",
      "Ngày hôm trước submission deadline"
    ],
    "correct_answer": "Trước submission deadline ít nhất 2-3 tiếng",
    "explanation": "Ít nhất 2-3 tiếng để có thời gian xử lý sự cố kỹ thuật nếu phát sinh. Ngày hôm trước càng tốt."
  },
  {
    "question": "Chủ đầu tư yêu cầu gia hạn bid validity. Nhà thầu có được từ chối không?",
    "options": [
      "Không - bắt buộc phải đồng ý",
      "Có - nhà thầu có thể từ chối nhưng sẽ mất bid security",
      "Có - từ chối mà không mất bid security",
      "Tùy vào lý do Chủ đầu tư đưa ra"
    ],
    "correct_answer": "Có - nhà thầu có thể từ chối nhưng sẽ mất bid security",
    "explanation": "Nhà thầu có quyền từ chối gia hạn, nhưng khi đó bid security sẽ bị tịch thu và hồ sơ không còn được xem xét."
  }
]$quiz_6$::jsonb,
  true,
  false
),
(
  'quy-trinh-clarification',
  $title_7$Clarification - hỏi đúng cách, đúng lúc$title_7$,
  $titleen_7$The Clarification Process$titleen_7$,
  1,
  'quy-trinh',
  ARRAY['clarification', 'addendum', 'HSMT', 'câu hỏi làm rõ', 'quy trình']::text[],
  $objective_7$Sau bài này bạn hiểu clarification là gì, khi nào nên hỏi, và biết cách viết một câu hỏi clarification đúng chuẩn - kèm template thực tế có thể dùng ngay.$objective_7$,
  $explanation_7$Clarification là quyền của bạn: khi HSMT có điều gì không rõ, bạn được phép hỏi Chủ đầu tư trong thời hạn quy định. Điều quan trọng là câu trả lời của Chủ đầu tư có giá trị pháp lý như Addendum và được gửi đến tất cả nhà thầu - nên bạn vừa giải quyết được thắc mắc của mình, vừa tránh bất lợi khi đối thủ nhận được thông tin mà bạn không biết. Hỏi đúng là kỹ năng, không phải hỏi vu vơ.$explanation_7$,
  $content_7$## Clarification là gì và tại sao quan trọng?

Trong quá trình chuẩn bị hồ sơ, nhà thầu thường gặp những điểm mơ hồ, mâu thuẫn hoặc không rõ trong HSMT. Thay vì tự đoán, nhà thầu có thể gửi câu hỏi chính thức đến Chủ đầu tư - đây gọi là Request for Clarification.

**Tại sao quan trọng:**

**1. Câu trả lời có giá trị pháp lý**
Chủ đầu tư phải trả lời bằng văn bản và gửi đến tất cả nhà thầu dưới dạng Addendum hoặc Clarification Notice. Nội dung này trở thành một phần của HSMT, có hiệu lực ràng buộc.

**2. Mọi nhà thầu đều nhận được**
Chủ đầu tư không được trả lời riêng cho một nhà thầu - tất cả câu trả lời phải được phát hành công khai cho tất cả. Điều này có nghĩa: nếu bạn không hỏi, bạn vẫn nhận được câu trả lời của người khác hỏi.

**3. Bảo vệ bạn khỏi diễn giải sai**
Nếu bạn tự diễn giải một yêu cầu mơ hồ và làm hồ sơ theo đó, rủi ro là hồ sơ không đáp ứng đúng ý Chủ đầu tư → bị trừ điểm hoặc bị loại.

---

## Khi nào nên hỏi?

### Nên hỏi khi:

- HSMT có điều khoản mâu thuẫn (ví dụ: Section 2 ghi một đằng, BDS ghi một nẻo)
- Yêu cầu không rõ ràng (ví dụ: "similar experience" - loại công việc nào được tính?)
- Yêu cầu kỹ thuật có thể có nhiều cách đáp ứng khác nhau
- Không chắc tài liệu cụ thể nào được chấp nhận để chứng minh một yêu cầu
- Thời hạn trong HSMT có vẻ mâu thuẫn nhau

### Không nên hỏi khi:

- Câu hỏi đã có câu trả lời rõ ràng trong HSMT (đọc kỹ hơn trước)
- Câu hỏi sẽ lộ thông tin chiến lược của bạn (ví dụ: hỏi chi tiết về giải pháp kỹ thuật bạn định dùng)
- Câu hỏi có tính thương lượng ("Chúng tôi muốn đề xuất thay thế điều khoản X")
- Câu hỏi vô nghĩa hoặc quá vụn vặt - làm mất uy tín của bạn trong mắt Chủ đầu tư

> **Lưu ý thực tế:** Đừng gửi quá nhiều câu hỏi. 3–5 câu hỏi thực chất tốt hơn 15 câu hỏi vụn vặt. Chủ đầu tư đánh giá năng lực nhà thầu qua cả chất lượng câu hỏi.

---

## Cách viết clarification đúng chuẩn

Một câu hỏi clarification tốt gồm 4 phần:

### Phần 1 - Tiêu đề rõ ràng

Ghi rõ: số gói thầu, tên gói thầu, và đây là Request for Clarification.

Ví dụ:
Subject: Request for Clarification - Tender No. XYZ-2024-001
[Tên gói thầu đầy đủ]

---

### Phần 2 - Trích dẫn điều khoản cụ thể

Luôn ghi rõ bạn đang hỏi về phần nào của HSMT.

Ví dụ:
Reference: Section 4.2 - Qualification Criteria, Paragraph 3

---

### Phần 3 - Câu hỏi rõ ràng, một nghĩa

Câu hỏi phải:
- Cụ thể, không mơ hồ
- Có thể trả lời Yes/No hoặc bằng thông tin cụ thể
- Không dẫn dắt theo hướng bạn muốn nghe

---

### Phần 4 - Không lộ thông tin chiến lược

Tránh hỏi kiểu:
- "Giải pháp X của chúng tôi có được chấp nhận không?" → lộ giải pháp
- "Nếu giá dưới Y triệu thì có ảnh hưởng đến điểm kỹ thuật không?" → lộ chiến lược giá

---

## Template clarification letter mẫu (tiếng Anh)
[Company Letterhead]
[Date]
To: [Name of Contracting Authority / Employer]
[Address]
Subject: Request for Clarification
Tender No.: [Insert Tender Number]
Tender Title: [Insert Tender Title]
Dear Sir/Madam,
We, [Company Name], refer to the Bidding Documents issued
for the above-referenced tender, and would like to request
clarification on the following matter:

Question 1:
Reference: Section 4.2, Paragraph 3 - Similar Experience
The Bidding Documents state: "...contracts of similar nature
in the supply and installation of mechanical systems..."
Could you please clarify whether experience in the supply
and installation of HVAC systems in industrial facilities
would be considered as qualifying similar experience under
this requirement?

[Additional questions if any, numbered sequentially]

We would appreciate your response at your earliest
convenience, and no later than the deadline for
clarification specified in the Bidding Data Sheet.
Yours faithfully,
[Authorized Signatory Name]
[Title]
[Company Name]
[Contact Email]
[Contact Phone]

---

## Xử lý khi Chủ đầu tư trả lời không rõ ràng

Tình huống phổ biến: Bạn hỏi rõ ràng nhưng nhận được câu trả lời chung chung kiểu "Nhà thầu tự tham chiếu HSMT".

Các bước xử lý:

**Bước 1:** Đọc lại câu trả lời kỹ - đôi khi câu trả lời hàm ý rõ ràng hơn bề mặt.

**Bước 2:** Nếu thực sự không rõ, gửi follow-up clarification với câu hỏi Yes/No cụ thể hơn.

**Bước 3:** Nếu vẫn không nhận được câu trả lời rõ ràng, làm hồ sơ theo cách diễn giải an toàn hơn (conservative interpretation) - và ghi chú trong hồ sơ nếu cần thiết.

**Bước 4:** Document lại toàn bộ câu hỏi và câu trả lời để có bằng chứng nếu sau này có tranh chấp.

---

## Warning quan trọng - Câu trả lời được gửi đến tất cả nhà thầu

Đây vừa là lợi thế vừa là rủi ro:

**Lợi thế:** Bạn không cần phải hỏi tất cả - nếu nhà thầu khác hỏi câu bạn cũng đang thắc mắc, bạn sẽ tự động nhận được câu trả lời.

**Rủi ro:** Nếu câu hỏi của bạn vô tình tiết lộ chiến lược (ví dụ: hỏi về giải pháp kỹ thuật đặc biệt bạn định dùng), đối thủ sẽ biết hướng đi của bạn.

**Nguyên tắc:** Hỏi về yêu cầu và tiêu chí, không hỏi về giải pháp của bạn.$content_7$,
  $mistakes_7$[
  {
    "title": "Hỏi quá sát clarification deadline",
    "description": "Nếu gửi câu hỏi 1-2 ngày trước deadline clarification, Chủ đầu tư có thể không kịp trả lời trước khi bạn cần thông tin đó để làm hồ sơ. Gửi sớm để có thời gian xử lý.",
    "severity": "medium"
  },
  {
    "title": "Câu hỏi không trích dẫn điều khoản cụ thể",
    "description": "Hỏi chung chung như 'Yêu cầu kinh nghiệm trong HSMT có thể giải thích như thế nào?' khó nhận được câu trả lời hữu ích. Luôn dẫn chiếu Section/Clause cụ thể.",
    "severity": "medium"
  },
  {
    "title": "Hỏi bằng email không chính thức",
    "description": "Câu hỏi phải được gửi qua kênh chính thức quy định trong HSMT (email chính thức, cổng e-procurement, hoặc văn bản). Email ngoài kênh có thể không được chấp nhận và Chủ đầu tư không có nghĩa vụ trả lời.",
    "severity": "high"
  },
  {
    "title": "Quên theo dõi Addendum được phát hành",
    "description": "Sau khi gửi câu hỏi hoặc trong quá trình chuẩn bị hồ sơ, Chủ đầu tư có thể phát hành Addendum (sửa đổi HSMT). Nếu không theo dõi, bạn có thể làm hồ sơ theo bản HSMT cũ.",
    "severity": "fatal"
  }
]$mistakes_7$::jsonb,
  $fatal_7$[
  {
    "description": "Không cập nhật hồ sơ theo Addendum được phát hành sau khi clarification - làm hồ sơ theo HSMT phiên bản cũ",
    "law_reference": "Addendum là phần không tách rời của HSMT, có giá trị pháp lý ràng buộc"
  }
]$fatal_7$::jsonb,
  ARRAY['cau-truc-hsmt-doc-tu-dau', 'deadline-hieu-luc-ho-so', 'top-loi-bi-loai-chi-tu', 'kinh-nghiem-tuong-tu-yeu-cau-kho-nhat']::text[],
  $quiz_7$[
  {
    "question": "Câu trả lời clarification của Chủ đầu tư được gửi như thế nào?",
    "options": [
      "Chỉ gửi riêng cho nhà thầu đã hỏi",
      "Phát hành cho tất cả nhà thầu dưới dạng Addendum/Clarification Notice",
      "Đăng lên website công khai nhưng không gửi trực tiếp",
      "Chỉ trả lời miệng tại buổi site visit"
    ],
    "correct_answer": "Phát hành cho tất cả nhà thầu dưới dạng Addendum/Clarification Notice",
    "explanation": "Chủ đầu tư phải đảm bảo công bằng: mọi thông tin làm rõ đều được gửi đến tất cả nhà thầu."
  },
  {
    "question": "Thông tin nào KHÔNG nên đưa vào câu hỏi clarification?",
    "options": [
      "Số điều khoản cần làm rõ",
      "Giải pháp kỹ thuật cụ thể bạn đang cân nhắc sử dụng",
      "Yêu cầu về tài liệu chứng minh kinh nghiệm",
      "Mâu thuẫn giữa hai điều khoản trong HSMT"
    ],
    "correct_answer": "Giải pháp kỹ thuật cụ thể bạn đang cân nhắc sử dụng",
    "explanation": "Vì câu trả lời sẽ được gửi đến tất cả nhà thầu, tiết lộ giải pháp kỹ thuật của bạn là trao lợi thế cho đối thủ."
  },
  {
    "question": "Chủ đầu tư phát hành Addendum sau khi bạn đã làm xong 80% hồ sơ. Bạn cần làm gì?",
    "options": [
      "Tiếp tục vì hồ sơ gần xong, Addendum ít khi thay đổi nhiều",
      "Đọc kỹ Addendum và cập nhật hồ sơ theo những gì thay đổi - dù mất thêm thời gian",
      "Gửi email hỏi Chủ đầu tư có cần cập nhật hồ sơ không",
      "Nộp thêm một phụ lục riêng đính kèm Addendum"
    ],
    "correct_answer": "Đọc kỹ Addendum và cập nhật hồ sơ theo những gì thay đổi - dù mất thêm thời gian",
    "explanation": "Addendum là phần không tách rời của HSMT. Hồ sơ không phản ánh nội dung Addendum có thể bị coi là không tuân thủ yêu cầu."
  }
]$quiz_7$::jsonb,
  true,
  false
),
(
  'quick-scan-hsmt-5-phut',
  $title_8$Quick Scan HSMT - 5 phút biết có nên làm không$title_8$,
  $titleen_8$HSMT Quick Scan - GO or NO-GO in 5 Minutes$titleen_8$,
  2,
  'quy-trinh',
  ARRAY['quick scan', 'GO/NO-GO', 'HSMT', 'red flags', 'thực chiến']::text[],
  $objective_8$Sau bài này, bạn có thể:
- Biết cách đọc lướt HSMT đúng cách (không đọc từ đầu đến cuối)
- Áp dụng framework 5 bước Quick Scan để ra quyết định GO / NO-GO
- Điền được template Quick Scan cho bất kỳ gói thầu nào
- Tránh mất thời gian vào những gói thầu mình không có cơ hội$objective_8$,
  $explanation_8$Nhiều người mới làm thầu mắc cùng một lỗi: **đọc HSMT từ trang 1 đến trang cuối**, rồi đến trang 80 mới phát hiện công ty mình không đủ điều kiện tham gia.

Đó là cách đọc sai.

**Quick Scan là gì?**
Là kỹ năng đọc lướt có chủ đích - trong 5–10 phút đầu, bạn chỉ tìm đúng 5 thông tin quyết định. Nếu một trong số đó là fatal → NO-GO ngay, không đọc tiếp.

Tư duy đúng:

> "HSMT dài 200 trang nhưng quyết định GO/NO-GO thường nằm ở 10 trang quan trọng nhất."$explanation_8$,
  $content_8$### Framework Quick Scan - 5 bước (theo thứ tự này)

Luôn check theo đúng thứ tự. Nếu bước nào fail → dừng lại, không cần check tiếp.

---

#### Bước 1: Điều kiện tham gia - "Mình có được phép dự không?"

Tìm ở: Mục "Eligibility", "Điều kiện tham gia", "Tư cách nhà thầu" (thường ở đầu HSMT hoặc Section 2).

Cần check:
- Loại hình công ty được phép dự (nhà thầu độc lập, JV, nước ngoài…)
- Giấy phép đặc thù cần có (ví dụ: giấy phép xây dựng, chứng chỉ ngành)
- Công ty mình có đang bị cấm thầu không
- Có yêu cầu vốn điều lệ tối thiểu không

**Red flag:** Yêu cầu năng lực cụ thể mà mình chắc chắn không có → NO-GO ngay.

---

#### Bước 2: Bảo lãnh dự thầu - "Mình có lo được tiền không?"

Tìm ở: Mục "Bid Security", "Bảo đảm dự thầu".

Cần check:
- Số tiền bảo lãnh là bao nhiêu (thường 1–3% giá trị gói thầu)
- Hình thức chấp nhận: thư bảo lãnh ngân hàng, tiền mặt, hay cả hai
- Ngân hàng phát hành có phải ngân hàng trong danh sách được chấp nhận không
- Thời hạn hiệu lực của bảo lãnh (phải dài hơn bid validity ít nhất 30 ngày)

**Red flag:** Yêu cầu ngân hàng cụ thể mà công ty bạn không có quan hệ → cần confirm trước.

---

#### Bước 3: Kinh nghiệm tương tự - "Mình có đủ hồ sơ chứng minh không?"

Tìm ở: Mục "Experience", "Kinh nghiệm tương tự", "Similar Contracts".

Cần check:
- Số lượng hợp đồng tương tự yêu cầu (vd: ít nhất 3 hợp đồng trong 5 năm)
- Quy mô tối thiểu của mỗi hợp đồng (vd: ít nhất 50% giá trị gói này)
- "Tương tự" được định nghĩa như thế nào (ngành, loại công việc, quy mô)
- Bằng chứng cần có: hợp đồng + biên bản nghiệm thu hay chỉ cần hợp đồng

**Red flag:** Định nghĩa "tương tự" quá hẹp, hoặc yêu cầu nghiệm thu mà mình chưa có đủ → Conditional GO, cần đánh giá kỹ.

---

#### Bước 4: Deadline - "Mình có đủ thời gian làm không?"

Cần check:
- Ngày nộp hồ sơ (deadline)
- Số ngày còn lại tính từ hôm nay
- Khối lượng hồ sơ cần chuẩn bị (ước lượng)
- Có ngày clarification không (nếu có, timeline càng ngắn)

**Rule of thumb:**
- Gói đơn giản: cần ít nhất 7–10 ngày
- Gói trung bình: cần ít nhất 14–21 ngày
- Gói lớn/phức tạp: cần ít nhất 30 ngày

**Red flag:** Còn dưới 7 ngày mà hồ sơ phức tạp → cân nhắc kỹ.

---

#### Bước 5: Red flags & Suspicious Clauses - "Có bẫy không?"

Một số dấu hiệu cần cảnh giác:

| Dấu hiệu | Ý nghĩa |
|---|---|
| Thông số kỹ thuật chỉ khớp đúng 1 thương hiệu | Gói thầu có thể đã "chỉ định" nhà cung cấp |
| Yêu cầu kinh nghiệm rất cụ thể + địa bàn cụ thể | Nhà thầu khác khó đáp ứng |
| Thời gian nộp hồ sơ quá ngắn | Có thể có nhà thầu được ưu tiên |
| Bảo lãnh thực hiện bất thường cao (>10%) | Risk tài chính lớn |
| Liquidated Damages quá cao, không có cap | Risk pháp lý |
| HSMT mơ hồ, nhiều điều khoản mâu thuẫn | Cần clarification hoặc cân nhắc bỏ qua |

---

### Template Quick Scan

```
QUICK SCAN - [Tên gói thầu]
Ngày check: ___________
Người check: ___________

BỘ CHECK 5 BƯỚC:

1. ĐIỀU KIỆN THAM GIA
   [ ] Loại hình công ty: __________ → Đạt / Không đạt
   [ ] Giấy phép đặc thù: __________ → Có / Không
   [ ] Vốn điều lệ tối thiểu: __________ → Đạt / Không đạt
   → KẾT LUẬN BƯỚC 1: PASS / FAIL

2. BẢO LÃNH DỰ THẦU
   [ ] Số tiền: __________ → Lo được / Không lo được
   [ ] Ngân hàng yêu cầu: __________ → Có quan hệ / Cần xử lý
   [ ] Hiệu lực: __________ ngày
   → KẾT LUẬN BƯỚC 2: PASS / FAIL

3. KINH NGHIỆM TƯƠNG TỰ
   [ ] Yêu cầu: __ hợp đồng, tối thiểu __ tỷ, trong __ năm
   [ ] Mình có: __ hợp đồng đủ tiêu chí
   [ ] Bằng chứng cần: Hợp đồng + Nghiệm thu / Chỉ hợp đồng
   → KẾT LUẬN BƯỚC 3: PASS / CONDITIONAL / FAIL

4. DEADLINE
   [ ] Ngày nộp: __________
   [ ] Số ngày còn lại: __ ngày
   [ ] Ước tính khối lượng: Đơn giản / Trung bình / Phức tạp
   → KẾT LUẬN BƯỚC 4: PASS / TIGHT / FAIL

5. RED FLAGS
   [ ] Thông số kỹ thuật: Bình thường / Đáng ngờ
   [ ] Điều khoản tài chính: Bình thường / Bất thường
   [ ] HSMT: Rõ ràng / Mơ hồ
   → KẾT LUẬN BƯỚC 5: CLEAN / CÓ VẤN ĐỀ

─────────────────────────
KẾT LUẬN TỔNG: GO / NO-GO / CONDITIONAL GO
Lý do: ___________
Action tiếp theo: ___________
```

---

### Decision Tree: GO / NO-GO / Conditional GO

**NO-GO ngay nếu:**
- Không đủ tư cách tham gia (eligibility fail)
- Không có bảo lãnh dự thầu trong thời hạn yêu cầu
- Thiếu kinh nghiệm tương tự quá xa so với yêu cầu (vd: yêu cầu 5 hợp đồng, mình có 1)
- Deadline còn dưới 5 ngày mà hồ sơ phức tạp

**Conditional GO nếu:**
- Thiếu 1–2 hợp đồng kinh nghiệm nhưng có thể xử lý qua JV hoặc subcontract
- Ngân hàng bảo lãnh cần xử lý nhưng còn đủ thời gian
- Có một số điểm mơ hồ cần gửi clarification

**GO khi:**
- Pass cả 5 bước
- Risk nhận diện được và có kế hoạch xử lý

---

## 4. Ví dụ thực tế

**Gói thầu:** Cung cấp & lắp đặt hệ thống điện năng lượng mặt trời cho tòa nhà văn phòng

**Quick Scan thực tế:**

| Bước | Yêu cầu | Tình trạng | Kết luận |
|---|---|---|---|
| Điều kiện | Có giấy phép điện, nhà thầu VN | Có đủ | PASS |
| Bảo lãnh | 500 triệu, BL ngân hàng | Cần gọi ngân hàng confirm | PASS (cần xác nhận) |
| Kinh nghiệm | 3 hợp đồng solar ≥ 500kWp trong 5 năm | Có 2 hợp đồng đủ tiêu chí | CONDITIONAL |
| Deadline | Còn 18 ngày | Đủ thời gian | PASS |
| Red flags | Thông số chỉ nhắc đến "panel nhập khẩu EU" | Cần đọc kỹ hơn | CÓ VẤN ĐỀ NHỎ |

→ **Kết luận: Conditional GO**
→ **Action:** Xem xét thêm 1 hợp đồng solar có thể claim được, gửi clarification về "panel EU"

---$content_8$,
  $mistakes_8$[
  {
    "title": "Đọc HSMT từ đầu đến cuối",
    "description": "Mất 3-4 tiếng mới biết mình fail ở điều kiện tham gia.",
    "severity": "medium"
  },
  {
    "title": "Bỏ qua bước check deadline",
    "description": "Nhận ra còn 3 ngày khi hồ sơ cần 2 tuần để chuẩn bị.",
    "severity": "medium"
  },
  {
    "title": "Tự an ủi về kinh nghiệm tương tự",
    "description": "\"Hợp đồng này gần giống lắm\" nhưng thực tế không đủ tiêu chí → bị loại ở vòng kỹ thuật.",
    "severity": "medium"
  },
  {
    "title": "Bỏ qua red flags",
    "description": "Đổ 3 tuần làm hồ sơ cho một gói đã \"đặt sẵn\" cho nhà thầu khác.",
    "severity": "medium"
  },
  {
    "title": "Không điền template, chỉ check trong đầu",
    "description": "Dễ bỏ sót, dễ quên khi review lại sau.",
    "severity": "medium"
  }
]$mistakes_8$::jsonb,
  $fatal_8$[]$fatal_8$::jsonb,
  ARRAY['cau-truc-hsmt-doc-tu-dau', 'bao-lanh-du-thau-khong-duoc-sai', 'kinh-nghiem-tuong-tu-yeu-cau-kho-nhat', 'gap-analysis-nang-luc', 'checklist-truoc-khi-nop']::text[],
  $quiz_8$[
  {
    "question": "Theo framework Quick Scan, bước nào nên check TRƯỚC - kinh nghiệm tương tự hay điều kiện tham gia?",
    "options": [
      "Kinh nghiệm tương tự, vì đây là yêu cầu khó nhất",
      "Điều kiện tham gia (nếu không đủ tư cách, check gì cũng vô nghĩa)",
      "Giá dự thầu, vì giá quyết định thắng thầu",
      "Mẫu hồ sơ, vì dễ chỉnh sửa nhất"
    ],
    "correct_answer": "Điều kiện tham gia (nếu không đủ tư cách, check gì cũng vô nghĩa)",
    "explanation": "Quick Scan phải bắt đầu từ điều kiện tham gia vì đây là điểm có thể loại ngay. Nếu không đủ tư cách, các bước sau không còn ý nghĩa."
  },
  {
    "question": "Bạn còn 4 ngày, gói thầu yêu cầu hồ sơ kỹ thuật phức tạp. Quyết định của bạn?",
    "options": [
      "Vẫn GO vì có thể làm nhanh nếu tăng nhân sự",
      "NO-GO (trừ khi đã chuẩn bị sẵn từ trước)",
      "Chỉ nộp phần tài chính trước, phần kỹ thuật bổ sung sau",
      "Đợi đến ngày cuối rồi quyết định"
    ],
    "correct_answer": "NO-GO (trừ khi đã chuẩn bị sẵn từ trước)",
    "explanation": "Deadline quá ngắn với hồ sơ kỹ thuật phức tạp tạo risk rất cao. Nếu chưa chuẩn bị sẵn từ trước, đây thường là quyết định NO-GO."
  },
  {
    "question": "HSMT yêu cầu thông số kỹ thuật rất cụ thể, chỉ khớp đúng 1 thương hiệu. Đây là dấu hiệu gì?",
    "options": [
      "Yêu cầu bình thường, không cần kiểm tra thêm",
      "Red flag - gói thầu có thể đã được \"thiết kế\" cho nhà thầu/nhà cung cấp cụ thể",
      "Dấu hiệu hồ sơ đơn giản, dễ nộp",
      "Chỉ là vấn đề format, không ảnh hưởng quyết định GO/NO-GO"
    ],
    "correct_answer": "Red flag - gói thầu có thể đã được \"thiết kế\" cho nhà thầu/nhà cung cấp cụ thể",
    "explanation": "Thông số quá cụ thể, chỉ khớp một thương hiệu là red flag. Cần đọc kỹ hơn, cân nhắc clarification hoặc NO-GO nếu risk quá cao."
  }
]$quiz_8$::jsonb,
  true,
  true
),
(
  'gap-analysis-nang-luc',
  $title_9$GAP Analysis - Đối chiếu năng lực vs yêu cầu HSMT$title_9$,
  $titleen_9$Capability GAP Analysis$titleen_9$,
  2,
  'quy-trinh',
  ARRAY['GAP analysis', 'năng lực', 'HSMT', 'JV', 'thực chiến']::text[],
  $objective_9$Sau bài này, bạn có thể:
- Hiểu GAP analysis là gì và tại sao quan trọng trong đấu thầu
- Đối chiếu năng lực công ty với yêu cầu HSMT theo 4 nhóm
- Điền được template GAP analysis cho một gói thầu cụ thể
- Biết cách xử lý từng loại GAP: tự xử lý, tìm đối tác, JV, hay NO-GO$objective_9$,
  $explanation_9$Quick Scan giúp bạn biết "có nên tham gia không" trong 5 phút.

GAP Analysis là bước tiếp theo: **đào sâu hơn** để biết chính xác mình đang thiếu gì, thiếu bao nhiêu, và có thể bù đắp bằng cách nào.

Tư duy đúng:

> "Không ai hoàn hảo 100%. Câu hỏi không phải 'mình có thiếu không' mà là 'mình thiếu gì và xử lý được không'."

GAP analysis giúp bạn:
- Ra quyết định dựa trên dữ liệu, không phải cảm tính
- Chuẩn bị hồ sơ đúng trọng tâm
- Biết đúng lúc cần tìm đối tác JV hay subcontractor$explanation_9$,
  $content_9$### 4 nhóm năng lực cần đối chiếu

---

#### Nhóm 1: Tài chính

Các yêu cầu thường gặp:
- Doanh thu tối thiểu (vd: ≥ 2 lần giá trị gói thầu trong 3 năm gần nhất)
- Vốn chủ sở hữu tối thiểu
- Báo cáo tài chính đã kiểm toán (thường 3 năm gần nhất)
- Hạn mức tín dụng ngân hàng

Cần chuẩn bị:
- Số liệu BCTC 3 năm gần nhất
- Xác nhận hạn mức từ ngân hàng (nếu cần)

**Cảnh báo:** Nhiều HSMT yêu cầu BCTC "đã được kiểm toán độc lập". Nếu BCTC công ty bạn chưa kiểm toán → đây là GAP nghiêm trọng, không thể xử lý trong vài ngày.

---

#### Nhóm 2: Kỹ thuật

Các yêu cầu thường gặp:
- Kinh nghiệm tương tự (số hợp đồng, quy mô, loại hình)
- Thiết bị, máy móc sở hữu hoặc thuê dài hạn
- Chứng chỉ kỹ thuật của công ty (ISO, chứng chỉ ngành)
- Năng lực sản xuất/thi công

Cần chuẩn bị:
- Danh mục hợp đồng đã thực hiện (kèm biên bản nghiệm thu)
- Danh sách thiết bị kèm giấy tờ sở hữu/thuê

---

#### Nhóm 3: Nhân sự

Các yêu cầu thường gặp:
- Key personnel (Project Manager, Technical Lead…) với yêu cầu cụ thể về kinh nghiệm và chứng chỉ
- Số lượng nhân sự kỹ thuật tối thiểu
- Chứng chỉ hành nghề cá nhân

Cần chuẩn bị:
- CV chuẩn format HSMT yêu cầu
- Bản sao chứng chỉ hành nghề
- Xác nhận cam kết tham gia dự án

**Cảnh báo:** Key personnel phải "cam kết tham gia" - nếu họ đang trong hợp đồng khác, đây là GAP cần xử lý.

---

#### Nhóm 4: Pháp lý

Các yêu cầu thường gặp:
- Giấy phép kinh doanh đúng ngành nghề
- Giấy phép đặc thù (xây dựng, điện, y tế…)
- Tư cách hợp lệ (không bị cấm thầu, không đang kiện tụng)
- Các chứng nhận: ISO, HACCP, CE…

---

### Template GAP Analysis

```
GAP ANALYSIS - [Tên gói thầu]
Ngày: ___________

| Nhóm | Yêu cầu HSMT | Tình trạng công ty | GAP | Mức độ | Hướng xử lý |
|------|-------------|-------------------|-----|--------|-------------|
| Tài chính | Doanh thu ≥ 50 tỷ/năm × 3 năm | 35 tỷ/năm | -15 tỷ | CAO | JV với đối tác lớn hơn |
| Tài chính | BCTC kiểm toán | Chưa kiểm toán | Thiếu | FATAL | NO-GO hoặc xử lý ngay |
| Kỹ thuật | 3 hợp đồng solar ≥ 500kWp | 2 hợp đồng | Thiếu 1 | TRUNG BÌNH | Tìm subcontractor có kinh nghiệm |
| Nhân sự | PM ≥ 10 năm kinh nghiệm | PM hiện tại: 7 năm | -3 năm | CAO | Tìm PM bên ngoài |
| Pháp lý | Chứng chỉ ISO 9001 | Đã có | Không có GAP | - | - |
```

**Cột Mức độ:**
- **FATAL**: Không thể xử lý → NO-GO
- **CAO**: Khó xử lý, cần đối tác/JV
- **TRUNG BÌNH**: Có thể xử lý nhưng cần thời gian/nguồn lực
- **THẤP**: Xử lý được dễ dàng

---

### Cách xử lý từng loại GAP

#### GAP THẤP - Tự xử lý
Ví dụ: thiếu một số tài liệu, format CV chưa chuẩn
→ Xử lý trong nội bộ, không cần đối tác

#### GAP TRUNG BÌNH - Cần subcontractor
Ví dụ: thiếu 1 hợp đồng kinh nghiệm hoặc thiếu một loại thiết bị
→ Ký hợp đồng subcontract với đơn vị có kinh nghiệm
→ Lưu ý: không phải HSMT nào cũng chấp nhận subcontract cho phần core

#### GAP CAO - Cân nhắc JV
Ví dụ: thiếu doanh thu, thiếu nhiều hợp đồng tương tự
→ Liên danh với đối tác bổ sung năng lực
→ Cần thỏa thuận JV rõ ràng trước khi nộp hồ sơ

#### GAP FATAL - NO-GO
Ví dụ: không có giấy phép hành nghề, BCTC chưa kiểm toán, thiếu tư cách pháp lý
→ Không thể xử lý trong thời gian còn lại
→ Quyết định NO-GO, chuyển nguồn lực sang gói khác

---

## 4. Ví dụ thực tế

**Tình huống:** Gói thầu tư vấn thiết kế hệ thống PCCC cho tòa nhà 20 tầng. Giá trị: 8 tỷ VND.

**GAP Analysis:**

| Yêu cầu | Tình trạng | GAP | Mức độ | Xử lý |
|---|---|---|---|---|
| Doanh thu ≥ 16 tỷ/năm × 3 năm | 20 tỷ/năm | Không có GAP | - | OK |
| 2 hợp đồng PCCC tòa nhà >15 tầng | 1 hợp đồng đủ tiêu chí | Thiếu 1 | TRUNG BÌNH | Xem xét JV hoặc subcontract |
| Chứng chỉ tư vấn PCCC cấp tỉnh | Có | Không có GAP | - | OK |
| PM: ≥ 8 năm kinh nghiệm PCCC | PM: 5 năm | -3 năm | CAO | Tìm PM bên ngoài hoặc JV |

→ **Kết luận:** Conditional GO - cần xử lý 2 GAP trước khi quyết định nộp.

---$content_9$,
  $mistakes_9$[
  {
    "title": "Tự đánh lừa bản thân về năng lực",
    "description": "\"Hợp đồng này chắc tính được\" - nhưng thực ra không đúng định nghĩa \"tương tự\" của HSMT.",
    "severity": "medium"
  },
  {
    "title": "Không check kỹ định nghĩa \"tương tự\"",
    "description": "HSMT nói \"kinh nghiệm hệ thống điện\" nhưng ý họ là \"hệ thống điện công nghiệp\", không phải \"điện dân dụng\".",
    "severity": "medium"
  },
  {
    "title": "Bỏ qua GAP nhân sự đến phút chót",
    "description": "Tìm PM đúng yêu cầu rất khó, cần thời gian dài hơn tưởng.",
    "severity": "medium"
  },
  {
    "title": "Không document GAP analysis",
    "description": "Mỗi người trong team hiểu khác nhau về \"mình có đủ năng lực không\".",
    "severity": "medium"
  }
]$mistakes_9$::jsonb,
  $fatal_9$[]$fatal_9$::jsonb,
  ARRAY['quick-scan-hsmt-5-phut', 'kinh-nghiem-tuong-tu-yeu-cau-kho-nhat']::text[],
  $quiz_9$[
  {
    "question": "GAP \"BCTC chưa được kiểm toán\" thuộc mức độ nào?",
    "options": [
      "Thấp - có thể bổ sung sau khi nộp",
      "Trung bình - chỉ cần giải trình",
      "Cao - có thể xử lý bằng nhân sự nội bộ",
      "FATAL - không thể xử lý trong thời gian ngắn"
    ],
    "correct_answer": "FATAL - không thể xử lý trong thời gian ngắn",
    "explanation": "Nếu HSMT yêu cầu báo cáo tài chính đã kiểm toán mà công ty chưa có, đây thường là GAP nghiêm trọng và không xử lý được trong vài ngày."
  },
  {
    "question": "Công ty thiếu 1 hợp đồng kinh nghiệm tương tự. Nên xử lý bằng cách nào?",
    "options": [
      "Bỏ qua vì thiếu 1 hợp đồng thường không quan trọng",
      "Tự mô tả hợp đồng gần giống để thay thế",
      "Cân nhắc subcontract hoặc JV với đơn vị có hợp đồng đó",
      "Chờ Ban mời thầu tự linh hoạt khi đánh giá"
    ],
    "correct_answer": "Cân nhắc subcontract hoặc JV với đơn vị có hợp đồng đó",
    "explanation": "Thiếu kinh nghiệm tương tự là GAP năng lực. Nếu HSMT cho phép, subcontract hoặc liên danh có thể là hướng xử lý thực tế."
  },
  {
    "question": "Tại sao phải document GAP analysis thay vì chỉ nhớ trong đầu?",
    "options": [
      "Để team cùng nhìn thấy, để ra quyết định có căn cứ, và để review lại sau",
      "Để hồ sơ nhìn dài hơn",
      "Để thay thế cho phần compliance matrix",
      "Vì mọi GAP đều có thể xử lý bằng checklist"
    ],
    "correct_answer": "Để team cùng nhìn thấy, để ra quyết định có căn cứ, và để review lại sau",
    "explanation": "GAP analysis cần được ghi lại để cả team thống nhất mức độ rủi ro, hướng xử lý và quyết định GO/NO-GO."
  }
]$quiz_9$::jsonb,
  true,
  false
),
(
  'checklist-truoc-khi-nop',
  $title_10$Checklist Trước Khi Nộp Hồ Sơ$title_10$,
  $titleen_10$Pre-Submission Checklist$titleen_10$,
  2,
  'quy-trinh',
  ARRAY['checklist', 'nộp thầu', 'compliance', 'e-procurement', 'fatal errors']::text[],
  $objective_10$Sau bài này, bạn có thể:
- Hiểu tại sao checklist trước khi nộp là bước không thể bỏ qua
- Áp dụng checklist 5 nhóm cho bất kỳ gói thầu nào
- Biết 5 thứ cần double-check trong 30 phút cuối trước khi đóng gói
- Có checklist riêng cho đấu thầu online (e-procurement)$objective_10$,
  $explanation_10$Một công ty từng bị loại khỏi gói thầu 20 tỷ đồng - không phải vì thiếu năng lực, không phải vì giá cao, mà vì **quên đóng dấu trang cuối của hồ sơ pháp lý**.

Hồ sơ dự thầu không phải thi kiến thức. Đây là bài thi về **sự cẩn thận và quy trình**.

> "Một lỗi nhỏ trong hồ sơ có thể triệt tiêu 3 tuần làm việc."

Checklist không phải để check những thứ phức tạp. Checklist để đảm bảo bạn không bỏ sót những thứ **đơn giản nhưng chí tử**.$explanation_10$,
  $content_10$### Checklist đầy đủ - 5 nhóm

---

#### NHÓM 1: Hồ sơ pháp lý

- [ ] Giấy phép kinh doanh - bản sao công chứng còn hiệu lực
- [ ] Giấy phép hành nghề / chứng chỉ đặc thù (nếu yêu cầu)
- [ ] Điều lệ công ty (nếu yêu cầu)
- [ ] Quyết định bổ nhiệm người đại diện pháp luật
- [ ] Giấy ủy quyền ký (nếu người ký không phải người đại diện pháp luật) - công chứng
- [ ] Tất cả trang có chữ ký: đúng người, đúng chức danh
- [ ] Tất cả trang có con dấu: đúng vị trí, dấu rõ ràng, không bị lệch
- [ ] Số bộ hồ sơ: đúng số lượng HSMT yêu cầu (vd: 1 gốc + 2 bản sao)

**Note:** Một số HSMT yêu cầu công chứng toàn bộ bộ pháp lý - đọc kỹ và không tự suy diễn.

---

#### NHÓM 2: Bảo lãnh dự thầu

- [ ] Số tiền bảo lãnh: đúng số, đúng đơn vị tiền tệ (VND hay USD?)
- [ ] Hình thức bảo lãnh: đúng theo yêu cầu HSMT (BL ngân hàng / tiền mặt)
- [ ] Ngân hàng phát hành: thuộc danh sách chấp nhận (nếu HSMT quy định)
- [ ] Thời hạn hiệu lực: phải đủ dài (≥ bid validity + buffer)
- [ ] Mẫu thư bảo lãnh: đúng theo mẫu HSMT (nếu HSMT có mẫu chuẩn)
- [ ] Người thụ hưởng: đúng tên, đúng địa chỉ Bên mời thầu
- [ ] Ngày phát hành: không được sau ngày nộp hồ sơ

**Warning:** Sai số tiền bảo lãnh dù chỉ 1 đồng → có thể bị loại trực tiếp.

---

#### NHÓM 3: Hồ sơ kỹ thuật

- [ ] Compliance Matrix: đầy đủ, có đánh dấu Comply / Deviate / Not Applicable
- [ ] Tất cả thông số kỹ thuật: đáp ứng hoặc vượt yêu cầu
- [ ] Deviation list: liệt kê rõ các điểm không comply (nếu có)
- [ ] Tài liệu catalog / datasheet: đúng model, đúng thông số
- [ ] Phương án kỹ thuật / methodology: đủ chi tiết theo yêu cầu
- [ ] Hợp đồng kinh nghiệm tương tự: đủ số lượng, kèm nghiệm thu (nếu yêu cầu)
- [ ] CV key personnel: đúng format, đủ thông tin, có chữ ký cam kết
- [ ] Chứng chỉ cá nhân (key personnel): bản sao rõ ràng

---

#### NHÓM 4: Hồ sơ tài chính

- [ ] Đơn giá dự thầu: điền đầy đủ, không bỏ trống dòng nào
- [ ] Tổng giá: đúng (cộng lại thủ công để kiểm tra)
- [ ] Đơn vị tiền tệ: đúng và nhất quán trong toàn bộ bảng giá
- [ ] Chữ ký và đóng dấu trên bảng giá
- [ ] Phụ lục giá (nếu có): đầy đủ, nhất quán với bảng giá chính
- [ ] Thuế: đã bao gồm hay chưa - phải khớp với yêu cầu HSMT
- [ ] Giá có điền bằng chữ (nếu yêu cầu): khớp với số

**Warning:** Sai số học trong bảng giá (vd: cộng sai) có thể bị coi là lỗi kỹ thuật. Luôn cộng lại bằng tay hoặc excel riêng trước khi nộp.

---

#### NHÓM 5: Nộp hồ sơ

- [ ] Địa điểm nộp: đúng theo HSMT (tên đơn vị, địa chỉ, tầng/phòng)
- [ ] Số bộ hồ sơ: đủ theo yêu cầu
- [ ] Cách đóng gói: đúng theo yêu cầu (niêm phong, dán nhãn)
- [ ] Nhãn bên ngoài: đúng tên gói thầu, đúng tên nhà thầu, đúng địa chỉ nhận
- [ ] Thời hạn nộp: biết rõ giờ chốt, không phải ngày chốt
- [ ] Biên nhận nộp hồ sơ: yêu cầu và giữ lại

**Note:** Nộp trễ 1 phút = bị loại. Không có ngoại lệ.

---

### 5 thứ double-check trong 30 phút cuối

Trước khi đóng gói lần cuối, dừng lại 30 phút và check 5 điểm này:

1. **Chữ ký & con dấu** - Lướt qua từng trang, kiểm tra chỗ cần ký đã ký chưa
2. **Số tiền bảo lãnh** - Đọc lại thư bảo lãnh, đối chiếu với HSMT
3. **Tổng giá trong đơn dự thầu** - Cộng lại một lần nữa
4. **Số bộ hồ sơ** - Đếm lại đủ số bộ gốc + sao
5. **Giờ nộp & địa điểm** - Xác nhận lần cuối không có thay đổi trong Addendum

---

### Checklist riêng cho đấu thầu online (E-Procurement)

- [ ] Đăng nhập tài khoản trước deadline ít nhất 2–3 tiếng
- [ ] Upload từng file: kiểm tra đúng tên file, đúng mục
- [ ] Kích thước file: đúng giới hạn hệ thống (thường <10MB/file)
- [ ] Tên file: không có ký tự đặc biệt (dấu tiếng Việt, /, \, *, ?)
- [ ] Xem lại file đã upload: download lại để confirm mở được
- [ ] Hoàn thành nộp (submit): đừng chỉ upload mà quên bấm "Nộp hồ sơ"
- [ ] Lưu screenshot xác nhận nộp thành công
- [ ] In/lưu biên nhận điện tử (nếu hệ thống cấp)

---

## 4. Ví dụ thực tế

**Câu chuyện thật (ẩn danh):**

Một nhà thầu chuẩn bị hồ sơ 3 tuần cho gói thầu 15 tỷ. Hồ sơ kỹ thuật xuất sắc, giá cạnh tranh. Nhưng đến phần đánh giá sơ bộ, Ban mời thầu phát hiện:

- Giấy ủy quyền ký hồ sơ **không được công chứng**
- Thư bảo lãnh ghi sai **tên gói thầu**

Kết quả: loại ở vòng đầu tiên.

**Bài học:** 3 tuần làm việc, bị loại vì 2 lỗi có thể kiểm tra trong 10 phút.

---$content_10$,
  $mistakes_10$[
  {
    "title": "Nộp đúng giờ nhưng sai địa điểm",
    "description": "Phòng ban trong cùng tòa nhà nhưng khác tầng → bị từ chối nhận.",
    "severity": "medium"
  },
  {
    "title": "Bảo lãnh đúng số tiền nhưng sai tên gói thầu",
    "description": "Hầu hết HSMT coi đây là fatal error.",
    "severity": "medium"
  },
  {
    "title": "Upload đủ file nhưng quên bấm Submit",
    "description": "Hệ thống e-procurement không nhận hồ sơ dù file đã lên server.",
    "severity": "medium"
  },
  {
    "title": "Tổng giá trong đơn dự thầu sai so với phụ lục",
    "description": "Ban mời thầu sẽ dùng số nào? Mỗi HSMT có quy định khác nhau - và đây thường là điểm tranh cãi không hay.",
    "severity": "medium"
  },
  {
    "title": "Không đọc Addendum",
    "description": "HSMT có thể được sửa đổi sau khi phát hành. Không check Addendum = có thể nộp hồ sơ sai yêu cầu mới nhất.",
    "severity": "medium"
  }
]$mistakes_10$::jsonb,
  $fatal_10$[]$fatal_10$::jsonb,
  ARRAY['quick-scan-hsmt-5-phut', 'xu-ly-upload-loi-e-procurement', 'bao-lanh-du-thau-khong-duoc-sai']::text[],
  $quiz_10$[
  {
    "question": "Bạn upload xong toàn bộ file lên hệ thống e-procurement. Bước tiếp theo cần làm gì?",
    "options": [
      "Đóng trình duyệt vì upload xong là đã nộp",
      "Bấm \"Nộp hồ sơ\" / Submit - upload chưa phải là nộp",
      "Chỉ gửi email báo đã upload",
      "Đợi hệ thống tự submit sau deadline"
    ],
    "correct_answer": "Bấm \"Nộp hồ sơ\" / Submit - upload chưa phải là nộp",
    "explanation": "Nhiều hệ thống tách upload file và submit hồ sơ thành 2 bước. Upload xong nhưng chưa bấm Submit thì hồ sơ có thể chưa được nộp."
  },
  {
    "question": "Tổng giá trong đơn dự thầu khác với tổng giá trong phụ lục giá. Điều này có vấn đề gì?",
    "options": [
      "Không vấn đề gì, bên mời thầu sẽ tự chọn số thấp hơn",
      "Mâu thuẫn số liệu - tùy HSMT sẽ xử lý khác nhau, nhưng đây là lỗi nghiêm trọng cần tránh",
      "Chỉ cần sửa sau khi trúng thầu",
      "Đây là lỗi format, không ảnh hưởng đánh giá"
    ],
    "correct_answer": "Mâu thuẫn số liệu - tùy HSMT sẽ xử lý khác nhau, nhưng đây là lỗi nghiêm trọng cần tránh",
    "explanation": "Mâu thuẫn giá là rủi ro lớn vì ảnh hưởng trực tiếp đến đánh giá hồ sơ. Phải kiểm tra trước khi nộp."
  },
  {
    "question": "Bạn nên nộp hồ sơ lúc mấy giờ nếu deadline là 9:00 sáng?",
    "options": [
      "8:59 vì miễn đúng trước deadline là được",
      "Sau 9:00 nếu đã upload file trước đó",
      "Nộp trước 8:00, hoặc với e-procurement: upload xong trước 7:00–8:00",
      "Đúng 9:00 để tận dụng tối đa thời gian chuẩn bị"
    ],
    "correct_answer": "Nộp trước 8:00, hoặc với e-procurement: upload xong trước 7:00–8:00",
    "explanation": "Cần buffer đủ lớn để xử lý lỗi upload, session, mạng hoặc file. Không nên nộp sát deadline."
  }
]$quiz_10$::jsonb,
  true,
  true
),
(
  'xu-ly-upload-loi-e-procurement',
  $title_11$Nộp Thầu Online - Xử Lý Lỗi Upload và Sự Cố Kỹ Thuật$title_11$,
  $titleen_11$E-Procurement Submission - Troubleshooting$titleen_11$,
  2,
  'quy-trinh',
  ARRAY['e-procurement', 'upload', 'submission deadline', 'sự cố kỹ thuật', 'nộp thầu online']::text[],
  $objective_11$Sau bài này, bạn có thể:
- Biết các hệ thống e-procurement phổ biến ở Việt Nam và đặc điểm của mỗi hệ thống
- Xử lý được 5 lỗi upload phổ biến nhất
- Áp dụng nguyên tắc vàng để tránh sự cố vào phút chót
- Biết cần làm gì nếu hệ thống gặp sự cố gần deadline$objective_11$,
  $explanation_11$E-procurement ra đời để làm đấu thầu minh bạch hơn. Nhưng thực tế: hệ thống online thêm một lớp rủi ro mới - rủi ro kỹ thuật.

Hồ sơ hoàn hảo, nhưng upload lỗi vào đúng ngày deadline = kết quả giống hệt nộp trễ = bị loại.

Không giống nộp hồ sơ giấy, bạn không thể "cầm tay chạy nộp" nếu hệ thống gặp vấn đề lúc 8:55 sáng.

> "Chuẩn bị cho rủi ro kỹ thuật không phải lo xa - đó là bắt buộc."$explanation_11$,
  $content_11$### Các hệ thống e-procurement phổ biến tại Việt Nam

| Hệ thống | Đơn vị vận hành | Thường dùng cho |
|---|---|---|
| Hệ thống mạng đấu thầu quốc gia (muasamcong.mpi.gov.vn) | Bộ Kế hoạch & Đầu tư | Mua sắm công, gói thầu vốn nhà nước |
| Hệ thống VNPT e-Procurement | VNPT | Gói thầu nội bộ VNPT và một số tổ chức |
| Hệ thống Viettel Procurement | Viettel | Gói thầu nội bộ Viettel |
| Hệ thống của EVN | EVN | Gói thầu ngành điện |
| Hệ thống của các tập đoàn lớn | Tự phát triển | Gói thầu nội bộ doanh nghiệp |

**Quan trọng nhất:** Hệ thống mạng đấu thầu quốc gia (muasamcong.mpi.gov.vn) - dùng cho hầu hết các gói thầu vốn nhà nước, ODA.

Trước mỗi gói thầu, xác nhận:
- Hệ thống nào đang dùng
- Đã có tài khoản chưa
- Tài khoản còn hiệu lực không

---

### 5 lỗi upload phổ biến nhất & cách xử lý

---

#### Lỗi 1: File quá nặng

**Triệu chứng:** Hệ thống báo lỗi khi upload, hoặc upload mãi không xong.

**Giới hạn thường gặp:** 10MB, 20MB, hoặc 50MB tùy hệ thống.

**Cách xử lý:**
- Compress PDF: dùng Adobe Acrobat (Save as Optimized PDF) hoặc tool online như smallpdf.com
- Scan với DPI thấp hơn: 150 DPI thay vì 300 DPI nếu không cần in lại
- Tách file lớn thành nhiều file nhỏ (nếu hệ thống cho phép)
- Xóa metadata thừa trong file Word/Excel trước khi convert sang PDF

**Phòng ngừa:** Sau khi scan/tạo toàn bộ file, kiểm tra dung lượng trước - đừng để phát hiện khi đang upload.

---

#### Lỗi 2: Tên file có ký tự đặc biệt

**Triệu chứng:** Hệ thống báo lỗi "invalid filename", file không hiển thị sau khi upload.

**Ký tự gây lỗi phổ biến:** Dấu tiếng Việt (ă, ơ, ệ…), dấu ngoặc (), /, \, *, ?, &, #, %

**Cách xử lý:**
- Đổi tên file sang tiếng Anh hoặc không dấu
- Dùng dấu gạch dưới (_) hoặc gạch ngang (-) thay cho khoảng trắng

**Ví dụ:**
- Sai: `Hồ sơ pháp lý (bản gốc).pdf`
- Đúng: `Ho-so-phap-ly-ban-goc.pdf`

**Phòng ngừa:** Đặt tên file chuẩn ngay từ đầu khi tạo, không chỉnh sửa lúc upload.

---

#### Lỗi 3: Hệ thống chậm gần deadline

**Triệu chứng:** Tốc độ upload giảm mạnh, trang web không phản hồi, đợi lâu không thấy progress.

**Nguyên nhân:** Nhiều nhà thầu upload cùng lúc vào giờ chót - server quá tải. Đây là tình huống xảy ra **thường xuyên**.

**Cách xử lý khi đang gặp:**
- Không refresh trang nếu đang upload (sẽ mất progress)
- Đợi kiên nhẫn, không đóng tab
- Nếu hệ thống treo hoàn toàn: thử trình duyệt khác (Chrome → Firefox)
- Xóa cache trình duyệt, thử lại
- Dùng đường kết nối internet khác (đổi sang 4G nếu wifi không ổn định)

**Phòng ngừa (quan trọng nhất):** Upload trước deadline **ít nhất 2–3 tiếng**. Không có lý do gì để upload vào giờ chót.

---

#### Lỗi 4: Phiên đăng nhập hết hạn (Session Timeout)

**Triệu chứng:** Đang upload thì hệ thống tự đăng xuất, file upload mất, phải đăng nhập lại từ đầu.

**Nguyên nhân:** Hầu hết hệ thống có timeout sau 15–30 phút không có hoạt động. Nếu file upload lâu, session có thể hết trong khi đang upload.

**Cách xử lý:**
- Đăng nhập lại và thử upload lại từ đầu
- Kiểm tra xem file nào đã upload thành công trước khi session hết

**Phòng ngừa:**
- Không để máy không hoạt động trong lúc upload
- Nếu upload file lớn, mở một tab khác và click vài thứ trong hệ thống để giữ session active
- Chia nhỏ thành nhiều lần upload, không upload tất cả một lúc

---

#### Lỗi 5: Upload xong nhưng quên Submit

**Triệu chứng:** File đã lên hệ thống, nhưng hồ sơ chưa được "nộp" chính thức.

**Cách hoạt động:** Hầu hết hệ thống có 2 bước: (1) Upload file → (2) Submit/Nộp hồ sơ. Nhiều người làm xong bước 1 rồi đóng máy.

**Cách xử lý:** Sau khi upload xong, luôn kiểm tra trạng thái hồ sơ trong hệ thống. Trạng thái phải là "Đã nộp" / "Submitted", không phải "Đang soạn" / "Draft".

**Phòng ngừa:** Sau khi Submit, chụp màn hình xác nhận. Đây là bằng chứng quan trọng nếu có tranh chấp.

---

### Backup plan khi hệ thống gặp sự cố

Nếu hệ thống sập hoặc có lỗi nghiêm trọng gần deadline và bạn không upload được:

**Bước 1:** Chụp màn hình lỗi (timestamp rõ ràng)

**Bước 2:** Gửi email ngay cho Ban Quản lý dự án / Bên mời thầu, với nội dung:
- Thông báo đang gặp sự cố kỹ thuật với hệ thống
- Đính kèm screenshot lỗi
- Hỏi hướng xử lý (nộp bản cứng, gia hạn, hay cách khác)

**Bước 3:** Gọi điện trực tiếp cho đầu mối liên lạc ghi trong HSMT

**Bước 4:** Lưu tất cả bằng chứng liên lạc (email, log cuộc gọi)

**Quan trọng:** Đây chỉ là backup plan - không phải giải pháp chính. Phần lớn trường hợp, nếu không có xác nhận gia hạn chính thức từ Bên mời thầu, hồ sơ vẫn bị coi là nộp trễ. Tốt nhất: upload sớm để không bao giờ cần dùng backup plan này.

---

### Tài liệu cần lưu sau khi nộp thành công

- [ ] Screenshot màn hình xác nhận "Nộp thành công" - có timestamp
- [ ] Biên nhận điện tử (nếu hệ thống cấp) - lưu PDF
- [ ] Danh sách file đã upload và trạng thái từng file
- [ ] Screenshot trang tổng quan hồ sơ với trạng thái "Đã nộp"

---

## 4. Ví dụ thực tế

**Tình huống:** Deadline 9:00 sáng thứ Hai. Nhà thầu A bắt đầu upload lúc 8:30 sáng.

8:30 - Bắt đầu upload. File đầu tiên 45MB → hệ thống báo lỗi file quá lớn (giới hạn 20MB).
8:35 - Compress PDF. Upload lại. File thứ 2 tên `Hồ sơ kỹ thuật (bản chính).pdf` → lỗi tên file.
8:42 - Đổi tên, upload lại. Hệ thống bắt đầu chậm vì nhiều người cùng upload.
8:55 - Vẫn còn 3 file chưa upload. Session hết hạn.
9:00 - Deadline. Hồ sơ chưa được Submit.

→ Kết quả: Bị loại.

**Nếu upload từ 6:00 sáng:** Tất cả lỗi trên đều có thể xử lý từ từ.

---$content_11$,
  $mistakes_11$[
  {
    "title": "Upload vào ngày deadline",
    "description": "Không có đủ thời gian xử lý khi có vấn đề phát sinh.",
    "severity": "medium"
  },
  {
    "title": "Không kiểm tra file sau khi upload",
    "description": "File upload lên nhưng bị lỗi (corrupt), download lại không mở được. Không ai biết cho đến khi Ban mời thầu mở hồ sơ.",
    "severity": "medium"
  },
  {
    "title": "Không lưu bằng chứng nộp thành công",
    "description": "Khi có tranh chấp về việc có nộp hồ sơ hay không, không có bằng chứng để bảo vệ.",
    "severity": "medium"
  },
  {
    "title": "Quên đọc hướng dẫn upload của hệ thống",
    "description": "Mỗi hệ thống có quy định riêng về format file, dung lượng, cấu trúc thư mục. Đọc hướng dẫn 1 lần tiết kiệm nhiều giờ sau đó.",
    "severity": "medium"
  }
]$mistakes_11$::jsonb,
  $fatal_11$[]$fatal_11$::jsonb,
  ARRAY['checklist-truoc-khi-nop', 'deadline-hieu-luc-ho-so']::text[],
  $quiz_11$[
  {
    "question": "File PDF của bạn nặng 35MB, hệ thống giới hạn 20MB. Bạn cần làm gì?",
    "options": [
      "Đổi tên file nhưng giữ nguyên dung lượng",
      "Compress PDF bằng Acrobat hoặc tool online để giảm dung lượng xuống dưới 20MB",
      "Upload nhiều lần cho đến khi hệ thống nhận",
      "Chuyển sang file Word dù HSMT yêu cầu PDF"
    ],
    "correct_answer": "Compress PDF bằng Acrobat hoặc tool online để giảm dung lượng xuống dưới 20MB",
    "explanation": "Khi file vượt giới hạn dung lượng, cần nén hoặc tách file theo đúng hướng dẫn của hệ thống/HSMT."
  },
  {
    "question": "Sau khi upload xong tất cả file, bạn cần làm gì trước khi đóng máy?",
    "options": [
      "Bấm Submit/Nộp hồ sơ và chụp màn hình xác nhận \"Đã nộp thành công\"",
      "Xóa file local để tránh nhầm lẫn",
      "Đóng tab ngay vì upload đã hoàn tất",
      "Chờ email tự động rồi mới kiểm tra sau"
    ],
    "correct_answer": "Bấm Submit/Nộp hồ sơ và chụp màn hình xác nhận \"Đã nộp thành công\"",
    "explanation": "Cần xác nhận trạng thái đã nộp thành công và lưu bằng chứng. Đây là bằng chứng quan trọng nếu có tranh chấp."
  },
  {
    "question": "Hệ thống gặp lỗi vào 30 phút trước deadline. Bước đầu tiên bạn nên làm là gì?",
    "options": [
      "Đợi thêm vì hệ thống có thể tự ổn định",
      "Chụp màn hình lỗi (có timestamp), sau đó gửi email + gọi điện ngay cho Bên mời thầu",
      "Tắt máy và nộp lại sau deadline",
      "Chỉ gọi điện, không cần lưu bằng chứng"
    ],
    "correct_answer": "Chụp màn hình lỗi (có timestamp), sau đó gửi email + gọi điện ngay cho Bên mời thầu",
    "explanation": "Khi gặp lỗi sát deadline, ưu tiên lưu bằng chứng có timestamp rồi liên hệ ngay bằng email và điện thoại. Không nên chỉ chờ hệ thống tự phục hồi."
  }
]$quiz_11$::jsonb,
  true,
  false
)
ON CONFLICT (slug) DO UPDATE SET
  title = excluded.title,
  title_en = excluded.title_en,
  tier = excluded.tier,
  category = excluded.category,
  tags = excluded.tags,
  objective = excluded.objective,
  explanation = excluded.explanation,
  content_mdx = excluded.content_mdx,
  common_mistakes = excluded.common_mistakes,
  fatal_errors = excluded.fatal_errors,
  related_slugs = excluded.related_slugs,
  quiz = excluded.quiz,
  is_published = excluded.is_published,
  is_priority = excluded.is_priority;
-- ============================================================
-- SEED: Supplemental learning content
-- Generated from bidmentor-supplements.md. Safe to rerun.
-- ============================================================

insert into public.lessons (
  slug,
  title,
  title_en,
  tier,
  category,
  tags,
  objective,
  explanation,
  content_mdx,
  common_mistakes,
  fatal_errors,
  related_slugs,
  quiz,
  is_published,
  is_priority
) values
(
  'compliance-matrix-ky-nang-core',
  $sup_title_0$Compliance Matrix - Kỹ năng đối chiếu requirement như chuyên gia$sup_title_0$,
  $sup_titleen_0$Compliance Matrix - The Core Skill of Technical Bidding$sup_titleen_0$,
  2,
  'quy-trinh',
  ARRAY['compliance matrix', 'technical compliance', 'requirement', 'HSMT', 'thực chiến']::text[],
  $sup_objective_0$Sau bài này, bạn có thể:
- Hiểu Compliance Matrix là gì và tại sao nó là kỹ năng core của hồ sơ kỹ thuật
- Xây dựng Compliance Matrix chuẩn cho bất kỳ HSMT nào
- Biết khi nào dùng "Comply", "Deviate", "Not Applicable" và cách xử lý từng trường hợp
- Tránh lỗi phổ biến khi điền Compliance Matrix khiến hồ sơ bị trừ điểm$sup_objective_0$,
  $sup_explanation_0$Hãy tưởng tượng HSMT là một bản danh sách yêu cầu dài 200 trang. Compliance Matrix là bảng tóm tắt nói với Ban mời thầu: "Đây - từng yêu cầu của anh, tôi đáp ứng như thế nào."

Không có Compliance Matrix, Ban mời thầu phải tự đi tìm trong 200 trang hồ sơ của bạn xem bạn có đáp ứng hay không. Kết quả: mất thời gian của họ, tăng risk bỏ sót của bạn.

Có Compliance Matrix tốt: mọi thứ minh bạch, rõ ràng, dễ chấm điểm - và bạn kiểm soát được câu chuyện.

> "Compliance Matrix không chỉ là tài liệu nộp kèm. Nó là bản đồ để Ban mời thầu thấy bạn hiểu yêu cầu của họ."$sup_explanation_0$,
  $sup_content_0$### Compliance Matrix là gì?

Compliance Matrix (hay Compliance Statement, Technical Compliance Schedule) là bảng đối chiếu từng yêu cầu kỹ thuật của HSMT với giải pháp/tài liệu của nhà thầu.

Cấu trúc cơ bản:

| # | Yêu cầu HSMT | Tham chiếu (Ref) | Mức độ đáp ứng | Tài liệu chứng minh | Ghi chú |
|---|---|---|---|---|---|
| 1 | Công suất thiết bị ≥ 500kW | Spec 3.2.1 | Comply | Datasheet Model XYZ - Trang 12 | Cung cấp 520kW |
| 2 | Điện áp vận hành: 380V ±10% | Spec 3.2.2 | Comply | Datasheet Model XYZ - Trang 14 | |
| 3 | Chứng nhận CE hoặc tương đương | Spec 4.1 | Comply | Certificate CE No. 12345 | |
| 4 | Hệ thống giám sát từ xa | Spec 5.3 | Deviate | Proposal Section 4, Trang 22 | Đề xuất giải pháp SCADA thay thế - xem ghi chú |

---

### 3 mức độ đáp ứng

#### COMPLY (Đáp ứng đầy đủ)

Giải pháp của bạn đáp ứng đúng hoặc vượt yêu cầu HSMT.

**Cách điền:** Ghi "Comply" và dẫn đến tài liệu chứng minh cụ thể (trang, mục).

🟢 LOW RISK - Đây là trạng thái tốt nhất.

---

#### DEVIATE (Đề xuất giải pháp thay thế)

Giải pháp của bạn khác với yêu cầu HSMT nhưng vẫn đáp ứng được mục tiêu kỹ thuật theo một cách khác.

**Khi nào dùng:**
- Yêu cầu HSMT chỉ định thương hiệu/model cụ thể nhưng bạn có giải pháp tương đương tốt hơn
- Yêu cầu kỹ thuật có thể đạt được bằng phương pháp khác
- Có tiêu chuẩn thay thế tương đương (ví dụ: ASME thay vì EN)

**Cách điền:**
1. Ghi "Deviate" trong cột Mức độ đáp ứng
2. Giải thích rõ điểm khác biệt
3. Chứng minh giải pháp thay thế đáp ứng mục tiêu kỹ thuật
4. Đính kèm tài liệu kỹ thuật hỗ trợ

🟠 HIGH RISK - Chủ đầu tư có quyền không chấp nhận deviation. Cân nhắc kỹ trước khi deviate.

> **Lưu ý thực tế:** Một số HSMT quy định "No Deviation Allowed" cho các yêu cầu bắt buộc (mandatory). Deviate vào những yêu cầu này = loại trực tiếp.

---

#### NOT APPLICABLE (Không áp dụng)

Yêu cầu đó không liên quan đến scope của bạn hoặc đã được xử lý theo cách khác.

**Khi nào dùng:**
- Yêu cầu áp dụng cho một phần scope không thuộc phạm vi hợp đồng của bạn
- Yêu cầu đã được đáp ứng ở nơi khác trong hồ sơ

**Cách điền:** Ghi "N/A" và giải thích ngắn gọn lý do.

🟡 MEDIUM - Dùng N/A quá nhiều mà không giải thích có thể gây nghi ngờ.

---

### Quy trình xây dựng Compliance Matrix đúng cách

**Bước 1: Extract toàn bộ requirements**

Đọc kỹ phần Technical Requirements / Employer's Requirements và liệt kê từng yêu cầu thành một dòng riêng. Đừng gộp nhiều yêu cầu vào một dòng.

**Bước 2: Phân loại requirement**

- Mandatory (bắt buộc): thường có từ "shall", "must", "required"
- Preferred (ưu tiên): thường có từ "should", "preferred"
- Informational: mô tả ngữ cảnh, không phải yêu cầu

🔴 FATAL: Deviate vào Mandatory requirement mà HSMT không cho phép → loại trực tiếp.

**Bước 3: Map với giải pháp của bạn**

Với mỗi requirement: tìm trong giải pháp của bạn phần nào đáp ứng, và dẫn đến đó.

**Bước 4: Xử lý các deviation**

Với mỗi deviation: viết justification rõ ràng, kèm technical evidence.

**Bước 5: Cross-check**

Review lại toàn bộ matrix, đảm bảo:
- Không bỏ sót requirement nào
- Mọi "Comply" đều có link đến tài liệu cụ thể
- Mọi "Deviate" đều có giải thích

---

### Template Compliance Matrix chuẩn

```
COMPLIANCE MATRIX
Gói thầu: _______________
Nhà thầu: _______________
Ngày: _______________

| STT | Điều khoản HSMT | Nội dung yêu cầu | Loại | Mức đáp ứng | Tài liệu chứng minh | Ghi chú/Deviation |
|-----|----------------|-----------------|------|-------------|--------------------|--------------------|
| 1   | Spec 3.1       | ...             | M    | Comply      | Vol.2, Sec.4, P.12  |                   |
| 2   | Spec 3.2       | ...             | M    | Deviate     | Vol.2, Sec.5, P.18  | [Giải thích]      |
| 3   | Spec 4.1       | ...             | P    | Comply      | Catalog A, P.5      |                   |

Chú thích:
M = Mandatory (bắt buộc)
P = Preferred (ưu tiên)
I = Informational
```

---

## 4. Ví dụ thực tế

**Gói thầu:** Cung cấp và lắp đặt máy phát điện dự phòng 500kVA

**Yêu cầu HSMT Spec 3.4:** "Generator set shall be of diesel type, minimum rated output 500kVA at 0.8pf, operating voltage 380V/220V, 50Hz."

**Compliance Matrix:**

| Yêu cầu | Loại | Đáp ứng | Tài liệu |
|---|---|---|---|
| Diesel type | M | Comply | Datasheet Cummins C550D5, P.2 |
| Min 500kVA at 0.8pf | M | Comply | 550kVA - Datasheet P.3 |
| 380V/220V | M | Comply | Datasheet P.4 |
| 50Hz | M | Comply | Datasheet P.4 |

**Ghi chú column:** "Proposed model: Cummins C550D5 - rated 550kVA, exceeds minimum requirement by 10%."

---$sup_content_0$,
  $sup_mistakes_0$[
  {
    "title": "Ghi \"Comply\" nhưng không có tài liệu chứng minh",
    "description": "Ban mời thầu không có căn cứ để verify - thường bị đánh dấu \"không đủ thông tin\" hoặc trừ điểm.",
    "severity": "high"
  },
  {
    "title": "Deviate vào yêu cầu Mandatory mà không biết",
    "description": "Đọc kỹ yêu cầu có phải Mandatory không trước khi chọn Deviate.",
    "severity": "fatal"
  },
  {
    "title": "Bỏ sót requirement trong matrix",
    "description": "Ban mời thầu sẽ coi là \"không đáp ứng\" - ngay cả khi thực ra bạn có giải pháp.",
    "severity": "high"
  },
  {
    "title": "Dùng N/A không giải thích",
    "description": "Quá nhiều N/A không có lý do khiến hồ sơ trông thiếu nghiêm túc.",
    "severity": "medium"
  },
  {
    "title": "Tham chiếu không chính xác",
    "description": "\"Xem hồ sơ kỹ thuật\" không đủ - phải là \"Vol.2, Section 4.2, Page 18\".",
    "severity": "medium"
  }
]$sup_mistakes_0$::jsonb,
  $sup_fatal_0$[]$sup_fatal_0$::jsonb,
  ARRAY['quick-scan-hsmt-5-phut', 'gap-analysis-nang-luc', 'reading-scc-dieu-khoan-nguy-hiem', 'checklist-truoc-khi-nop']::text[],
  $sup_quiz_0$[
  {
    "question": "HSMT yêu cầu \"equipment shall comply with EN 60947 standard\". Thiết bị của bạn có chứng nhận IEC 60947 - là tiêu chuẩn tương đương nhưng không phải EN. Bạn điền gì trong Compliance Matrix?",
    "options": [
      "Comply - IEC và EN là cùng tiêu chuẩn",
      "Deviate - giải thích IEC 60947 là tiêu chuẩn quốc tế tương đương EN 60947, đính kèm certificate IEC",
      "N/A - tiêu chuẩn không áp dụng cho thị trường Việt Nam",
      "Comply - và không cần giải thích thêm"
    ],
    "correct_answer": "Deviate - giải thích IEC 60947 là tiêu chuẩn quốc tế tương đương EN 60947, đính kèm certificate IEC",
    "explanation": "Về kỹ thuật, IEC 60947 và EN 60947 có nội dung tương đương, nhưng để an toàn pháp lý và rõ ràng với Ban mời thầu, điền Deviate kèm giải thích là cách đúng nhất. A không sai về kỹ thuật nhưng thiếu transparency."
  },
  {
    "question": "Requirement #12 ghi \"Contractor shall provide 24/7 on-site maintenance team during warranty period.\" Bạn đề xuất on-call response team (đến trong 4 tiếng) thay vì on-site thường trực. Bạn xử lý thế nào?",
    "options": [
      "Ghi Comply - response 4 tiếng là đủ tốt",
      "Ghi Deviate - giải thích rõ on-call model, cam kết SLA cụ thể, kèm evidence về effectiveness",
      "Ghi N/A - đây là yêu cầu vô lý",
      "Bỏ trống dòng này và giải thích trong phần narrative"
    ],
    "correct_answer": "Ghi Deviate - giải thích rõ on-call model, cam kết SLA cụ thể, kèm evidence về effectiveness",
    "explanation": "Đây là deviation cần được xử lý minh bạch. Ghi Comply khi không comply (A) là gian lận. N/A (C) không đúng. Bỏ trống (D) là cách tệ nhất - Ban mời thầu sẽ coi là không đáp ứng."
  }
]$sup_quiz_0$::jsonb,
  true,
  true
),
(
  'reading-scc-dieu-khoan-nguy-hiem',
  $sup_title_1$Reading SCC - Tìm điều khoản nguy hiểm trước khi ký$sup_title_1$,
  $sup_titleen_1$Reading Special Conditions of Contract - Finding the Danger Clauses$sup_titleen_1$,
  2,
  'quy-trinh',
  ARRAY['SCC', 'contract risk', 'liquidated damages', 'payment terms', 'commercial risk']::text[],
  $sup_objective_1$Sau bài này, bạn có thể:
- Hiểu tại sao SCC nguy hiểm hơn GCC và phải đọc kỹ như thế nào
- Nhận biết 6 loại điều khoản nguy hiểm phổ biến nhất trong SCC
- Biết khi nào nên gửi clarification về SCC, và khi nào nên cân nhắc lại quyết định GO$sup_objective_1$,
  $sup_explanation_1$GCC (General Conditions of Contract) là template chuẩn - FIDIC, NEC, hoặc mẫu Bộ Xây dựng. Nhiều người biết GCC là gì và không đọc kỹ vì "chuẩn quốc tế mà".

SCC (Special Conditions of Contract) là nơi Chủ đầu tư **sửa đổi GCC** cho phù hợp với gói thầu cụ thể. Và đây là nơi các điều khoản nguy hiểm thường nằm.

> "GCC là luật. SCC là luật của Chủ đầu tư. Và đôi khi, luật đó rất bất lợi cho bạn."

Nhiều nhà thầu thắng thầu, ký hợp đồng, rồi mới phát hiện ra: payment terms quá dài, LD không có cap, bảo hành quá khắt khe. Lúc đó đã muộn.

**Nguyên tắc:** Đọc SCC **trước** khi quyết định GO - không phải sau khi trúng thầu.$sup_explanation_1$,
  $sup_content_1$### 6 loại điều khoản nguy hiểm trong SCC

---

#### Điều khoản 1: Liquidated Damages (LD) - Phạt chậm tiến độ

**Là gì:** Mức phạt cố định mỗi ngày/tuần nếu nhà thầu không hoàn thành đúng hạn.

**Check những gì:**
- Mức phạt bao nhiêu? (thường 0.1–0.5% giá hợp đồng/ngày)
- Có **cap** không? (tổng phạt tối đa là bao nhiêu %)
- Thời điểm bắt đầu tính phạt: ngày ký hợp đồng hay ngày khởi công?

🔴 **FATAL WARNING: LD không có cap**

Ví dụ:
```
GCC Sub-Clause 8.7: LD = 0.5% per day
SCC: [Không có sửa đổi về cap]
```

Nếu chậm 60 ngày với hợp đồng 10 tỷ: LD = 3 tỷ đồng. Chậm 200 ngày = 10 tỷ = toàn bộ giá trị hợp đồng. Không có cap = risk vô hạn.

**Standard market:** LD có cap ở mức 5–10% giá hợp đồng. Nếu SCC không có cap → red flag nghiêm trọng.

---

#### Điều khoản 2: Payment Terms - Điều kiện thanh toán

**Là gì:** Khi nào và bao nhiêu % được thanh toán.

**Check những gì:**
- Có Advance Payment không? Bao nhiêu %?
- Thanh toán theo milestone nào? Tần suất ra sao?
- Bao nhiêu ngày sau khi nộp invoice thì được thanh toán?
- Có Retention không? Bao nhiêu %? Đến khi nào?

🟠 **HIGH RISK:** Payment terms bất lợi ảnh hưởng trực tiếp đến dòng tiền (cash flow).

**Ví dụ nguy hiểm:**
```
Payment: 30% upon contract signing, 70% upon final acceptance
Retention: 10% until end of Defects Liability Period (24 months)
```
→ Với hợp đồng 10 tỷ: bạn nhận 3 tỷ lúc ký, 6.3 tỷ sau nghiệm thu, còn 700 triệu bị giữ 24 tháng. Toàn bộ chi phí vật tư, nhân công phải tự ứng trong quá trình thực hiện.

**Standard market:** Advance 10–20%, thanh toán theo tiến độ hàng tháng, retention ≤ 5%, hoàn trả retention sau defects liability period.

---

#### Điều khoản 3: Defects Liability Period (DLP) - Thời gian bảo hành

**Là gì:** Thời gian sau khi nghiệm thu nhà thầu vẫn chịu trách nhiệm sửa chữa các lỗi phát sinh.

**Check những gì:**
- DLP bao lâu? (standard: 12 tháng, một số gói lên 24–36 tháng)
- DLP tính từ ngày nào: ngày nghiệm thu toàn bộ hay ngày nghiệm thu từng phần?
- Điều kiện extend DLP là gì? (nếu có defect, DLP có bị restart không?)

🟠 **HIGH RISK:** DLP > 24 tháng kết hợp với retention cao → tiền bị giữ lâu, risk phát sinh lỗi cao.

---

#### Điều khoản 4: Insurance Requirements - Yêu cầu bảo hiểm

**Là gì:** Các loại bảo hiểm nhà thầu phải mua và duy trì trong suốt dự án.

**Check những gì:**
- Loại bảo hiểm yêu cầu: CAR (Contractor's All Risk), TPL (Third Party Liability), Erection All Risk, Professional Indemnity…
- Mức coverage tối thiểu: bao nhiêu tiền?
- Ai là Additional Insured?
- Bảo hiểm phải mua trước ngày nào?

🟡 **MEDIUM:** Nhiều nhà thầu nhỏ không có sẵn các loại bảo hiểm chuyên biệt - và chi phí mua có thể làm lệch tính toán lợi nhuận.

---

#### Điều khoản 5: Dispute Resolution - Giải quyết tranh chấp

**Là gì:** Nếu có tranh chấp, giải quyết bằng cách nào, ở đâu, theo luật nào.

**Check những gì:**
- Arbitration hay tòa án?
- Địa điểm: trong nước hay nước ngoài? (gói quốc tế)
- Luật áp dụng: luật Việt Nam hay luật nước nào?
- Có DAB (Dispute Adjudication Board) không?

🟡 **MEDIUM:** Với gói trong nước, thường không phức tạp. Với gói quốc tế: arbitration ở nước ngoài tốn kém và bất lợi cho nhà thầu VN.

---

#### Điều khoản 6: Force Majeure & Extension of Time - Gia hạn tiến độ

**Là gì:** Điều kiện để nhà thầu được gia hạn tiến độ mà không bị phạt LD.

**Check những gì:**
- Force majeure được định nghĩa như thế nào? (có bao gồm dịch bệnh, chính sách nhà nước không?)
- Thủ tục thông báo: phải thông báo trong bao nhiêu ngày?
- Được gia hạn thời gian nhưng có được bồi thường chi phí không?

🟠 **HIGH RISK:** Thủ tục thông báo force majeure thường rất ngắn (7–14 ngày). Nếu không thông báo đúng hạn → mất quyền gia hạn dù có lý do chính đáng.

---

### Quy trình đọc SCC

**Bước 1:** Tìm SCC trong HSMT (thường là Section 8 hoặc Volume 3)

**Bước 2:** Đối chiếu với GCC - SCC thường ghi rõ "Sub-Clause X.Y is amended as follows" hoặc "The following is added to Sub-Clause X.Y"

**Bước 3:** Với 6 điều khoản nguy hiểm trên: tìm và đọc kỹ phần sửa đổi tương ứng

**Bước 4:** Đánh dấu và ghi chú rủi ro:
- 🔴 FATAL: Điều khoản không thể chấp nhận → cân nhắc clarification hoặc NO-GO
- 🟠 HIGH: Cần clarification hoặc đàm phán trước khi ký
- 🟡 MEDIUM: Cần tính vào giá và kế hoạch quản lý rủi ro

**Bước 5:** Quyết định:
- Có gửi clarification về điều khoản X không?
- Có cần điều chỉnh giá để cover thêm rủi ro không?
- Có nên reconsider GO/NO-GO không?

---

## 4. Ví dụ thực tế

**Gói thầu:** Xây dựng nhà máy chế biến thực phẩm - 50 tỷ VND - 18 tháng.

**Phát hiện trong SCC:**

| Điều khoản | Nội dung SCC | Đánh giá |
|---|---|---|
| LD | 0.3%/ngày, không có cap | 🔴 FATAL - LD vô hạn |
| Payment | 10% advance, thanh toán mỗi 3 tháng, retention 10% đến hết 24 tháng bảo hành | 🟠 HIGH - cash flow rất căng |
| DLP | 24 tháng, restart nếu có defect | 🟠 HIGH - retention bị giữ đến 4 năm sau nếu có defect |
| Insurance | CAR + TPL + PI, coverage ≥ 120% contract value | 🟡 MEDIUM - cần check phí bảo hiểm |

**Quyết định:**
- Gửi clarification yêu cầu thêm LD cap ở 10%
- Điều chỉnh giá tăng 3% để cover financing cost và insurance
- Nếu Chủ đầu tư từ chối cap LD → reconsider GO/NO-GO

---$sup_content_1$,
  $sup_mistakes_1$[
  {
    "title": "Đọc GCC nhưng bỏ qua SCC",
    "description": "\"GCC chuẩn quốc tế thì OK\" - nhưng SCC mới là nơi Chủ đầu tư sửa đổi bất lợi.",
    "severity": "high"
  },
  {
    "title": "Không check LD cap",
    "description": "Lỗi phổ biến nhất. LD không có cap = risk tài chính không giới hạn.",
    "severity": "fatal"
  },
  {
    "title": "Không tính payment terms vào giá",
    "description": "Payment chậm = chi phí vốn thực tế cao hơn. Phải tính vào giá chào.",
    "severity": "high"
  },
  {
    "title": "Bỏ qua thủ tục thông báo force majeure",
    "description": "Deadline thông báo thường 7–14 ngày. Trễ = mất quyền gia hạn.",
    "severity": "medium"
  }
]$sup_mistakes_1$::jsonb,
  $sup_fatal_1$[]$sup_fatal_1$::jsonb,
  ARRAY['cau-truc-hsmt-doc-tu-dau', 'quick-scan-hsmt-5-phut', 'compliance-matrix-ky-nang-core']::text[],
  $sup_quiz_1$[
  {
    "question": "SCC ghi: \"Sub-Clause 8.7 [Delay Damages]: Delay damages shall be 0.2% of the Contract Price per day of delay.\" Không có điều khoản nào khác về tổng mức phạt tối đa. Hợp đồng trị giá 20 tỷ. Bạn đánh giá thế nào?",
    "options": [
      "OK - 0.2%/ngày là mức bình thường trong thị trường",
      "🔴 FATAL - không có cap LD là rủi ro không giới hạn, cần yêu cầu thêm cap trước khi ký",
      "Chỉ là rủi ro lý thuyết - không cần quan tâm nếu tự tin hoàn thành đúng tiến độ",
      "Hỏi Ban mời thầu xem có thể giảm xuống 0.1%/ngày không"
    ],
    "correct_answer": "🔴 FATAL - không có cap LD là rủi ro không giới hạn, cần yêu cầu thêm cap trước khi ký",
    "explanation": "Dù 0.2%/ngày có vẻ thấp, không có cap LD là rủi ro nghiêm trọng. Nếu chậm 50 ngày: LD = 2 tỷ đồng (10% contract value). Standard là cap ở 10–15%. Nên gửi clarification yêu cầu thêm cap - không phải giảm rate như D đề xuất."
  },
  {
    "question": "Payment term trong SCC: \"30% upon signing, 40% upon substantial completion, 30% retained until Final Acceptance.\" Không có Advance Payment riêng. Hợp đồng 15 tỷ, thời gian thực hiện 14 tháng. Vấn đề gì?",
    "options": [
      "Bình thường - payment theo milestone là chuẩn",
      "30% đầu tiên là advance, đủ để bắt đầu",
      "30% bị giữ đến Final Acceptance có thể gây vấn đề cash flow nghiêm trọng - cần tính chi phí vốn vào giá",
      "Không có vấn đề vì tổng vẫn 100%"
    ],
    "correct_answer": "30% bị giữ đến Final Acceptance có thể gây vấn đề cash flow nghiêm trọng - cần tính chi phí vốn vào giá",
    "explanation": "30% = 4.5 tỷ bị giữ đến cuối dự án (14+ tháng). Trong 14 tháng đó, nhà thầu phải tự tài trợ toàn bộ chi phí thi công phần này. Chi phí vốn thực tế có thể là 5–8%/năm × 14 tháng × 4.5 tỷ ≈ 260–420 triệu. Nếu không tính vào giá, lợi nhuận bị ăn mòn đáng kể."
  }
]$sup_quiz_1$::jsonb,
  true,
  true
),
(
  'addendum-management-quan-ly-thay-doi',
  $sup_title_2$Addendum Management - Đừng làm hồ sơ theo bản HSMT cũ$sup_title_2$,
  $sup_titleen_2$Addendum Management - Tracking Every Change to the Bidding Document$sup_titleen_2$,
  2,
  'quy-trinh',
  ARRAY['addendum', 'clarification', 'version control', 'deadline', 'HSMT']::text[],
  $sup_objective_2$Sau bài này, bạn có thể:
- Hiểu Addendum là gì và có giá trị pháp lý như thế nào
- Thiết lập hệ thống theo dõi Addendum xuyên suốt quá trình chuẩn bị hồ sơ
- Xử lý đúng cách khi Addendum thay đổi requirement hoặc deadline
- Tránh lỗi nộp hồ sơ theo HSMT cũ - một trong những lỗi thầm lặng và nguy hiểm nhất$sup_objective_2$,
  $sup_explanation_2$Bạn đọc HSMT kỹ, làm hồ sơ cẩn thận, chuẩn bị đủ tài liệu. Nhưng trong khi bạn đang làm, Chủ đầu tư âm thầm phát hành một Addendum - sửa đổi yêu cầu kỹ thuật, thay đổi deadline, hoặc cập nhật biểu mẫu.

Bạn không biết. Bạn nộp hồ sơ theo bản cũ. Kết quả: bị loại vì không tuân thủ yêu cầu mới nhất - dù bạn đã đọc HSMT rất kỹ.

> "Addendum không báo cho bạn. Bạn phải tự đi tìm nó."$sup_explanation_2$,
  $sup_content_2$### Addendum là gì và tại sao quan trọng?

**Addendum** (số nhiều: Addenda) là văn bản sửa đổi, bổ sung HSMT do Chủ đầu tư phát hành sau khi HSMT đã được phát hành chính thức.

**Giá trị pháp lý:** Addendum là phần không tách rời của HSMT và có giá trị ràng buộc như HSMT gốc. Nếu HSMT gốc và Addendum mâu thuẫn: **Addendum mới hơn thường ưu tiên hơn.**

**Nội dung Addendum có thể gồm:**
- Sửa đổi yêu cầu kỹ thuật
- Thay đổi deadline (submission deadline, clarification deadline)
- Cập nhật biểu mẫu (form mới thay form cũ)
- Trả lời câu hỏi clarification của nhà thầu khác
- Đính chính lỗi trong HSMT gốc
- Thay đổi điều kiện tham gia

---

### Khi nào Addendum được phát hành?

- Sau khi nhà thầu gửi clarification → Chủ đầu tư trả lời qua Addendum
- Chủ đầu tư tự phát hiện lỗi trong HSMT
- Có thay đổi từ cơ quan phê duyệt cấp trên
- Thay đổi scope, budget, hoặc timeline dự án

🟠 **Không có quy định về số lượng Addendum.** Có gói thầu có 1 Addendum. Có gói có 5–7 Addenda trước deadline.

---

### Hệ thống theo dõi Addendum

**Rule #1: Kiểm tra hệ thống mỗi ngày làm việc**

Từ ngày nhận HSMT đến deadline, mỗi ngày check:
- Hệ thống e-procurement (muasamcong.mpi.gov.vn hoặc hệ thống tương ứng)
- Email chính thức đã đăng ký
- Thông báo trong hệ thống (notification)

Thời điểm nguy hiểm nhất: cuối tuần, ngày lễ, và 48 giờ trước deadline.

---

**Addendum Tracker - Template**

```
ADDENDUM TRACKER - [Tên gói thầu]

| # | Ngày phát hành | Nội dung tóm tắt | Ảnh hưởng đến hồ sơ | Đã cập nhật? | Người xử lý |
|---|----------------|-----------------|---------------------|-------------|------------|
| 01 | 10/07/2024 | Sửa thời hạn hiệu lực bảo lãnh từ 120 ngày lên 150 ngày | Cần xin lại thư bảo lãnh mới | ✅ Xong | Nguyễn A |
| 02 | 15/07/2024 | Thêm Form 6A - cam kết nhân sự key personnel | Cần điền thêm Form 6A, ký và đóng dấu | ✅ Xong | Trần B |
| 03 | 18/07/2024 | Sửa yêu cầu kinh nghiệm: từ 3 hợp đồng xuống còn 2 hợp đồng | Hồ sơ kinh nghiệm không cần thay đổi | ✅ Xong | Lê C |
```

---

### Quy trình xử lý khi nhận Addendum

**Bước 1: Đọc toàn bộ Addendum ngay**

Không để đến hôm sau. Addendum có thể thay đổi điều cốt lõi.

**Bước 2: Đánh giá impact**

- Thay đổi này ảnh hưởng đến phần nào của hồ sơ?
- Cần thêm/bớt tài liệu gì?
- Có thay đổi deadline không?
- Có thay đổi biểu mẫu không?

**Bước 3: Cập nhật Addendum Tracker**

Ghi nhận addendum mới, assign người xử lý, đặt deadline nội bộ để update hồ sơ.

**Bước 4: Update hồ sơ**

Thực hiện thay đổi cần thiết. Sau khi update: verify lại toàn bộ phần bị ảnh hưởng.

**Bước 5: Cross-check version control**

Đảm bảo phiên bản file trong thư mục FINAL là phiên bản đã cập nhật theo Addendum mới nhất.

---

### Tình huống đặc biệt: Addendum thay đổi deadline

🔴 **FATAL WARNING:** Đây là loại Addendum nguy hiểm nhất vì dễ bỏ sót.

Hai trường hợp:

**Gia hạn deadline:**
- Tốt cho bạn - có thêm thời gian
- Nhưng nếu không biết: bạn có thể vẫn nộp theo deadline cũ → không sai, nhưng lãng phí thời gian chuẩn bị

**Rút ngắn deadline:**
- Nguy hiểm - nếu không biết: nộp trễ và bị loại
- Hiếm gặp nhưng đã xảy ra trong thực tế

**Action ngay khi thấy deadline thay đổi:**
1. Update calendar/lịch nội bộ ngay
2. Thông báo cho cả team ngay lập tức
3. Recalculate timeline chuẩn bị hồ sơ

---

### Tình huống đặc biệt: Addendum phát hành sát deadline

Chủ đầu tư phát hành Addendum 24–48 tiếng trước deadline - không phải hiếm.

**Xử lý:**

1. Đọc ngay, đánh giá impact
2. Nếu thay đổi nhỏ (sửa form, đính chính lỗi đánh máy): cập nhật và nộp theo kế hoạch
3. Nếu thay đổi lớn (sửa yêu cầu kỹ thuật, thêm tài liệu mới): xem xét gửi email cho Chủ đầu tư hỏi về khả năng gia hạn - có căn cứ pháp lý vì Addendum quá sát deadline

---

## 4. Ví dụ thực tế

**Timeline gói thầu xây lắp - 30 ngày chuẩn bị:**

```
Ngày 1:   Nhận HSMT
Ngày 5:   Addendum 01 - Đính chính lỗi trong bảng khối lượng BOQ (ít ảnh hưởng)
Ngày 12:  Addendum 02 - Thêm yêu cầu chứng chỉ ISO 14001 cho nhà thầu
          → IMPACT CAO: Cần kiểm tra ngay công ty có ISO 14001 không
          → Nếu không có: GAP mới xuất hiện sau khi đã quyết định GO
Ngày 20:  Addendum 03 - Trả lời clarification của nhà thầu khác về định nghĩa "similar work"
          → Thông tin quan trọng: định nghĩa rõ hơn có lợi cho mình
Ngày 25:  Addendum 04 - Gia hạn deadline thêm 7 ngày
          → Thêm thời gian - update lịch ngay
```

→ Kết quả: Addendum 02 là quan trọng nhất và cần xử lý ngay. Nhà thầu không theo dõi hàng ngày sẽ bỏ sót và nộp hồ sơ thiếu chứng chỉ ISO 14001.

---$sup_content_2$,
  $sup_mistakes_2$[
  {
    "title": "Không check hệ thống hàng ngày",
    "description": "Addendum có thể đến bất cứ lúc nào, kể cả cuối tuần. Thiết lập alert email nếu hệ thống hỗ trợ.",
    "severity": "fatal"
  },
  {
    "title": "Biết có Addendum nhưng \"đọc sau\"",
    "description": "Đọc sau = không đủ thời gian xử lý, hoặc quên luôn.",
    "severity": "high"
  },
  {
    "title": "Không update biểu mẫu khi có form mới",
    "description": "Nộp hồ sơ với form cũ khi Addendum đã ban hành form mới → có thể bị loại vì không tuân thủ.",
    "severity": "high"
  },
  {
    "title": "Không thông báo cho cả team",
    "description": "Một người biết, người khác không biết → các phần hồ sơ không nhất quán.",
    "severity": "medium"
  },
  {
    "title": "Không verify version control sau khi cập nhật Addendum",
    "description": "Update file nhưng không đảm bảo file trong thư mục FINAL là phiên bản mới nhất → nộp bản cũ.",
    "severity": "fatal"
  }
]$sup_mistakes_2$::jsonb,
  $sup_fatal_2$[]$sup_fatal_2$::jsonb,
  ARRAY['quy-trinh-clarification', 'checklist-truoc-khi-nop', 'xu-ly-upload-loi-e-procurement']::text[],
  $sup_quiz_2$[
  {
    "question": "Bạn nhận được Addendum 03, phát hành 3 ngày trước deadline, thay đổi yêu cầu kinh nghiệm từ \"3 hợp đồng tương tự\" xuống còn \"2 hợp đồng tương tự\". Công ty bạn có 2 hợp đồng đủ tiêu chí. Bạn làm gì?",
    "options": [
      "Không cần làm gì - yêu cầu thấp hơn trước, hồ sơ vẫn đủ điều kiện",
      "Kiểm tra lại hồ sơ kinh nghiệm hiện tại xem có cần cập nhật gì không, và xác nhận 2 hợp đồng đang claim là đúng theo định nghĩa mới trong Addendum",
      "Thêm vào hồ sơ thêm 1 hợp đồng nữa cho chắc",
      "Gửi email hỏi Chủ đầu tư xác nhận mình đủ điều kiện"
    ],
    "correct_answer": "Kiểm tra lại hồ sơ kinh nghiệm hiện tại xem có cần cập nhật gì không, và xác nhận 2 hợp đồng đang claim là đúng theo định nghĩa mới trong Addendum",
    "explanation": "Addendum có thể thay đổi cả định nghĩa \"tương tự\" chứ không chỉ số lượng. Cần đọc kỹ toàn bộ nội dung Addendum và verify lại hồ sơ. A đúng về số lượng nhưng chưa đủ cẩn thận. C không cần thiết. D tốn thời gian và không cần thiết nếu yêu cầu đã rõ."
  },
  {
    "question": "Addendum 01 phát hành ngày 5/7, thay đổi bid validity từ 90 ngày lên 120 ngày. Thư bảo lãnh bạn đã xin có hiệu lực đến 14/10 (tính cho 90 ngày + 30 ngày buffer từ deadline 15/7). Bạn cần làm gì?",
    "options": [
      "Không cần làm gì - 14/10 vẫn là sau deadline nộp thầu",
      "Tính lại: Bid validity 120 ngày từ 15/7 = hết hạn 12/11. Thư bảo lãnh cần hiệu lực đến ít nhất 12/12 (thêm 30 ngày). Cần xin thư bảo lãnh mới.",
      "Hỏi Chủ đầu tư xem thư bảo lãnh cũ có được chấp nhận không",
      "Nộp thư bảo lãnh cũ và đính kèm note giải thích"
    ],
    "correct_answer": "Tính lại: Bid validity 120 ngày từ 15/7 = hết hạn 12/11. Thư bảo lãnh cần hiệu lực đến ít nhất 12/12 (thêm 30 ngày). Cần xin thư bảo lãnh mới.",
    "explanation": "Addendum thay đổi bid validity → thay đổi trực tiếp yêu cầu về thời hạn hiệu lực bảo lãnh. Phải tính lại và xin thư bảo lãnh mới. A sai vì 14/10 không đủ cover 120 ngày bid validity + buffer. C và D đều là rủi ro không đáng."
  }
]$sup_quiz_2$::jsonb,
  true,
  true
)
ON CONFLICT (slug) DO UPDATE SET
  title = excluded.title,
  title_en = excluded.title_en,
  tier = excluded.tier,
  category = excluded.category,
  tags = excluded.tags,
  objective = excluded.objective,
  explanation = excluded.explanation,
  content_mdx = excluded.content_mdx,
  common_mistakes = excluded.common_mistakes,
  fatal_errors = excluded.fatal_errors,
  related_slugs = excluded.related_slugs,
  quiz = excluded.quiz,
  is_published = excluded.is_published,
  is_priority = excluded.is_priority;

update public.lessons as l
set
  content_mdx = coalesce(v.content_mdx, l.content_mdx),
  quiz = coalesce(v.quiz, l.quiz)
from (values
(
  'top-loi-bi-loai-chi-tu',
  null::text,
  $sup_update_quiz_0$[
  {
    "question": "HSMT yêu cầu người ký Đơn dự thầu phải là \"người có thẩm quyền theo quy định pháp luật\". Giám đốc công ty bạn đang công tác nước ngoài - không thể ký trực tiếp. Phó Giám đốc sẵn sàng ký. Bạn xử lý thế nào?",
    "options": [
      "Để Phó GĐ ký trực tiếp - chức danh Phó GĐ là đủ thẩm quyền",
      "Chuẩn bị Giấy ủy quyền từ GĐ cho Phó GĐ, công chứng đúng theo quy định, đính kèm vào hồ sơ",
      "Để GĐ ký scan và gửi qua email, in ra đính vào hồ sơ",
      "Hỏi Ban mời thầu xem chữ ký Phó GĐ có được chấp nhận không"
    ],
    "correct_answer": "Chuẩn bị Giấy ủy quyền từ GĐ cho Phó GĐ, công chứng đúng theo quy định, đính kèm vào hồ sơ",
    "explanation": "Ủy quyền ký hợp lệ phải bằng văn bản, được công chứng. Chữ ký scan không hợp lệ với hồ sơ cứng. Phó GĐ ký không có ủy quyền là fatal error."
  }
]$sup_update_quiz_0$::jsonb
),
(
  'bao-lanh-du-thau-khong-duoc-sai',
  null::text,
  $sup_update_quiz_1$[
  {
    "question": "HSMT quy định Bid Validity là 90 ngày kể từ ngày nộp thầu. Ngày nộp thầu là 15/07/2024. Bạn cần xin thư bảo lãnh có hiệu lực đến ngày nào?",
    "options": [
      "15/10/2024 (đúng 90 ngày)",
      "14/11/2024 (90 ngày + 30 ngày buffer)",
      "31/12/2024 (cho chắc)",
      "Ngày nộp thầu là được, không cần tính bid validity"
    ],
    "correct_answer": "14/11/2024 (90 ngày + 30 ngày buffer)",
    "explanation": "Bid validity hết quanh ngày 13/10/2024. Thư bảo lãnh phải cover thêm ít nhất 28–30 ngày buffer, nên tối thiểu đến 12–14/11/2024."
  }
]$sup_update_quiz_1$::jsonb
),
(
  'quick-scan-hsmt-5-phut',
  $sup_update_content_2$### Framework Quick Scan - 5 bước (theo thứ tự này)

Luôn check theo đúng thứ tự. Nếu bước nào fail → dừng lại, không cần check tiếp.

---

#### Bước 1: Điều kiện tham gia - "Mình có được phép dự không?"

Tìm ở: Mục "Eligibility", "Điều kiện tham gia", "Tư cách nhà thầu" (thường ở đầu HSMT hoặc Section 2).

Cần check:
- Loại hình công ty được phép dự (nhà thầu độc lập, JV, nước ngoài…)
- Giấy phép đặc thù cần có (ví dụ: giấy phép xây dựng, chứng chỉ ngành)
- Công ty mình có đang bị cấm thầu không
- Có yêu cầu vốn điều lệ tối thiểu không

**Red flag:** Yêu cầu năng lực cụ thể mà mình chắc chắn không có → NO-GO ngay.

---

#### Bước 2: Bảo lãnh dự thầu - "Mình có lo được tiền không?"

Tìm ở: Mục "Bid Security", "Bảo đảm dự thầu".

Cần check:
- Số tiền bảo lãnh là bao nhiêu (thường 1–3% giá trị gói thầu)
- Hình thức chấp nhận: thư bảo lãnh ngân hàng, tiền mặt, hay cả hai
- Ngân hàng phát hành có phải ngân hàng trong danh sách được chấp nhận không
- Thời hạn hiệu lực của bảo lãnh (phải dài hơn bid validity ít nhất 30 ngày)

**Red flag:** Yêu cầu ngân hàng cụ thể mà công ty bạn không có quan hệ → cần confirm trước.

---

#### Bước 3: Kinh nghiệm tương tự - "Mình có đủ hồ sơ chứng minh không?"

Tìm ở: Mục "Experience", "Kinh nghiệm tương tự", "Similar Contracts".

Cần check:
- Số lượng hợp đồng tương tự yêu cầu (vd: ít nhất 3 hợp đồng trong 5 năm)
- Quy mô tối thiểu của mỗi hợp đồng (vd: ít nhất 50% giá trị gói này)
- "Tương tự" được định nghĩa như thế nào (ngành, loại công việc, quy mô)
- Bằng chứng cần có: hợp đồng + biên bản nghiệm thu hay chỉ cần hợp đồng

**Red flag:** Định nghĩa "tương tự" quá hẹp, hoặc yêu cầu nghiệm thu mà mình chưa có đủ → Conditional GO, cần đánh giá kỹ.

---

#### Bước 4: Deadline - "Mình có đủ thời gian làm không?"

Cần check:
- Ngày nộp hồ sơ (deadline)
- Số ngày còn lại tính từ hôm nay
- Khối lượng hồ sơ cần chuẩn bị (ước lượng)
- Có ngày clarification không (nếu có, timeline càng ngắn)

**Rule of thumb:**
- Gói đơn giản: cần ít nhất 7–10 ngày
- Gói trung bình: cần ít nhất 14–21 ngày
- Gói lớn/phức tạp: cần ít nhất 30 ngày

**Red flag:** Còn dưới 7 ngày mà hồ sơ phức tạp → cân nhắc kỹ.

---

#### Bước 5: Red flags & Suspicious Clauses - "Có bẫy không?"

Một số dấu hiệu cần cảnh giác:

| Dấu hiệu | Ý nghĩa |
|---|---|
| Thông số kỹ thuật chỉ khớp đúng 1 thương hiệu | Gói thầu có thể đã "chỉ định" nhà cung cấp |
| Yêu cầu kinh nghiệm rất cụ thể + địa bàn cụ thể | Nhà thầu khác khó đáp ứng |
| Thời gian nộp hồ sơ quá ngắn | Có thể có nhà thầu được ưu tiên |
| Bảo lãnh thực hiện bất thường cao (>10%) | Risk tài chính lớn |
| Liquidated Damages quá cao, không có cap | Risk pháp lý |
| HSMT mơ hồ, nhiều điều khoản mâu thuẫn | Cần clarification hoặc cân nhắc bỏ qua |

---

---

#### Bước 6: Commercial Risk - "Có thắng mà vẫn thua không?"

🟠 Đây là check mà người mới hay bỏ qua nhất.

Một gói thầu có thể **technically doable** nhưng **commercially suicidal**. Tìm phần SCC (Special Conditions of Contract) và check:

| Điều khoản | Cần check gì | Red flag |
|---|---|---|
| **Payment Terms** | Thanh toán khi nào, bao lâu sau nghiệm thu? | > 90 ngày sau nghiệm thu → risk dòng tiền |
| **Retention** | Giữ lại bao nhiêu % và đến khi nào? | > 10% giữ đến hết bảo hành → đóng băng tiền lâu |
| **Liquidated Damages (LD)** | Phạt chậm tiến độ bao nhiêu/ngày? Có cap không? | Không có cap LD → risk vô hạn |
| **Advance Payment** | Có advance không? Bao nhiêu %? | 0% advance → phải tự ứng 100% vốn |
| **Warranty Period** | Bảo hành bao lâu? Điều kiện gì? | > 24 tháng với điều kiện khắt khe → risk cao |

**Red flag tổng:** Nếu có từ 2 điều khoản bất lợi trở lên → đây là Conditional GO cần phân tích sâu hơn, không phải GO đơn giản.

---

#### Bước 7: Scope Clarity - "Mình biết mình đang làm gì không?"

Scope mơ hồ = risk variation order và tranh chấp sau này. Check:

- **BOQ vs Technical Specs:** Số lượng/khối lượng trong BOQ có khớp với specs kỹ thuật không?
- **Drawing:** Bản vẽ có đủ và rõ ràng không, hay chỉ có "drawings to be provided later"?
- **Interface:** Ai chịu trách nhiệm phần nào nếu có interface với nhà thầu khác?
- **Exclusions:** HSMT có liệt kê rõ những gì **không** bao gồm trong scope không?

**Red flag:** "Works as per Engineer's instruction" hoặc "to the satisfaction of the Employer" mà không có tiêu chí cụ thể → tranh chấp nghiệm thu rất cao.

### Template Quick Scan

```
QUICK SCAN - [Tên gói thầu]
Ngày check: ___________
Người check: ___________

BỘ CHECK 7 BƯỚC:

1. ĐIỀU KIỆN THAM GIA
   [ ] Loại hình công ty: __________ → Đạt / Không đạt
   [ ] Giấy phép đặc thù: __________ → Có / Không
   [ ] Vốn điều lệ tối thiểu: __________ → Đạt / Không đạt
   → KẾT LUẬN BƯỚC 1: PASS / FAIL

2. BẢO LÃNH DỰ THẦU
   [ ] Số tiền: __________ → Lo được / Không lo được
   [ ] Ngân hàng yêu cầu: __________ → Có quan hệ / Cần xử lý
   [ ] Hiệu lực: __________ ngày
   → KẾT LUẬN BƯỚC 2: PASS / FAIL

3. KINH NGHIỆM TƯƠNG TỰ
   [ ] Yêu cầu: __ hợp đồng, tối thiểu __ tỷ, trong __ năm
   [ ] Mình có: __ hợp đồng đủ tiêu chí
   [ ] Bằng chứng cần: Hợp đồng + Nghiệm thu / Chỉ hợp đồng
   → KẾT LUẬN BƯỚC 3: PASS / CONDITIONAL / FAIL

4. DEADLINE
   [ ] Ngày nộp: __________
   [ ] Số ngày còn lại: __ ngày
   [ ] Ước tính khối lượng: Đơn giản / Trung bình / Phức tạp
   → KẾT LUẬN BƯỚC 4: PASS / TIGHT / FAIL

5. RED FLAGS
   [ ] Thông số kỹ thuật: Bình thường / Đáng ngờ
   [ ] Điều khoản tài chính: Bình thường / Bất thường
   [ ] HSMT: Rõ ràng / Mơ hồ
   → KẾT LUẬN BƯỚC 5: CLEAN / CÓ VẤN ĐỀ

6. COMMERCIAL RISK
   [ ] Payment terms: __ ngày → Chấp nhận được / Quá dài
   [ ] Retention: __% đến khi nào → OK / Bất thường
   [ ] Liquidated Damages: có cap không → Có / Không có (RED FLAG)
   [ ] Advance payment: __% → Đủ / Không có
   → KẾT LUẬN BƯỚC 6: ACCEPTABLE / HIGH RISK / FATAL

7. SCOPE CLARITY
   [ ] BOQ khớp với specs: Có / Mâu thuẫn
   [ ] Drawings: Đầy đủ / Thiếu
   [ ] Scope exclusions: Rõ ràng / Mơ hồ
   → KẾT LUẬN BƯỚC 7: CLEAR / CẦN CLARIFICATION / MƠ HỒ

─────────────────────────
KẾT LUẬN TỔNG: GO / NO-GO / CONDITIONAL GO
Lý do: ___________
Action tiếp theo: ___________
```

---

### Decision Tree: GO / NO-GO / Conditional GO

**NO-GO ngay nếu:**
- Không đủ tư cách tham gia (eligibility fail)
- Không có bảo lãnh dự thầu trong thời hạn yêu cầu
- Thiếu kinh nghiệm tương tự quá xa so với yêu cầu (vd: yêu cầu 5 hợp đồng, mình có 1)
- Deadline còn dưới 5 ngày mà hồ sơ phức tạp

**Conditional GO nếu:**
- Thiếu 1–2 hợp đồng kinh nghiệm nhưng có thể xử lý qua JV hoặc subcontract
- Ngân hàng bảo lãnh cần xử lý nhưng còn đủ thời gian
- Có một số điểm mơ hồ cần gửi clarification

**GO khi:**
- Pass cả 5 bước
- Risk nhận diện được và có kế hoạch xử lý

---

---

## Người làm thầu lâu năm nghĩ khác gì?

Quick Scan không chỉ là checklist - nó là cách tư duy. Đây là sự khác biệt thực sự:

| Người mới nghĩ | Người làm thầu lâu năm nghĩ |
|---|---|
| "Mình cố gắng là làm được" | "Win probability có đáng để burn 3 tuần nguồn lực không?" |
| "Thiếu 1 hợp đồng chắc Chủ đầu tư thông cảm" | "Qualification threshold thường binary - có hoặc không. Không có vùng xám." |
| "Còn 10 ngày là đủ rồi" | "10 ngày với hồ sơ EPC phức tạp là cực ngắn. Timeline thực tế là 8 ngày vì phải chờ bảo lãnh." |
| "Bỏ qua red flag đó đi, làm trước" | "Red flag là tín hiệu - đọc kỹ hơn hoặc hỏi clarification trước khi quyết định." |
| "Gói này mình làm được kỹ thuật" | "Technically doable nhưng commercial terms có suicide không?" |

> Người làm thầu lâu năm không làm hồ sơ tốt hơn vì họ giỏi hơn. Họ không làm những gói thầu không nên làm - và dồn toàn lực cho những gói có cơ hội thật sự.

## 4. Ví dụ thực tế

**Gói thầu:** Cung cấp & lắp đặt hệ thống điện năng lượng mặt trời cho tòa nhà văn phòng

**Quick Scan thực tế:**

| Bước | Yêu cầu | Tình trạng | Kết luận |
|---|---|---|---|
| Điều kiện | Có giấy phép điện, nhà thầu VN | Có đủ | PASS |
| Bảo lãnh | 500 triệu, BL ngân hàng | Cần gọi ngân hàng confirm | PASS (cần xác nhận) |
| Kinh nghiệm | 3 hợp đồng solar ≥ 500kWp trong 5 năm | Có 2 hợp đồng đủ tiêu chí | CONDITIONAL |
| Deadline | Còn 18 ngày | Đủ thời gian | PASS |
| Red flags | Thông số chỉ nhắc đến "panel nhập khẩu EU" | Cần đọc kỹ hơn | CÓ VẤN ĐỀ NHỎ |

→ **Kết luận: Conditional GO**
→ **Action:** Xem xét thêm 1 hợp đồng solar có thể claim được, gửi clarification về "panel EU"

---$sup_update_content_2$,
  $sup_update_quiz_2$[
  {
    "question": "HSMT yêu cầu 3 hợp đồng tương tự completed trong 5 năm. Công ty bạn có: (1) 1 hợp đồng prime contractor đủ tiêu chí, (2) 1 hợp đồng prime contractor nhưng chưa có biên bản nghiệm thu, (3) 1 hợp đồng với tư cách subcontractor. HSMT không nói rõ subcontract có được tính không. Bạn quyết định:",
    "options": [
      "Khai cả 3, để Ban mời thầu tự đánh giá",
      "Chỉ khai hợp đồng (1), quyết định NO-GO vì chỉ có 1 hợp đồng chắc chắn",
      "Gửi clarification hỏi: \"Subcontract và hợp đồng chưa có nghiệm thu có được tính không?\" trước khi quyết định",
      "Khai (1) và (2), bỏ (3) vì subcontract thường không được tính"
    ],
    "correct_answer": "Gửi clarification hỏi: \"Subcontract và hợp đồng chưa có nghiệm thu có được tính không?\" trước khi quyết định",
    "explanation": "Khi HSMT không rõ ràng, clarification là bước đúng nhất trước khi ra quyết định. Khai hồ sơ không chắc đủ điều kiện có thể tạo rủi ro."
  }
]$sup_update_quiz_2$::jsonb
),
(
  'gap-analysis-nang-luc',
  $sup_update_content_3$### 4 nhóm năng lực cần đối chiếu

---

#### Nhóm 1: Tài chính

Các yêu cầu thường gặp:
- Doanh thu tối thiểu (vd: ≥ 2 lần giá trị gói thầu trong 3 năm gần nhất)
- Vốn chủ sở hữu tối thiểu
- Báo cáo tài chính đã kiểm toán (thường 3 năm gần nhất)
- Hạn mức tín dụng ngân hàng

Cần chuẩn bị:
- Số liệu BCTC 3 năm gần nhất
- Xác nhận hạn mức từ ngân hàng (nếu cần)

**Cảnh báo:** Nhiều HSMT yêu cầu BCTC "đã được kiểm toán độc lập". Nếu BCTC công ty bạn chưa kiểm toán → đây là GAP nghiêm trọng, không thể xử lý trong vài ngày.

---

#### Nhóm 2: Kỹ thuật

Các yêu cầu thường gặp:
- Kinh nghiệm tương tự (số hợp đồng, quy mô, loại hình)
- Thiết bị, máy móc sở hữu hoặc thuê dài hạn
- Chứng chỉ kỹ thuật của công ty (ISO, chứng chỉ ngành)
- Năng lực sản xuất/thi công

Cần chuẩn bị:
- Danh mục hợp đồng đã thực hiện (kèm biên bản nghiệm thu)
- Danh sách thiết bị kèm giấy tờ sở hữu/thuê

---

#### Nhóm 3: Nhân sự

Các yêu cầu thường gặp:
- Key personnel (Project Manager, Technical Lead…) với yêu cầu cụ thể về kinh nghiệm và chứng chỉ
- Số lượng nhân sự kỹ thuật tối thiểu
- Chứng chỉ hành nghề cá nhân

Cần chuẩn bị:
- CV chuẩn format HSMT yêu cầu
- Bản sao chứng chỉ hành nghề
- Xác nhận cam kết tham gia dự án

**Cảnh báo:** Key personnel phải "cam kết tham gia" - nếu họ đang trong hợp đồng khác, đây là GAP cần xử lý.

---

#### Nhóm 4: Pháp lý

Các yêu cầu thường gặp:
- Giấy phép kinh doanh đúng ngành nghề
- Giấy phép đặc thù (xây dựng, điện, y tế…)
- Tư cách hợp lệ (không bị cấm thầu, không đang kiện tụng)
- Các chứng nhận: ISO, HACCP, CE…

---

### Template GAP Analysis

```
GAP ANALYSIS - [Tên gói thầu]
Ngày: ___________

| Nhóm | Yêu cầu HSMT | Tình trạng công ty | GAP | Mức độ | Hướng xử lý |
|------|-------------|-------------------|-----|--------|-------------|
| Tài chính | Doanh thu ≥ 50 tỷ/năm × 3 năm | 35 tỷ/năm | -15 tỷ | CAO | JV với đối tác lớn hơn |
| Tài chính | BCTC kiểm toán | Chưa kiểm toán | Thiếu | FATAL | NO-GO hoặc xử lý ngay |
| Kỹ thuật | 3 hợp đồng solar ≥ 500kWp | 2 hợp đồng | Thiếu 1 | TRUNG BÌNH | Tìm subcontractor có kinh nghiệm |
| Nhân sự | PM ≥ 10 năm kinh nghiệm | PM hiện tại: 7 năm | -3 năm | CAO | Tìm PM bên ngoài |
| Pháp lý | Chứng chỉ ISO 9001 | Đã có | Không có GAP | - | - |
```

**Cột Mức độ:**
- **FATAL**: Không thể xử lý → NO-GO
- **CAO**: Khó xử lý, cần đối tác/JV
- **TRUNG BÌNH**: Có thể xử lý nhưng cần thời gian/nguồn lực
- **THẤP**: Xử lý được dễ dàng

---

---

### Readiness Score - Đọc kết quả GAP bằng số

Sau khi điền GAP Analysis, tính điểm theo 4 nhóm:

| Nhóm | Không có GAP | GAP thấp | GAP trung bình | GAP cao | GAP fatal |
|---|---|---|---|---|---|
| Điểm | 100 | 75 | 50 | 25 | 0 |

**Ngưỡng quyết định:**
- ≥ 85: GO - rủi ro thấp
- 70–84: Conditional GO - xử lý GAP trước khi nộp
- 50–69: Conditional GO có điều kiện - cân nhắc JV
- < 50: NO-GO hoặc cần JV partner mạnh

> Readiness Score không phải con số tuyệt đối. Nó là công cụ để team cùng nhìn thấy bức tranh rủi ro - và ưu tiên xử lý đúng chỗ.

### Cách xử lý từng loại GAP

#### GAP THẤP - Tự xử lý
Ví dụ: thiếu một số tài liệu, format CV chưa chuẩn
→ Xử lý trong nội bộ, không cần đối tác

#### GAP TRUNG BÌNH - Cần subcontractor
Ví dụ: thiếu 1 hợp đồng kinh nghiệm hoặc thiếu một loại thiết bị
→ Ký hợp đồng subcontract với đơn vị có kinh nghiệm
→ Lưu ý: không phải HSMT nào cũng chấp nhận subcontract cho phần core

#### GAP CAO - Cân nhắc JV
Ví dụ: thiếu doanh thu, thiếu nhiều hợp đồng tương tự
→ Liên danh với đối tác bổ sung năng lực
→ Cần thỏa thuận JV rõ ràng trước khi nộp hồ sơ

#### GAP FATAL - NO-GO
Ví dụ: không có giấy phép hành nghề, BCTC chưa kiểm toán, thiếu tư cách pháp lý
→ Không thể xử lý trong thời gian còn lại
→ Quyết định NO-GO, chuyển nguồn lực sang gói khác

---

## 4. Ví dụ thực tế

**Tình huống:** Gói thầu tư vấn thiết kế hệ thống PCCC cho tòa nhà 20 tầng. Giá trị: 8 tỷ VND.

**GAP Analysis:**

| Yêu cầu | Tình trạng | GAP | Mức độ | Xử lý |
|---|---|---|---|---|
| Doanh thu ≥ 16 tỷ/năm × 3 năm | 20 tỷ/năm | Không có GAP | - | OK |
| 2 hợp đồng PCCC tòa nhà >15 tầng | 1 hợp đồng đủ tiêu chí | Thiếu 1 | TRUNG BÌNH | Xem xét JV hoặc subcontract |
| Chứng chỉ tư vấn PCCC cấp tỉnh | Có | Không có GAP | - | OK |
| PM: ≥ 8 năm kinh nghiệm PCCC | PM: 5 năm | -3 năm | CAO | Tìm PM bên ngoài hoặc JV |

→ **Kết luận:** Conditional GO - cần xử lý 2 GAP trước khi quyết định nộp.

---$sup_update_content_3$,
  $sup_update_quiz_3$[
  {
    "question": "GAP Analysis cho thấy: Tài chính OK, Pháp lý OK, Kỹ thuật thiếu 1 hợp đồng tương tự (GAP trung bình), Nhân sự thiếu PM đủ tiêu chí (GAP cao). Deadline còn 21 ngày. Bạn nên:",
    "options": [
      "Quyết định NO-GO - có 2 GAP là quá nhiều",
      "GO luôn - 21 ngày đủ xử lý",
      "Xử lý nhân sự trước (GAP cao nhất), sau đó xem xét lại quyết định trong 3–5 ngày tới",
      "Tìm JV partner có thể bổ sung cả kinh nghiệm lẫn nhân sự"
    ],
    "correct_answer": "Xử lý nhân sự trước (GAP cao nhất), sau đó xem xét lại quyết định trong 3–5 ngày tới",
    "explanation": "Ưu tiên xử lý GAP cao nhất trước. Nếu tìm được PM phù hợp trong vài ngày, GAP kỹ thuật có thể xử lý tiếp qua subcontract hoặc JV."
  }
]$sup_update_quiz_3$::jsonb
),
(
  'checklist-truoc-khi-nop',
  $sup_update_content_4$### Checklist đầy đủ - 5 nhóm

---

#### NHÓM 1: Hồ sơ pháp lý

- [ ] Giấy phép kinh doanh - bản sao công chứng còn hiệu lực
- [ ] Giấy phép hành nghề / chứng chỉ đặc thù (nếu yêu cầu)
- [ ] Điều lệ công ty (nếu yêu cầu)
- [ ] Quyết định bổ nhiệm người đại diện pháp luật
- [ ] Giấy ủy quyền ký (nếu người ký không phải người đại diện pháp luật) - công chứng
- [ ] Tất cả trang có chữ ký: đúng người, đúng chức danh
- [ ] Tất cả trang có con dấu: đúng vị trí, dấu rõ ràng, không bị lệch
- [ ] Số bộ hồ sơ: đúng số lượng HSMT yêu cầu (vd: 1 gốc + 2 bản sao)

**Note:** Một số HSMT yêu cầu công chứng toàn bộ bộ pháp lý - đọc kỹ và không tự suy diễn.

---

#### NHÓM 2: Bảo lãnh dự thầu

- [ ] Số tiền bảo lãnh: đúng số, đúng đơn vị tiền tệ (VND hay USD?)
- [ ] Hình thức bảo lãnh: đúng theo yêu cầu HSMT (BL ngân hàng / tiền mặt)
- [ ] Ngân hàng phát hành: thuộc danh sách chấp nhận (nếu HSMT quy định)
- [ ] Thời hạn hiệu lực: phải đủ dài (≥ bid validity + buffer)
- [ ] Mẫu thư bảo lãnh: đúng theo mẫu HSMT (nếu HSMT có mẫu chuẩn)
- [ ] Người thụ hưởng: đúng tên, đúng địa chỉ Bên mời thầu
- [ ] Ngày phát hành: không được sau ngày nộp hồ sơ

**Warning:** Sai số tiền bảo lãnh dù chỉ 1 đồng → có thể bị loại trực tiếp.

---

#### NHÓM 3: Hồ sơ kỹ thuật

- [ ] Compliance Matrix: đầy đủ, có đánh dấu Comply / Deviate / Not Applicable
- [ ] Tất cả thông số kỹ thuật: đáp ứng hoặc vượt yêu cầu
- [ ] Deviation list: liệt kê rõ các điểm không comply (nếu có)
- [ ] Tài liệu catalog / datasheet: đúng model, đúng thông số
- [ ] Phương án kỹ thuật / methodology: đủ chi tiết theo yêu cầu
- [ ] Hợp đồng kinh nghiệm tương tự: đủ số lượng, kèm nghiệm thu (nếu yêu cầu)
- [ ] CV key personnel: đúng format, đủ thông tin, có chữ ký cam kết
- [ ] Chứng chỉ cá nhân (key personnel): bản sao rõ ràng

---

#### NHÓM 4: Hồ sơ tài chính

- [ ] Đơn giá dự thầu: điền đầy đủ, không bỏ trống dòng nào
- [ ] Tổng giá: đúng (cộng lại thủ công để kiểm tra)
- [ ] Đơn vị tiền tệ: đúng và nhất quán trong toàn bộ bảng giá
- [ ] Chữ ký và đóng dấu trên bảng giá
- [ ] Phụ lục giá (nếu có): đầy đủ, nhất quán với bảng giá chính
- [ ] Thuế: đã bao gồm hay chưa - phải khớp với yêu cầu HSMT
- [ ] Giá có điền bằng chữ (nếu yêu cầu): khớp với số

**Warning:** Sai số học trong bảng giá (vd: cộng sai) có thể bị coi là lỗi kỹ thuật. Luôn cộng lại bằng tay hoặc excel riêng trước khi nộp.

---

#### NHÓM 5: Nộp hồ sơ

- [ ] Địa điểm nộp: đúng theo HSMT (tên đơn vị, địa chỉ, tầng/phòng)
- [ ] Số bộ hồ sơ: đủ theo yêu cầu
- [ ] Cách đóng gói: đúng theo yêu cầu (niêm phong, dán nhãn)
- [ ] Nhãn bên ngoài: đúng tên gói thầu, đúng tên nhà thầu, đúng địa chỉ nhận
- [ ] Thời hạn nộp: biết rõ giờ chốt, không phải ngày chốt
- [ ] Biên nhận nộp hồ sơ: yêu cầu và giữ lại

**Note:** Nộp trễ 1 phút = bị loại. Không có ngoại lệ.

---

---

#### NHÓM 6: Version Control

🟠 HIGH RISK - Đây là nhóm check mà nhiều team bỏ qua và là nguồn gốc của nhiều lỗi thầm lặng nhất.

- [ ] File nộp là **phiên bản final** - không phải draft hoặc phiên bản cũ
- [ ] Không còn **Track Changes** hoặc comment trong file Word/Excel
- [ ] File pricing là **số final đã lock** - không phải bản đang chỉnh sửa
- [ ] Không còn placeholder text ("TBD", "insert here", "XX") trong bất kỳ file nào
- [ ] **Addendum mới nhất** đã được tích hợp vào hồ sơ - kiểm tra ngày phát hành
- [ ] Tên file: đúng phiên bản cuối (không phải "final_v2_thật_sự_cuối.pdf")
- [ ] File kỹ thuật và file tài chính **nhất quán với nhau** - không có số liệu mâu thuẫn

**Thực tế:** Lỗi version control thường xảy ra khi nhiều người cùng chỉnh sửa file. Assign 1 người duy nhất chịu trách nhiệm merge và lock file final.

### 5 thứ double-check trong 30 phút cuối

Trước khi đóng gói lần cuối, dừng lại 30 phút và check 5 điểm này:

1. **Chữ ký & con dấu** - Lướt qua từng trang, kiểm tra chỗ cần ký đã ký chưa
2. **Số tiền bảo lãnh** - Đọc lại thư bảo lãnh, đối chiếu với HSMT
3. **Tổng giá trong đơn dự thầu** - Cộng lại một lần nữa
4. **Số bộ hồ sơ** - Đếm lại đủ số bộ gốc + sao
5. **Giờ nộp & địa điểm** - Xác nhận lần cuối không có thay đổi trong Addendum

---

### Checklist riêng cho đấu thầu online (E-Procurement)

- [ ] Đăng nhập tài khoản trước deadline ít nhất 2–3 tiếng
- [ ] Upload từng file: kiểm tra đúng tên file, đúng mục
- [ ] Kích thước file: đúng giới hạn hệ thống (thường <10MB/file)
- [ ] Tên file: không có ký tự đặc biệt (dấu tiếng Việt, /, \, *, ?)
- [ ] Xem lại file đã upload: download lại để confirm mở được
- [ ] Hoàn thành nộp (submit): đừng chỉ upload mà quên bấm "Nộp hồ sơ"
- [ ] Lưu screenshot xác nhận nộp thành công
- [ ] In/lưu biên nhận điện tử (nếu hệ thống cấp)

---

## 4. Ví dụ thực tế

**Câu chuyện thật (ẩn danh):**

Một nhà thầu chuẩn bị hồ sơ 3 tuần cho gói thầu 15 tỷ. Hồ sơ kỹ thuật xuất sắc, giá cạnh tranh. Nhưng đến phần đánh giá sơ bộ, Ban mời thầu phát hiện:

- Giấy ủy quyền ký hồ sơ **không được công chứng**
- Thư bảo lãnh ghi sai **tên gói thầu**

Kết quả: loại ở vòng đầu tiên.

**Bài học:** 3 tuần làm việc, bị loại vì 2 lỗi có thể kiểm tra trong 10 phút.

---$sup_update_content_4$,
  null::jsonb
)
) as v(slug, content_mdx, quiz)
where l.slug = v.slug;
