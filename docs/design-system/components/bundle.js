/* @ds-bundle: {"format":4,"namespace":"Nichiji","components":[{"name":"Button"}]} */
(function () {
  var VARIANTS = { primary: "nj-btn--primary", secondary: "nj-btn--secondary", quiet: "nj-btn--quiet", done: "nj-btn--done" };

  function Button(props) {
    props = props || {};
    var el = document.createElement("button");
    el.type = "button";
    el.className = "nj-btn " + (VARIANTS[props.variant] || VARIANTS.primary) + (props.block ? " nj-btn--block" : "");
    el.textContent = props.label || "";
    if (typeof props.onClick === "function") el.addEventListener("click", props.onClick);
    return el;
  }

  window.Nichiji = { Button: Button, variants: Object.keys(VARIANTS) };
})();
