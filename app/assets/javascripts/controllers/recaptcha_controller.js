import { Controller } from "@hotwired/stimulus";

const config = (window["___grecaptcha_cfg"] ||= {});
config["fns"] ||= [];

const recaptcha = (window["grecaptcha"] ||= {});
const enterprise = (recaptcha["enterprise"] ||= {});

enterprise.ready = (f) => {
  (config["fns"] ||= []).push(f);
};

function init() {
  if (document.head.querySelector("script[src*='recaptcha/enterprise']"))
    return;

  const script = document.createElement("script");
  script.setAttribute(
    "src",
    "https://www.google.com/recaptcha/enterprise.js?render=explicit",
  );
  script.toggleAttribute("async", true);
  script.toggleAttribute("defer", true);

  document.head.appendChild(script);
}

export default class RecaptchaController extends Controller {
  connect() {
    init();

    enterprise.ready(() => {
      enterprise.render(this.element, {
        sitekey: this.element.dataset.sitekey,
        action: this.element.dataset.action,
        callback: (response) => {
          this.responseTarget.value = response;
        },
      });
    });
  }

  get responseTarget() {
    return this.element.nextElementSibling;
  }
}
