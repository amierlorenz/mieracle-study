# Canvas modules and files API

Research for #71 (map #70, feeds #78 "Pick step: files to exams"). Researched 2026-10-02 against the Canvas LMS REST API docs and the `instructure/canvas-lms` source on `master`. No calls were made to a real Canvas instance, so anything marked **verify** depends on how the school's Canvas is configured.

Sources:
- [Modules API](https://canvas.instructure.com/doc/api/modules.html), [Files API](https://canvas.instructure.com/doc/api/files.html), [Pagination](https://canvas.instructure.com/doc/api/file.pagination.html), [Throttling](https://canvas.instructure.com/doc/api/file.throttling.html)
- canvas-lms source: [`lib/api/v1/context_module.rb`](https://github.com/instructure/canvas-lms/blob/master/lib/api/v1/context_module.rb), [`app/controllers/context_modules_api_controller.rb`](https://github.com/instructure/canvas-lms/blob/master/app/controllers/context_modules_api_controller.rb), [`app/controllers/files_controller.rb`](https://github.com/instructure/canvas-lms/blob/master/app/controllers/files_controller.rb), [`lib/api/v1/attachment.rb`](https://github.com/instructure/canvas-lms/blob/master/lib/api/v1/attachment.rb), [`app/models/attachment.rb`](https://github.com/instructure/canvas-lms/blob/master/app/models/attachment.rb), [`app/models/folder.rb`](https://github.com/instructure/canvas-lms/blob/master/app/models/folder.rb), [`lib/api/v1/assignment.rb`](https://github.com/instructure/canvas-lms/blob/master/lib/api/v1/assignment.rb), [`lib/api.rb`](https://github.com/instructure/canvas-lms/blob/master/lib/api.rb), [`lib/authentication_methods.rb`](https://github.com/instructure/canvas-lms/blob/master/lib/authentication_methods.rb), [`app/helpers/attachment_helper.rb`](https://github.com/instructure/canvas-lms/blob/master/app/helpers/attachment_helper.rb)
- [Google Drive `files.export`](https://developers.google.com/workspace/drive/api/reference/rest/v3/files/export), [Google export formats](https://developers.google.com/workspace/drive/api/guides/ref-export-formats), [Microsoft Graph: convert to other formats](https://learn.microsoft.com/en-us/graph/api/driveitem-get-content-format)

## Answer in brief

1. One call per course, `GET /api/v1/courses/:id/modules?include[]=items&include[]=content_details&per_page=100`, returns the module tree in order. Modules come back sorted by `position`, and each item has `position` and `indent`. Canvas leaves `items` out of any module with **more than 100 items**. When that happens, page through `items_url` instead.
2. Module item `type` is one of `File`, `Page`, `Discussion`, `Assignment`, `Quiz`, `SubHeader`, `ExternalUrl`, `ExternalTool`. Canvas has **no exam type**. A classic quiz shows up as `Quiz`, with `content_id` holding the quiz id. A New Quiz shows up as `Assignment`, with `content_id` holding the assignment id. You can only tell a New Quiz from a plain assignment through the Assignments API (`is_quiz_lti_assignment: true`).
3. For files, use the module item's `content_id` (the attachment id) with `GET /api/v1/courses/:cid/files/:id`. This works even when the **Files tab is hidden**. Listing `GET /courses/:id/files` checks the folder's `:read_contents` permission, and that permission is denied to students when the tab is hidden. In that case the list call returns **403** "user not authorized to perform that action". Getting a single file only needs `:read` on the attachment, which does not look at the tab.
4. For a locked file (`locked_for_user: true`), the File JSON has an empty-string `url`. For an unlocked file, `url` is `https://<canvas>/files/:id/download?download_frd=1[&verifier=<uuid>]`. That URL redirects through the files domain or inst-fs to storage.
5. Use `updated_at`, `modified_at` and `size` to detect changes, and track each file by its **module item id**. When an instructor overwrites a file, Canvas creates a **new attachment id** and repoints the module item's `content_id` to it. Canvas does not expose a content hash or a stable ETag through the API.
6. External slide links (Google Slides, OneDrive/SharePoint, Box) all need the provider's own OAuth before they can be fetched as PDF. A Canvas token cannot fetch them. There is no primary data on how common they are.
7. `CanvasClient.getAll` already handles pagination correctly. It does not handle throttling (`429`), or `403` as a separate case.

## 1. Modules and items, in order

**Endpoints**
- `GET /api/v1/courses/:course_id/modules`: takes `include[]=items`, `include[]=content_details` (which needs `items`), `search_term` and `student_id`. The result is scoped with `modules_visible_to(user)`, so a student never sees unpublished modules.
- `GET /api/v1/courses/:course_id/modules/:module_id/items`: takes `include[]=content_details`, `search_term` and `student_id`.
- Items are inlined only when `count <= Api::MAX_PER_PAGE` (100) (`context_module.rb`: `if includes.include?("items") && count <= Api::MAX_PER_PAGE`). In every case the module carries `items_count` and `items_url`, so the client can tell when items were left out.

**Module fields that matter for Pick**: `id`, `name`, `position` (1-based course order), `unlock_at`, `prerequisite_module_ids`, `require_sequential_progress`, `items_count`, `items_url`, `items`, and `state` (the student's progression: `locked`, `unlocked`, `started` or `completed`, depending on progression).

**ModuleItem fields**: `id` (the module item id, which stays the same when the file changes), `module_id`, `position`, `title`, `indent` (0-based nesting, used for visual hierarchy under SubHeaders), `type`, `content_id` (left out for Page, SubHeader and ExternalUrl), `html_url`, `url` (the API URL; for File it is `/api/v1/courses/:cid/files/:id`), `page_url` (Page only), `external_url` (ExternalUrl and ExternalTool), `new_tab`, `completion_requirement`, and `published` (only shown to callers who can see unpublished content).

**`content_details`** (from `content_details` in `context_module.rb`) copies these from the target object when present: `usage_rights`, `locked`, `hidden`, `lock_explanation`, `display_name`, `due_at`, `unlock_at`, `lock_at` and `points_possible`. It also adds `thumbnail_url` for files and the standard lock JSON (`locked_for_user`, `lock_info`, `lock_explanation`). For assignment and quiz items, the `due_at` here comes from `overridden_for(current_user)`, so it is the **student's own due date**. That is useful for spotting exams.

**Type mapping** (`Api::API_DATA_TYPE`): Attachment→`File`, WikiPage→`Page`, DiscussionTopic→`Discussion`, Assignment→`Assignment`, Quizzes::Quiz→`Quiz`, ContextModuleSubHeader→`SubHeader`, ExternalUrl→`ExternalUrl`, ContextExternalTool→`ExternalTool`.

### How exams appear

- Canvas has no exam concept. An exam is whatever the instructor made it: a classic `Quiz` item, an `Assignment` item (which includes New Quizzes and paper exams entered as zero-submission assignments), an `ExternalTool` (a proctoring LTI), a calendar event outside modules, or only a `SubHeader` such as "Exam 1 review".
- To link a module item to the app's existing `Exam` and `CanvasItem` records (which use the key `assignment_<id>`):
  - A `type == "Assignment"` item maps directly: `content_id` is the assignment id.
  - A `type == "Quiz"` item has a quiz id in `content_id`. The Assignments API returns `quiz_id` on quiz assignments (`assignment.rb` line ~311), so the mapping is quiz_id → assignment, taken from the `assignments(courseID:)` fetch the app already makes. `CanvasAssignment` would just need to decode `quiz_id`.
  - New Quizzes: in the Assignments API, `is_quiz_lti_assignment: true` (and `is_quiz_assignment` for classic quizzes). The community has reported a `quiz_lti` field on module items, but it is **not in current module item serialization** on `master`, so don't rely on it.
- Practical heuristic for #78: decide which assignments are exams from data the app already has (the user's `Exam` records, each linked to a `CanvasItem`). Find each exam's module item by content id, then give each File the first exam that comes after it in (module position, item position) order. Fall back to the exam due date when exams sit outside modules.

## 2. Getting the files

**Metadata**: `GET /api/v1/courses/:course_id/files/:id` (or `/api/v1/files/:id`). The File object has `id`, `uuid` (being removed behind the `deprecate_uuid_in_files_api` flag), `folder_id`, `display_name`, `filename`, `content-type`, `url`, `size` (bytes), `created_at`, `updated_at`, `modified_at` (falls back to `updated_at`), `unlock_at`, `lock_at`, `locked`, `hidden`, `hidden_for_user`, `locked_for_user`, `lock_info`, `lock_explanation`, `mime_class`, `thumbnail_url`, `preview_url` (only with `include[]=preview_url`), and `upload_status`.

**Files tab hidden** (`folder.rb` policy):
```ruby
given do |user, session|
  visible? && !locked? && context.grants_right?(user, session, :read_files) &&
    !(context.is_a?(Course) && context.tab_hidden?(Course::TAB_FILES))
end
can :read_contents
```
`api_index` (list files) calls `authorized_action(@folder, @current_user, :read_contents)`. So for a student in a course with the Files tab hidden, the list call fails. `api_show` checks `:read` on the attachment instead (granted by `user_can_read_through_context?`), so the per-file call works. **Plan: always discover files through modules, never through the course file list.** That costs one GET per file, which is fine sequentially.

**Status codes** (`authentication_methods.rb#render_json_unauthorized`): a valid token without permission gets **403** `{"status":"unauthorized","errors":[{"message":"user not authorized to perform that action"}]}`. A missing, invalid, expired or revoked token gets **401** with a `WWW-Authenticate` header ("Invalid access token.", "Expired access token.", and so on). `CanvasClient` mapping 401 to `.unauthorized` (bad token) is therefore correct. A 403 means "this item or list is off-limits", not "re-enter token".

**Locked files**: in `attachment_json`, `downloadable = !attachment.locked_for?(user, check_policies: true)`. When the file is not downloadable, `url` and `thumbnail_url` are `""`. Files inside a module that is still locked (by `unlock_at` or prerequisites) show `locked_for_user: true` and a `lock_explanation`, and Pick should list them as "not available yet".

**Downloading**:
- `url` = `file_download_url(..., download: 1, download_frd: 1, verifier: uuid)`. The `uuid` verifier is added unless the root account turned on `disable_adding_uuid_verifier_in_api`. When present, the verifier alone authorizes the download.
- `FilesController#token_auth_allowed?` returns true for `show` and `api_show`. Bearer tokens on the non-API download route are honoured only when the site-admin flag `enable_file_access_with_api_tokens` is on (`authentication_methods.rb` line ~145). **Verify** on the user's instance: send `Authorization: Bearer` and also keep the verifier URL as is.
- The response is a 302, either to the "safer" files domain (`safe_domain_file_url`) or, for inst-fs-hosted files, to a short-lived signed inst-fs URL (`authenticated_download_url`). Follow redirects, and **do not forward the Canvas `Authorization` header to another host**. Strip it in `urlSession(_:task:willPerformHTTPRedirection:newRequest:)` when the host changes. This keeps the token from leaking to a storage host, and avoids signed-URL hosts rejecting a request that carries two kinds of auth.
- Side effect: `send_stored_file` calls `attachment.context_module_action(user, :read)`. **Downloading a file marks the "view" module requirement as completed for the user.** That is harmless and may even be wanted, but the user should know.

## 3. Content types and sizes

- `mime_class` groups types: `pdf` (application/pdf), `ppt` (`.ppt`, `.pptx`, and Keynote, whose MIME type Canvas misspells as `applicatoin/vnd.apple.key`), `doc`, `xls`, `image`, `zip`, `audio`, `video`, `text`, `code` and `html`. Use `mime_class` to decide whether a file is eligible for intake (pdf and ppt are the main ones, doc is secondary).
- `size` is given in bytes before download, so Pick can show sizes and estimate cost or token use without fetching anything. No primary source gives typical sizes. The map's estimate (~0.5–2 GB per semester) should be checked by summing `size` across one real course.
- Canvas cannot convert PPTX to PDF through the API. `preview_url` and Canvadocs are an HTML viewer, not a PDF download. PPTX → PDF has to happen on the Mac. That decision belongs to the Extract tickets.

## 4. Change detection

- When a file is replaced with the same name ("overwrite" duplicate handling in `Attachment#handle_duplicates`), Canvas creates a **new attachment**. The old one gets `replacement_attachment_id`, and module items are repointed: `ContentTag.where(content_id: old, content_type: "Attachment").update_all(content_id: new.id, ...)`, after which the modules are touched.
- So the stable key is the **module item `id`**. A change shows up as a new `content_id`, or the same id with a later `updated_at`/`modified_at`, or a different `size`.
- Canvas stores `md5` (actually SHA-512 for newer files) but **never serializes it** in the File API. Any ETag from the storage redirect target depends on the storage backend and is undocumented, so don't use it. Hash the downloaded bytes locally if a content-level comparison is needed.
- A file removed from a module just disappears from the items list. A file that is unpublished or hidden disappears for students in the same way.

## 5. External slide links

- `ExternalUrl` items carry `external_url`. Google Drive and OneDrive integrations installed as LTI tools show up as `ExternalTool`.
- **Google Slides**: the Drive API `files.export` (`GET /drive/v3/files/{id}/export?mimeType=application/pdf`) supports PDF and PPTX. It requires an OAuth scope (`drive.readonly` or `drive.file`) and caps exports at **10 MB**. The unauthenticated `docs.google.com/presentation/d/<id>/export/pdf` link only works for "anyone with the link" decks and is not a documented API. Treat it as best-effort.
- **OneDrive/SharePoint**: Graph `GET /drive/items/{id}/content?format=pdf` converts `ppt`/`pptx` (among others) and returns a 302 to a pre-authenticated URL. It needs delegated `Files.Read`. There is no anonymous path.
- **Box**: the API needs Box OAuth even for shared links.
- How common these links are: **no primary data**. The cheap way to find out is to count `ExternalUrl`/`ExternalTool` items by host across the user's real courses once the module fetch exists. Until then, treat external links as "show in Pick as not importable; the user can download the file and drop it in".

## 6. Pagination and rate limits

- Pagination: `Link` header with `current`, `next`, `prev`, `first` and `last` (`last` may be missing). URLs are opaque. The default is 10 per page, and `per_page` is clamped to 1…100 (`Api::MAX_PER_PAGE = 100`). The docs warn that the header *name* is case-insensitive. `HTTPURLResponse.value(forHTTPHeaderField:)` is already case-insensitive, so `CanvasClient.getAll` is fine.
- Throttling: each request costs quota (shown in `X-Request-Cost`), and `X-Rate-Limit-Remaining` appears while throttling is active. When throttled, the server sends **`429`** (the docs say "429 Forbidden (Rate Limit Exceeded)"; older Canvas versions sent 403 with that text). Parallel requests pay a pre-flight penalty. The docs say "any API client that makes no more than one simultaneous request is unlikely to be throttled", and each token has its own quota.
- Implications for `CanvasClient`: run the module walk and per-file metadata fetches **sequentially**. `CanvasSync` currently uses `async let` for two calls per course, which is fine. Add a small retry with backoff on 429 (and on 403 whose body says "Rate Limit Exceeded"). Don't fan out per-file GETs with a task group.

## 7. Fit with existing code

- `CanvasClient.getAll(_:query:)` (adds `per_page=100`, follows `rel="next"`) can be reused as is for `modules` and `items`. Note that `include[]` has to be repeated as separate `URLQueryItem`s.
- New pieces needed: `modules(courseID:)`, `moduleItems(courseID:moduleID:)` (fallback when `items` is missing), `file(courseID:id:)`, a download method with redirect handling, a `ClientError.forbidden` (403) case and a `.throttled` (429) case, and `quiz_id`/`is_quiz_lti_assignment` added to `CanvasAssignment`.
- Pages that link files in their body (instructors often do this) do not produce File module items. Page text is out of scope per #70, but those files would be missed. **Verify** how often this happens in the user's courses.
