# Tối ưu hóa đơn Gemini API: Hướng dẫn toàn diện về Context Caching

Tại sao hệ thống RAG (Retrieval-Augmented Generation) của chúng ta lại "đốt" ngân sách API như thể không có ngày mai ?
Và rồi tôi phát hiện ra tính năng **Context Caching** của Gemini - một yếu tố thay đổi cuộc chơi thực sự cho bất kỳ ai làm việc với ngữ cảnh lớn.

Hãy để tôi chỉ cho bạn tính năng này là gì, tại sao nó quan trọng, và cách triển khai nó trong các dự án của bạn.

## Vấn đề: Ngữ cảnh lặp đi lặp lại = Lãng phí Token

Nếu bạn đã từng xây dựng các ứng dụng LLM, có lẽ bạn đã gặp phải tình huống này: Bạn có một tài liệu lớn, một cơ sở tri thức, hoặc một chỉ dẫn hệ thống (system prompt) cần được đính kèm với mọi truy vấn của người dùng.

Cách tiếp cận truyền thống sẽ như sau:

1.  Người dùng đặt câu hỏi.
2.  Code của bạn kết hợp **toàn bộ ngữ cảnh** + câu hỏi của họ.
3.  Gửi tất cả đến LLM.
4.  Lặp lại cho từng câu hỏi.

Điều này có nghĩa là bạn đang gửi đi gửi lại cùng một lượng token. Đối với các ngữ cảnh lớn, điều này sẽ nhanh chóng làm tăng chi phí về:

*   **Chi phí API** (trả tiền cho cùng một lượng token nhiều lần).
*   **Độ trễ** (truyền tải lượng dữ liệu lớn).
*   **Thời gian xử lý** (model phải xử lý tất cả token trong mỗi yêu cầu).

## Giải pháp: Context Caching

Tính năng Context Caching của Gemini cho phép bạn tải nội dung lên một lần, lưu trữ nó trên máy chủ (server-side), và tham chiếu đến nó trong các yêu cầu tiếp theo. Hãy coi nó như việc tạo ra một cơ sở tri thức tạm thời mà model có thể truy cập mà không cần bạn phải gửi lại.

```python
import os
from google import genai
from google.genai import types

# Cấu hình client
client = genai.Client(api_key=os.environ.get("GOOGLE_API_KEY"))

# Cơ sở tri thức lớn hoặc chỉ dẫn hệ thống
knowledge_base = """
[Nội dung tài liệu, chỉ dẫn, hoặc ngữ cảnh lớn của bạn ở đây - phải có ít nhất 32,768 token]
"""

# Tạo một bộ đệm (lưu ý: hậu tố phiên bản của model là bắt buộc)
cache = client.caches.create(
    model="models/gemini-1.5-pro-001",  # Phải bao gồm hậu tố phiên bản
    config=types.CreateCachedContentConfig(
        display_name="my_knowledge_base",
        system_instruction="Bạn là một trợ lý hữu ích, trả lời các câu hỏi dựa trên cơ sở tri thức được cung cấp.",
        contents=[knowledge_base],
        ttl="3600s",  # Thời gian tồn tại của bộ đệm là 1 giờ
    )
)

# Bây giờ bạn có thể truy vấn chỉ bằng câu hỏi của người dùng
response = client.models.generate_content(
    model="models/gemini-1.5-pro-001", 
    contents="Ai là người sáng lập công ty?",
    config=types.GenerateContentConfig(cached_content=cache.name)
)

print(response.text)
print(response.usage_metadata)
```

## Khi nào Context Caching phát huy hiệu quả nhất?

Từ kinh nghiệm xây dựng các hệ thống thực tế của tôi, Context Caching hoạt động tốt nhất cho các trường hợp sau:

1.  **Hệ thống Hỏi-Đáp trên tài liệu:** Nếu bạn đang xây dựng một hệ thống để trả lời câu hỏi về các tài liệu lớn (hợp đồng pháp lý, hướng dẫn kỹ thuật, bài báo nghiên cứu), caching là giải pháp hoàn hảo. Lưu tài liệu vào bộ đệm một lần, sau đó để người dùng đặt nhiều câu hỏi mà không cần gửi lại nó.

2.  **Hệ thống RAG phức tạp:** Khi triển khai RAG với các cơ sở tri thức rộng lớn, bạn có thể lưu vào bộ đệm các phần thường xuyên được truy cập hoặc toàn bộ bộ sưu tập tài liệu.

