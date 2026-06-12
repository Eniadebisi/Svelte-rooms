<script>
  // Stores
  import { page } from "$app/stores";
</script>

<div class="m-0 vh-100 p-0 d-flex flex-column align-items-center justify-content-center">
  <h1>{$page?.error?.message}</h1>
  <br />
  <a href="/">Go Back Home</a>
</div>
