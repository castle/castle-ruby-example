// Minimal UI behaviour that previously came from Bootstrap's JS bundle:
// the responsive navbar toggle and dismissible flash messages.
(function () {
  document.addEventListener("DOMContentLoaded", function () {
    var toggler = document.querySelector("[data-nav-toggle]");
    var menu = document.querySelector("[data-nav-menu]");
    if (toggler && menu) {
      toggler.addEventListener("click", function () {
        menu.classList.toggle("hidden");
      });
    }

    document.querySelectorAll("[data-dismiss-alert]").forEach(function (btn) {
      btn.addEventListener("click", function () {
        var alert = btn.closest(".alert");
        if (alert) alert.remove();
      });
    });
  });
})();