3.  **Phân tích Video/Audio:** Nếu bạn đang phân tích các tệp media dài, việc caching giúp ngăn chặn việc gửi đi gửi lại tệp khổng lồ đó với mỗi truy vấn phân tích.

4.  **Chỉ dẫn hệ thống nhất quán:** Đối với các ứng dụng sử dụng các chỉ dẫn hệ thống phức tạp hoặc các ví dụ few-shot, việc caching các chỉ dẫn này sẽ tiết kiệm token trên mọi yêu cầu.

## Ví dụ triển khai trong thực tế

Đây là một ví dụ thực tế từ một hệ thống hỗ trợ khách hàng mà tôi đã xây dựng gần đây:

```python
import os
import time
from google import genai
from google.genai import types

class CachedKnowledgeBase:
    def __init__(self, api_key, model="models/gemini-1.5-flash-001", cache_hours=24):
        self.client = genai.Client(api_key=api_key)
        self.model = model
        self.cache = None
        self.ttl_seconds = int(cache_hours * 3600)
        self.cache_created = False

    def load_knowledge_base(self, kb_file_path, system_instruction=None):
        """Tải và lưu cơ sở tri thức từ một tệp vào bộ đệm"""
        # Đọc tệp cơ sở tri thức
        with open(kb_file_path, 'r') as file:
            kb_content = file.read()

        # Đặt chỉ dẫn hệ thống mặc định nếu không được cung cấp
        if not system_instruction:
            system_instruction = """
            Bạn là một chuyên viên hỗ trợ khách hàng. Chỉ trả lời câu hỏi của khách hàng 
            dựa trên thông tin trong cơ sở tri thức. 
            Nếu bạn không biết câu trả lời, hãy nói rõ thay vì bịa ra.
            Luôn lịch sự, súc tích và hữu ích.
            """

        # Tạo bộ đệm
        try:
            self.cache = self.client.caches.create(
                model=self.model,
                config=types.CreateCachedContentConfig(
                    display_name=f"support_kb_{os.path.basename(kb_file_path)}",
                    system_instruction=system_instruction,
                    contents=[kb_content],
                    ttl=f"{self.ttl_seconds}s",
                )
            )
            self.cache_created = True
            print(f"Cơ sở tri thức đã được lưu vào bộ đệm thành công! (ID: {self.cache.name})")
            print(f"Bộ đệm sẽ hết hạn sau {self.ttl_seconds/3600} giờ")
            return True
        except Exception as e:
            print(f"Không thể lưu cơ sở tri thức vào bộ đệm: {e}")
            return False

    def answer_question(self, question, temperature=0.2):
        """Trả lời câu hỏi của khách hàng bằng cơ sở tri thức đã được cache"""
        if not self.cache_created:
            raise Exception("Cơ sở tri thức chưa được cache. Hãy gọi load_knowledge_base trước.")

        try:
            start_time = time.time()
            response = self.client.models.generate_content(
                model=self.model,
                contents=question,
                config=types.GenerateContentConfig(
                    cached_content=self.cache.name,
                    temperature=temperature
                )
            )
            end_time = time.time()

            # Trích xuất thông tin sử dụng token
            usage = response.usage_metadata

            # Trả về phản hồi và siêu dữ liệu
            return {
                "answer": response.text,
                "response_time": round(end_time - start_time, 2),
                "cached_tokens": usage.cached_content_token_count,
                "prompt_tokens": usage.prompt_token_count,
                "response_tokens": usage.candidates_token_count,
                "total_tokens": usage.total_token_count
            }
        except Exception as e:
            return {"error": str(e)}

    def extend_cache(self, additional_hours=24):
        """Gia hạn thời gian tồn tại của bộ đệm"""
        if not self.cache_created:
            return False

        new_ttl = int(additional_hours * 3600)
        try:
            self.client.caches.update(
                name=self.cache.name,
                config=types.UpdateCachedContentConfig(
                    ttl=f"{new_ttl}s"
                )
            )
            self.ttl_seconds = new_ttl
            print(f"Bộ đệm đã được gia hạn thêm {additional_hours} giờ")
            return True
        except Exception as e:
            print(f"Không thể gia hạn bộ đệm: {e}")
            return False

    def cleanup(self):
        """Xóa bộ đệm khi không còn cần thiết"""
        if self.cache_created:
            try:
                self.client.caches.delete(self.cache.name)
                print("Đã xóa bộ đệm thành công")
                self.cache_created = False
                return True
            except Exception as e:
                print(f"Không thể xóa bộ đệm: {e}")
                return False

# Ví dụ sử dụng
if __name__ == "__main__":
    support_bot = CachedKnowledgeBase(
        api_key=os.environ.get("GOOGLE_API_KEY"),
        model="models/gemini-1.5-flash-001",
        cache_hours=48
    )

    # Tải cơ sở tri thức
    support_bot.load_knowledge_base(
        "product_documentation.txt",
        system_instruction="""
        Bạn là trợ lý hỗ trợ kỹ thuật cho sản phẩm đám mây của chúng tôi.
        Trả lời câu hỏi của khách hàng một cách chính xác dựa trên tài liệu.
        Bao gồm các bước cụ thể khi mô tả cách giải quyết các vấn đề kỹ thuật.
        Nếu thông tin không có trong tài liệu, hãy hướng dẫn khách hàng liên hệ
        với bộ phận hỗ trợ trực tiếp thay vì đoán mò.
        """
    )

    # Ví dụ câu hỏi của khách hàng
    questions = [
        "Làm thế nào để đặt lại mật khẩu của tôi?",
        "Sự khác biệt giữa gói Basic và Pro là gì?",
        "Tôi có thể tích hợp với Salesforce không?",
        "Yêu cầu hệ thống là gì?",
        "Làm thế nào để thiết lập xác thực hai yếu tố?"
    ]

    # Xử lý tất cả các câu hỏi và theo dõi tổng lượng token sử dụng
    total_cached_tokens = 0
    total_prompt_tokens = 0
    total_response_tokens = 0

    for i, question in enumerate(questions):
        print(f"\nCâu hỏi {i+1}: {question}")
        result = support_bot.answer_question(question)

        if "error" in result:
            print(f"Lỗi: {result['error']}")
            continue

        print(f"Câu trả lời: {result['answer'][:150]}...")
        print(f"Thời gian phản hồi: {result['response_time']}s")
        print(f"Tokens: {result['prompt_tokens']} prompt + {result['cached_tokens']} cached + {result['response_tokens']} response")

        total_cached_tokens = result['cached_tokens']  # Giống nhau cho mọi truy vấn
        total_prompt_tokens += result['prompt_tokens']
        total_response_tokens += result['response_tokens']

    # Ước tính chi phí
    # Đây là mức giá ví dụ - hãy điều chỉnh dựa trên giá hiện tại
    cached_storage_cost = (total_cached_tokens / 1_000_000) * 48 * 1  # 1$ mỗi triệu token mỗi giờ
    standard_approach_cost = ((total_cached_tokens * len(questions)) / 1_000) * 0.0005
    cached_approach_cost = ((total_prompt_tokens + total_response_tokens) / 1_000) * 0.0005 + cached_storage_cost

    print("\n--- Phân tích chi phí ---")
    print(f"Cách tiếp cận thông thường (gửi lại ngữ cảnh): ${standard_approach_cost:.2f}")
    print(f"Sử dụng context caching: ${cached_approach_cost:.2f}")
    print(f"Tiết kiệm: ${standard_approach_cost - cached_approach_cost:.2f} ({(1 - cached_approach_cost/standard_approach_cost) * 100:.1f}%)")

    # Dọn dẹp khi hoàn tất
    support_bot.cleanup()
```

