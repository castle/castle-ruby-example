// Castle browser SDK glue.
//
// The SDK itself (and `Castle.configure`) is loaded in the layout, only when a
// publishable key is configured. Here we make sure that any form opting in with
// `data-castle="true"` carries a fresh request token in a hidden
// `castle_request_token` field, which the backend forwards to the risk/filter
// endpoints.
(function () {
  function setToken(form, token) {
    var field = form.querySelector('input[name="castle_request_token"]');
    if (!field) {
      field = document.createElement("input");
      field.type = "hidden";
      field.name = "castle_request_token";
      form.appendChild(field);
    }
    field.value = token || "";
  }

  function attach(form) {
    var submitted = false;

    form.addEventListener("submit", function (event) {
      var sdkReady = window.Castle && typeof Castle.createRequestToken === "function";
      if (submitted || !sdkReady) {
        return; // already handled, or no SDK configured — submit as-is
      }

      event.preventDefault();

      Castle.createRequestToken()
        .then(function (token) {
          setToken(form, token);
        })
        .catch(function (err) {
          console.error("Castle.createRequestToken failed", err);
          setToken(form, "");
        })
        .then(function () {
          submitted = true;
          if (typeof form.requestSubmit === "function") {
            form.requestSubmit();
          } else {
            form.submit();
          }
        });
    });
  }

  document.addEventListener("DOMContentLoaded", function () {
    var forms = document.querySelectorAll('form[data-castle="true"]');
    Array.prototype.forEach.call(forms, attach);
  });
})();
