interface ActionNextStepData {
  title?: string;
  items: string[];
}

interface CaseFailData {
  title: string;
  story: string;
  lesson: string;
}

interface ReadinessScoreData {
  scores: { label: string; score: number; note?: string }[];
  conclusion: string;
  priority?: string;
}

export interface LessonSupplement {
  actionNextStep?: ActionNextStepData;
  caseFail?: CaseFailData;
  readinessScore?: ReadinessScoreData;
}

const ACTION_NEXT_STEPS: Record<string, ActionNextStepData> = {
  "dau-thau-la-gi": {
    items: [
      "Vào muasamcong.mpi.gov.vn, tìm bất kỳ gói thầu nào đang mở.",
      "Download HSMT về.",
      "Mở ra và thử tìm 3 thứ: tên Chủ đầu tư, giá trị gói thầu, deadline nộp hồ sơ.",
    ],
  },
  "cau-truc-hsmt-doc-tu-dau": {
    items: [
      "Tìm phần BDS (Bid Data Sheet) và highlight deadline, bid validity, số tiền bảo lãnh.",
      "Tìm phần Qualification Criteria và đọc lướt xem yêu cầu năng lực gồm những gì.",
      "Tìm phần SCC (Special Conditions) và xem có bao nhiêu trang, có điều khoản nào về phạt không.",
    ],
  },
  "top-loi-bi-loai-chi-tu": {
    items: [
      "Check 10 lỗi chí tử trước khi đóng gói, không phải sau.",
      "Đảm bảo ai trong team cũng biết danh sách lỗi này.",
      'Assign 1 người chịu trách nhiệm check fatal errors, không để "ai cũng nghĩ người kia đã check".',
    ],
  },
  "bao-lanh-du-thau-khong-duoc-sai": {
    items: [
      "Gọi ngân hàng ngay hôm nay để hỏi timeline phát hành thư bảo lãnh.",
      "Lập danh sách ngân hàng công ty đang có quan hệ tín dụng.",
      "Với mỗi HSMT mới, check đủ 5 điểm: số tiền, hiệu lực, hình thức, ngân hàng, mẫu.",
    ],
  },
  "kinh-nghiem-tuong-tu-yeu-cau-kho-nhat": {
    items: [
      "Lập danh sách toàn bộ hợp đồng công ty đã thực hiện trong 5 năm qua.",
      "Với mỗi hợp đồng, ghi rõ tên dự án, giá trị, loại công việc, ngày hoàn thành, có biên bản nghiệm thu không.",
      "Highlight những hợp đồng chưa có biên bản nghiệm thu để xử lý trước gói thầu tiếp theo.",
    ],
  },
  "deadline-hieu-luc-ho-so": {
    items: [
      "Lấy HSMT gần nhất và đọc kỹ phần timeline trong BDS.",
      "Vẽ timeline: clarification deadline, submission deadline, bid validity end, bảo lãnh hết hạn.",
      "Tính ngược từ submission deadline để biết cần bắt đầu làm hồ sơ từ ngày nào.",
    ],
  },
  "quy-trinh-clarification": {
    items: [
      "Liệt kê tất cả điểm mơ hồ hoặc mâu thuẫn trong HSMT đang xem xét.",
      "Với mỗi điểm, quyết định có cần hỏi không hay có thể tự diễn giải an toàn.",
      "Nếu cần hỏi, draft câu hỏi và gửi ít nhất 5 ngày trước clarification deadline.",
    ],
  },
  "quick-scan-hsmt-5-phut": {
    items: [
      "Download template Quick Scan ở phần trên.",
      "Lấy 1 HSMT thật và thử điền template này.",
      "Ra quyết định GO / NO-GO dựa trên kết quả, không phải cảm tính.",
    ],
  },
  "gap-analysis-nang-luc": {
    items: [
      "Lấy gói thầu bạn đang xem xét và điền template GAP Analysis 4 nhóm.",
      "Với mỗi GAP, quyết định ngay: tự xử lý, subcontractor, JV, hay NO-GO.",
      "Share file GAP Analysis cho cả team để mọi người nhìn thấy rủi ro giống nhau.",
    ],
  },
  "checklist-truoc-khi-nop": {
    items: [
      "Print hoặc lưu checklist 5 nhóm để dùng ngay.",
      "Assign 1 người chịu trách nhiệm đi qua từng mục trước khi đóng gói.",
      "Với gói thầu tiếp theo, không đóng gói cho đến khi tất cả ô trong checklist đã được tick.",
    ],
  },
  "xu-ly-upload-loi-e-procurement": {
    items: [
      "Đăng nhập muasamcong.mpi.gov.vn và kiểm tra tài khoản còn hoạt động không.",
      "Đặt rule cứng cho team: không upload sau 17:00 ngày hôm trước deadline.",
      'Tạo thư mục "FINAL SUBMISSION" riêng cho mỗi gói thầu, chỉ chứa file đã sẵn sàng nộp.',
    ],
  },
  "compliance-matrix-ky-nang-core": {
    items: [
      "Lấy một HSMT bất kỳ và mở phần Technical Requirements.",
      "Liệt kê 10 yêu cầu đầu tiên vào template Compliance Matrix.",
      "Thử phân loại từng yêu cầu: Mandatory hay Preferred? Comply hay cần Deviate?",
    ],
  },
  "reading-scc-dieu-khoan-nguy-hiem": {
    items: [
      "Lấy HSMT đang xem xét và tìm phần SCC.",
      "Dùng 6 điều khoản nguy hiểm trong bài làm checklist để check từng cái.",
      "Với bất kỳ red flag nào, ghi chú ngay và quyết định có cần clarification không.",
    ],
  },
  "addendum-management-quan-ly-thay-doi": {
    items: [
      "Tạo Addendum Tracker cho gói thầu đang chuẩn bị.",
      "Thiết lập lịch nhắc kiểm tra hệ thống sáng và chiều mỗi ngày làm việc.",
      'Assign 1 người chịu trách nhiệm theo dõi Addendum, không để "ai cũng theo dõi".',
    ],
  },
};