## Vấn đề chi phí: Khi nào thì đáng để sử dụng?

Context Caching không miễn phí - bạn phải trả tiền cho thời gian lưu trữ. Đây là cách phân tích chi phí:

*   **Chi phí lưu trữ:** $1 mỗi triệu token mỗi giờ.
*   **Chi phí xử lý:** Bạn vẫn phải trả tiền cho việc xử lý các token đã được cache, nhưng với mức giá giảm.

Hãy xem một ví dụ thực tế từ một dự án tôi đã làm tháng trước:

*   **Cơ sở tri thức:** 50,000 token
*   **Thời gian cache:** 24 giờ
*   **Người dùng trung bình:** 15 truy vấn mỗi ngày
*   **Truy vấn trung bình:** 25 token
*   **Phản hồi trung bình:** 200 token

**Không có caching:**

*   **Tổng token được xử lý:** 50,025 token × 15 truy vấn = 750,375 token mỗi ngày
*   **Chi phí với giá $0.0005 cho 1K token:** $0.38 mỗi ngày cho mỗi người dùng

**Có caching:**

*   **Chi phí lưu trữ:** (50,000 token ÷ 1,000,000) × 24 giờ × $1 = $1.20 cho 24 giờ
*   **Chi phí xử lý:** (25 + 200) token × 15 truy vấn × $0.0005 cho 1K token = $0.0017
*   **Tổng chi phí:** $1.20 + $0.0017 = $1.21 mỗi ngày

