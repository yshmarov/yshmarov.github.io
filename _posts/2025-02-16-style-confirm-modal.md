---
layout: post
title: "Style window.confirm() with Turbo"
tags: javascript turbo
---

In Rails we often use

```ruby
button_to "Delete", my_path, method: :delete, data: { turbo_confirm: "Are you sure?" }
```

That would open a [default browser confirm dialog](https://developer.mozilla.org/en-US/docs/Web/API/Window/confirm).

We can style it with TailwindCSS and a little JavaScript.

```diff
# app/javascript/application.js
import '@hotwired/turbo-rails'
import 'controllers'
+import 'confirm'
```

```ruby
# config/importmap.rb
pin "confirm", to: "confirm.js"
```

```js
// app/javascript/confirm.js
// Custom TailwindCSS modals for confirm dialogs
//
// Example usage:
//
//   <%= button_to "Delete", my_path, method: :delete, form: {
//     data: {
//       turbo_confirm: "Are you sure?",
//       turbo_confirm_description: "This will delete your record. Enter the record name to confirm.",
//       turbo_confirm_text: "record name"
//     }
//   } %>
function insertConfirmModal(message, element, button) {
  let confirmInput = "";

  // button is nil if using link_to with data-turbo-confirm
  let confirmText =
    button?.dataset?.turboConfirmText || element.dataset.turboConfirmText;
  let description =
    button?.dataset?.turboConfirmDescription ||
    element.dataset.turboConfirmDescription ||
    "";
  if (confirmText) {
    confirmInput = `<input type="text" class="mt-4 form-control" data-behavior="confirm-text" />`;
  }
  let id = `confirm-modal-${new Date().getTime()}`;

  let content = `
      <dialog id="${id}" class="modal rounded-lg max-w-md w-full backdrop:backdrop-blur-sm backdrop:bg-black/50">
        <form method="dialog">
          <div class="bg-white mx-auto rounded shadow p-6 max-w-md ">
            <h5 class="text-lg">${message}</h5>
            <p class="mt-2 text-sm text-gray-700 ">${description}</p>
  
            ${confirmInput}
  
            <div class="flex justify-end items-center flex-wrap gap-2 mt-4">
              <button value="cancel" class="btn btn-secondary">Cancel</button>
              <button value="confirm" class="btn btn-danger">Confirm</button>
            </div>
          </div>
        </form>
      </dialog>
    `;

  document.body.insertAdjacentHTML("beforeend", content);
  let modal = document.getElementById(id);

  // Focus on the first button in the modal after rendering
  modal.querySelector("button").focus();

  // Disable commit button until the value matches confirmText
  if (confirmText) {
    let commitButton = modal.querySelector("[value='confirm']");
    commitButton.disabled = true;
    modal
      .querySelector("input[data-behavior='confirm-text']")
      .addEventListener("input", (event) => {
        commitButton.disabled = event.target.value != confirmText;
      });
  }

  return modal;
}

// Replace deprecated Turbo.setConfirmMethod with new config approach
Turbo.config.forms.confirm = (message, element, button) => {
  let dialog = insertConfirmModal(message, element, button);
  dialog.showModal();

  return new Promise((resolve, reject) => {
    dialog.addEventListener(
      "close",
      () => {
        resolve(dialog.returnValue == "confirm");
      },
      { once: true }
    );
  });
};
```

Now your confirm dialogs will be sexy!

Inspired by [Rails Designer](https://dev.to/railsdesigner/custom-confirm-dialog-for-turbo-and-rails-3n96), Gorails' "Custom Turbo Confirm Modals with Hotwire in Rails" & others.