const CASE_FAILS: Record<string, CaseFailData> = {
  "top-loi-bi-loai-chi-tu": {
    title: "Hồ sơ kỹ thuật tốt nhất - vẫn bị loại vòng đầu",
    story:
      "Một nhà thầu chuẩn bị hồ sơ kỹ thuật xuất sắc trong 3 tuần. Đến ngày mở thầu, Ban mời thầu phát hiện người ký Đơn dự thầu là Phó Giám đốc, nhưng Giấy ủy quyền ký đính kèm chưa được công chứng theo yêu cầu HSMT. Hồ sơ bị loại ở vòng kiểm tra sơ bộ.",
    lesson: "Fatal errors không quan tâm đến chất lượng kỹ thuật của bạn.",
  },
  "bao-lanh-du-thau-khong-duoc-sai": {
    title: "Sai tên - mất hết",
    story:
      'Nhà thầu chuẩn bị đủ hồ sơ kỹ thuật và tài chính. Thư bảo lãnh ngân hàng đúng số tiền, đúng thời hạn, nhưng phần "Beneficiary" ghi tên Ban Quản lý Dự án, trong khi HSMT yêu cầu ghi tên Chủ đầu tư. Hồ sơ bị loại ngay vòng kiểm tra bảo lãnh.',
    lesson:
      'Bảo lãnh không có khái niệm "gần đúng" - sai một chữ là sai hoàn toàn.',
  },
  "kinh-nghiem-tuong-tu-yeu-cau-kho-nhat": {
    title: "3 hợp đồng - nhưng chỉ tính được 1",
    story:
      "Nhà thầu có 3 hợp đồng tương tự trong 5 năm. Khi chấm: hợp đồng thứ nhất đủ tiêu chí, hợp đồng thứ hai là subcontract không được tính, hợp đồng thứ ba không có biên bản nghiệm thu. Chỉ còn 1 hợp đồng hợp lệ trên ngưỡng yêu cầu 3.",
    lesson:
      "Số lượng hợp đồng không quan trọng bằng số hợp đồng đủ tiêu chí đúng định nghĩa của HSMT đó.",
  },
  "deadline-hieu-luc-ho-so": {
    title: "Upload xong - nhưng trễ 7 phút",
    story:
      "Nhà thầu hoàn thành hồ sơ đúng hạn, bắt đầu upload lúc 8:30 với deadline 9:00. File cuối upload xong lúc 8:58, nhưng khi bấm Submit, hệ thống xử lý đến 9:07 mới confirm. Hồ sơ bị ghi nhận nộp lúc 9:07.",
    lesson:
      "Deadline không phải là lúc bạn bấm nút - là lúc hệ thống confirm. Upload trước ít nhất 2 tiếng.",
  },
  "quy-trinh-clarification": {
    title: "Addendum gửi lúc 5 giờ chiều - không ai đọc",
    story:
      "Chủ đầu tư phát hành Addendum sửa đổi yêu cầu kinh nghiệm vào 17:00 ngày thứ Sáu trước deadline thứ Hai. Nhà thầu không kiểm tra hệ thống cuối tuần, làm hồ sơ theo HSMT gốc và bị loại vì không đáp ứng yêu cầu mới.",
    lesson:
      "Addendum có thể đến bất cứ lúc nào. Kiểm tra hệ thống hàng ngày trong suốt thời gian chuẩn bị hồ sơ.",
  },
  "quick-scan-hsmt-5-phut": {
    title: "Upload xong - nhưng trễ 7 phút",
    story:
      "Nhà thầu hoàn thành hồ sơ đúng hạn, bắt đầu upload lúc 8:30 với deadline 9:00. File cuối upload xong lúc 8:58, nhưng khi bấm Submit, hệ thống xử lý đến 9:07 mới confirm. Hồ sơ bị ghi nhận nộp lúc 9:07.",
    lesson:
      "Timeline risk phải được phát hiện ngay từ Quick Scan, không đợi đến ngày nộp mới xử lý.",
  },
  "gap-analysis-nang-luc": {
    title: "3 hợp đồng - nhưng chỉ tính được 1",
    story:
      "Nhà thầu tưởng mình có 3 hợp đồng tương tự, nhưng khi đối chiếu theo HSMT chỉ có 1 hợp đồng đủ điều kiện. Một hợp đồng là subcontract, một hợp đồng thiếu nghiệm thu.",
    lesson:
      "GAP Analysis phải kiểm tra bằng chứng hợp lệ, không chỉ đếm số lượng tài liệu đang có.",
  },
  "compliance-matrix-ky-nang-core": {
    title: "Comply với tất cả - và bị loại",
    story:
      'Nhà thầu điền "Comply" cho toàn bộ 45 yêu cầu kỹ thuật, nhưng cột tài liệu chứng minh để trống hoặc chỉ ghi chung "xem hồ sơ kỹ thuật". Ban mời thầu không thể verify và coi như không có bằng chứng.',
    lesson:
      '"Comply" mà không có tài liệu chứng minh = lời nói suông trong đấu thầu.',
  },
  "reading-scc-dieu-khoan-nguy-hiem": {
    title: "Thắng thầu - thua hợp đồng",
    story:
      "Nhà thầu thắng gói 30 tỷ, triển khai chậm 3 tháng. SCC quy định LD 0.1%/ngày và không có cap. Tổng LD 2.7 tỷ đồng, gần bằng lợi nhuận toàn dự án.",
    lesson:
      "SCC nguy hiểm nhất không phải là SCC bạn đọc - mà là SCC bạn không đọc.",
  },
  "addendum-management-quan-ly-thay-doi": {
    title: "Addendum phát hành thứ Sáu - nộp hồ sơ thứ Hai",
    story:
      "Chủ đầu tư phát hành Addendum 02 lúc 17:30 thứ Sáu, thay đổi mẫu Bid Form. Deadline là sáng thứ Hai. Nhà thầu không kiểm tra cuối tuần và nộp hồ sơ với form cũ.",
    lesson:
      "Addendum phát hành cuối tuần không phải tai nạn - đó là thực tế. Phải có người kiểm tra hệ thống khi gần deadline.",
  },
};

const READINESS_SCORES: Record<string, ReadinessScoreData> = {
  "gap-analysis-nang-luc": {
    scores: [
      { label: "Tài chính", score: 80, note: "GAP thấp" },
      { label: "Kỹ thuật", score: 60, note: "GAP trung bình" },
      { label: "Nhân sự", score: 50, note: "GAP trung bình" },
      { label: "Pháp lý", score: 100, note: "Không có GAP" },
    ],
    conclusion: "CONDITIONAL GO",
    priority: "Nhân sự (50) - ưu tiên xử lý trước",
  },
};

export function getLessonSupplement(slug: string): LessonSupplement {
  return {
    actionNextStep: ACTION_NEXT_STEPS[slug],
    caseFail: CASE_FAILS[slug],
    readinessScore: READINESS_SCORES[slug],
  };
}