Trong kịch bản này, việc dùng cache **không hợp lý về mặt tài chính**. Nhưng khi phục vụ hơn 100 người dùng với cùng một cơ sở tri thức, bài toán kinh tế thay đổi hoàn toàn:

*   **Không có caching (100 người dùng):** $0.38 × 100 = **$38 mỗi ngày**
*   **Có caching (100 người dùng):** $1.20 + ($0.0017 × 100) = **$1.37 mỗi ngày**

Đó là **mức giảm chi phí đến 96%**!

## Mẹo triển khai từ thực chiến

Sau khi triển khai tính năng này trong nhiều dự án, đây là những mẹo tôi đã rút ra:

*   **Yêu cầu về phiên bản:** Luôn bao gồm hậu tố phiên bản (ví dụ: `-001`) khi chỉ định model.
*   **Yêu cầu token tối thiểu:** Ngữ cảnh phải có ít nhất **32,768 token**. Đây là một hạn chế hiện tại mà hy vọng Google sẽ giảm trong tương lai.
*   **Quản lý bộ đệm:** Triển khai quản lý vòng đời của bộ đệm.
*   **Lựa chọn Model:** Cả Gemini 1.5 Pro và Flash đều hỗ trợ context caching. Theo thử nghiệm của tôi, Flash hoạt động tốt cho hầu hết các trường hợp sử dụng và có chi phí thấp hơn.
*   **Kỳ vọng về độ trễ:** Hiện tại, context caching chủ yếu giúp giảm chi phí thay vì độ trễ. Đừng mong đợi sự cải thiện đáng kể về hiệu suất (ít nhất là bây giờ).

## Khi nào KHÔNG nên sử dụng Context Caching

Sau khi lãng phí một số chi phí API không cần thiết, tôi đã học được khi nào context caching không đáng giá:

*   **Ngữ cảnh nhỏ:** Nếu ngữ cảnh của bạn dưới 32,768 token, bạn không thể sử dụng caching (hạn chế hiện tại).
*   **Trường hợp sử dụng một truy vấn:** Nếu người dùng thường chỉ hỏi một câu về một tài liệu, chi phí lưu trữ sẽ lớn hơn lợi ích.
*   **Dữ liệu thay đổi nhanh:** Nếu dữ liệu tham chiếu của bạn thay đổi thường xuyên, việc caching sẽ trở nên kém hiệu quả.
*   **Lượng truy vấn rất thấp:** Đối với các ứng dụng có ít người dùng hoặc các truy vấn không thường xuyên, các phương pháp tiêu chuẩn có thể hiệu quả hơn về chi phí.

## Tương lai của Context Caching

Tôi rất lạc quan về hướng đi của tính năng này. Khi các ứng dụng LLM trưởng thành hơn, các tính năng như context caching sẽ trở thành hạ tầng thiết yếu. Tôi kỳ vọng các cải tiến trong tương lai sẽ bao gồm:

*   Hỗ trợ kích thước ngữ cảnh nhỏ hơn.
*   Cải thiện độ trễ.
*   Kiểm soát caching chi tiết hơn.
*   Khả năng caching liên tục vượt qua giới hạn TTL hiện tại.

## Kết luận

Context caching là một trong những tính năng có vẻ nhỏ nhưng có thể tác động mạnh mẽ đến kinh tế và kiến trúc ứng dụng của bạn. Đối với các ứng dụng đa người dùng xử lý ngữ cảnh lớn, đây là một yếu tố thay đổi cuộc chơi tiềm năng có thể cắt giảm chi phí hơn 90% trong các kịch bản phù hợp.

Bạn đã triển khai context caching trong các ứng dụng Gemini của mình chưa? Tôi rất muốn nghe về kinh nghiệm của bạn và bất kỳ cách sử dụng sáng tạo nào bạn đã tìm thấy cho tính năng này. Hãy để lại bình luận bên dưới nhé