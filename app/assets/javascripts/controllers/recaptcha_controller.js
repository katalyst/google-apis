import { Controller } from "@hotwired/stimulus";

const config = (window["___grecaptcha_cfg"] ||= {});
config["fns"] ||= [];

const recaptcha = (window["grecaptcha"] ||= {});
const enterprise = (recaptcha["enterprise"] ||= {});

enterprise.ready = (f) => {
  (config["fns"] ||= []).push(f);
};

/**
 * Inject recaptcha enterprise script into the head, unless it is already there.
 */
function injectRecaptchaScripts() {
  if (document.head.querySelector("script[src*='recaptcha/enterprise']")) {
    return;
  }

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
  static values = {
    siteKey: String,
    action: String,
    response: String,
    widgetId: String,
  };

  connect() {
    injectRecaptchaScripts();

    enterprise.ready(this.attachRecaptcha);
  }

  disconnect() {
    enterprise.ready(this.detachRecaptcha);
  }

  /**
   * Prevent turbo morph events from updating the dom inside this element.
   * Instead, remove the temporary container and re-initialize recaptcha.
   *
   * Recaptcha does not allow the same response to be validated twice so we
   * always need to ask the user to re-complete the recaptcha.
   *
   * @param e {Event}
   */
  morph(e) {
    e.preventDefault();

    enterprise.ready(() => {
      this.detachRecaptcha();
      this.responseValue = "";
      this.attachRecaptcha();
    });
  }

  /**
   * Respond to an update to the recaptcha challenge.
   *
   * @param response {String}
   */
  responseValueChanged(response) {
    this.responseTarget.value = response;
  }

  /**
   * Renders the recaptcha widget inside the temporary container.
   */
  attachRecaptcha = () => {
    this.widgetIdValue = enterprise.render(this.containerTarget, {
      sitekey: this.siteKeyValue,
      action: this.actionValue,
      callback: this.recaptchaResponse,
    });
  };

  /**
   * Detach the input from recaptcha.js and remove the temporary container.
   */
  detachRecaptcha = () => {
    enterprise.reset(this.widgetIdValue);
    this.widgetIdValue = "";
    this.containerTarget.remove();
  };

  /**
   * Handles callbacks from recaptcha when the user has completed the challenge.
   */
  recaptchaResponse = (response) => {
    this.responseValue = response;
  };

  /**
   * @returns {HTMLDivElement} creates or returns a temporary div for holding the recaptcha inputs
   */
  get containerTarget() {
    let container = this.element.firstElementChild;
    if (container) return container;

    container = document.createElement("div");
    container.dataset.turboTemporary = "";
    this.element.appendChild(container);
    return container;
  }

  /**
   * @returns {HTMLInputElement} the hidden input that will submit the recaptcha response
   */
  get responseTarget() {
    return this.element.nextElementSibling;
  }
}
