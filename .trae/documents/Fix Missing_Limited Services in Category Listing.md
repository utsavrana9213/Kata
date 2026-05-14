## Findings
- Category listing uses a bundled CSV snapshot as the primary data source. In [category_services_page.dart:L50-L73](file:///Users/utsavrana/Downloads/untitled%20folder%202/the/servekeen/lib/category_services_page.dart#L50-L73) it loads services from [HierarchyRepository](file:///Users/utsavrana/Downloads/untitled%20folder%202/the/servekeen/lib/data/hierarchy_repository.dart#L29-L72), which is built from [services_rows.csv](file:///Users/utsavrana/Downloads/untitled%20folder%202/the/servekeen/services_rows.csv#L1).
- The app only calls the backend endpoint `get_services_by_category.php` when the CSV returns an empty list. So if the CSV contains *any* services for that category/subcategory, the UI never queries the database—leading to “missing newly uploaded services” and “only a limited number shown”.
- Separately, if the server endpoint applies a default LIMIT or filters subcategories incorrectly (comma-separated IDs vs equality), the UI currently has no pagination mechanism to retrieve the rest.

## Plan
### 1) Make Category Listing Remote-First
- Change [CategoryServicesPage._fetchServices](file:///Users/utsavrana/Downloads/untitled%20folder%202/the/servekeen/lib/category_services_page.dart#L50-L73) to always request `ApiService.fetchServicesByCategoryId(...)`.
- Use the CSV list only as an immediate placeholder (show cached results quickly), then replace/merge with the remote response.
- Add `mounted` checks around `setState` to prevent crashes during fast navigation.

### 2) Add Refresh + Better Loading UX
- Wrap the list in a `RefreshIndicator` so users can manually refresh.
- Keep a “loading” state while fetching remote data even if cached items exist.

### 3) Backend Endpoint Verification (to address true DB/result limits)
- Verify production `get_services_by_category.php` behavior:
  - Ensure no hidden `LIMIT`/pagination default.
  - Ensure category filter handles both `category_id` and `categorys` columns (your create script writes either/both depending on schema: [services_create.php:L130-L158](file:///Users/utsavrana/Downloads/untitled%20folder%202/the/servekeen/backend_scripts/services_create.php#L130-L158)).
  - Ensure subcategory filtering handles comma-separated stored values (use `FIND_IN_SET` if needed).
- If that endpoint isn’t available in this repo, add a correct `backend_scripts/get_services_by_category.php` implementation matching the app contract and ready to deploy.

### 4) Validate
- Run the Flutter app and verify:
  - A newly created service appears under its category/subcategory without reinstalling.
  - Category listing shows the full DB set (or paginates if backend requires it).
  - Switching subcategories updates results correctly.

## Expected Outcome
- Category/subcategory pages always reflect the database state instead of the CSV snapshot.
- The “only a limited number of services show” issue is removed unless the server endpoint itself is limiting results (covered by step 3).