const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname, "..");
const assetRoot = path.join(root, "TripPet", "Resources", "Assets.xcassets");
const sourceRoot = path.join(root, "TripPet", "Resources", "ArtSource");

const groups = {
  Animals: [
    "animal_cat_home",
    "animal_visitor_unknown",
    "animal_cat_selfie",
    "trip_marker_cat",
    "animal_dog_home",
    "animal_dog_visitor",
    "animal_rabbit_home",
    "animal_rabbit_visitor",
  ],
  Cabin: [
    "cabin_room_base",
    "prop_map_table",
    "prop_ticket_single",
    "prop_paper_plane",
    "ticket_flight_trail",
  ],
  Destinations: [
    "destination_paris_line",
    "destination_iceland_line",
    "trip_route_map_paris",
    "trip_route_map_iceland",
  ],
  Postcards: ["postcard_template_classic", "ticket_confirm_card"],
  Stamps: ["stamp_paris", "stamp_iceland"],
  Envelopes: ["mailbox_tray_base", "envelope_unread", "envelope_read", "envelope_old"],
  Onboarding: ["onboarding_cabin_path", "onboarding_cat_suitcase", "health_steps_ticket"],
  Settings: ["settings_notification_note", "settings_collection_empty", "settings_about_cabin"],
  UI: [
    "icon_home",
    "icon_mail",
    "icon_settings",
    "icon_back",
    "icon_health",
    "icon_ticket",
    "icon_steps",
    "icon_notification",
    "icon_collection",
    "icon_about",
  ],
  Textures: ["texture_paper_grain"],
};

const colors = {
  paper: "#FFF9EF",
  ivory: "#F7EEDC",
  sage: "#8FAF95",
  deepSage: "#5F7F66",
  mist: "#A9C9D8",
  peach: "#E9B9A4",
  ochre: "#D8B36A",
  ink: "#3D4338",
  pencil: "#74766F",
  gray: "#DED6C7",
  warn: "#C98976",
};

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function writeJSON(file, data) {
  fs.writeFileSync(file, `${JSON.stringify(data, null, 2)}\n`);
}

function groupContents() {
  return { info: { author: "xcode", version: 1 } };
}

function imageContents(filename, options = {}) {
  const contents = {
    images: [{ filename, idiom: "universal" }],
    info: { author: "xcode", version: 1 },
  };
  if (options.vector || options.template) {
    contents.properties = {
      "preserves-vector-representation": true,
    };
  }
  if (options.template) {
    contents.properties["template-rendering-intent"] = "template";
  }
  return contents;
}

function wobblePath(points, close = true) {
  const [first, ...rest] = points;
  const body = rest.map(([x, y]) => `L ${x} ${y}`).join(" ");
  return `M ${first[0]} ${first[1]} ${body}${close ? " Z" : ""}`;
}

function svgWrap(name, width, height, body, defs = "", attrs = "") {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" role="img" aria-label="${name}" ${attrs}>
  <defs>
    <filter id="paperNoise" x="-10%" y="-10%" width="120%" height="120%">
      <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="3" seed="17" result="noise"/>
      <feColorMatrix in="noise" type="saturate" values="0"/>
      <feComponentTransfer>
        <feFuncA type="table" tableValues="0 0.08"/>
      </feComponentTransfer>
    </filter>
    <filter id="softBleed" x="-12%" y="-12%" width="124%" height="124%">
      <feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="2" seed="9" result="texture"/>
      <feDisplacementMap in="SourceGraphic" in2="texture" scale="3.2"/>
    </filter>
    <filter id="pencilRough" x="-8%" y="-8%" width="116%" height="116%">
      <feTurbulence type="fractalNoise" baseFrequency="0.08" numOctaves="2" seed="5" result="rough"/>
      <feDisplacementMap in="SourceGraphic" in2="rough" scale="1.1"/>
    </filter>
    ${defs}
  </defs>
  ${body}
</svg>
`;
}

function paperRect(x, y, w, h, r = 20, fill = colors.ivory, stroke = colors.pencil) {
  return `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}" fill="${fill}" stroke="${stroke}" stroke-width="3" opacity="0.96" filter="url(#softBleed)"/>`;
}

function line(points, stroke = colors.ink, width = 4, extra = "") {
  return `<path d="${wobblePath(points, false)}" fill="none" stroke="${stroke}" stroke-width="${width}" stroke-linecap="round" stroke-linejoin="round" filter="url(#pencilRough)" ${extra}/>`;
}

function blob(cx, cy, rx, ry, fill, opacity = 0.55) {
  return `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${fill}" opacity="${opacity}" filter="url(#softBleed)"/>`;
}

function cabinRoomBase() {
  const body = `
    <rect width="720" height="720" fill="${colors.paper}"/>
    <rect width="720" height="720" fill="${colors.ochre}" opacity="0.08" filter="url(#paperNoise)"/>
    ${blob(360, 215, 310, 175, colors.mist, 0.22)}
    <path d="M68 622 C175 588 548 592 655 624 L655 692 L68 692 Z" fill="${colors.ivory}" opacity="0.92"/>
    <path d="M72 622 C202 585 510 589 650 621" fill="none" stroke="${colors.gray}" stroke-width="4" stroke-linecap="round"/>
    <rect x="248" y="104" width="224" height="188" rx="28" fill="#DDEDF2" opacity="0.92" stroke="${colors.pencil}" stroke-width="5" filter="url(#pencilRough)"/>
    <path d="M360 107 L360 292 M250 198 L472 198" stroke="${colors.pencil}" stroke-width="4" stroke-linecap="round" opacity="0.85"/>
    <path d="M294 155 C320 132 349 135 373 160 C396 135 428 133 450 157" fill="none" stroke="${colors.paper}" stroke-width="8" stroke-linecap="round" opacity="0.9"/>
    <path d="M128 558 C130 444 172 350 246 289 C304 240 418 240 476 290 C550 353 591 444 593 558 Z" fill="${colors.ivory}" opacity="0.74" stroke="${colors.pencil}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M118 559 L603 559" stroke="${colors.pencil}" stroke-width="5" stroke-linecap="round" opacity="0.8"/>
    <path d="M156 470 C242 439 480 438 565 470" fill="none" stroke="${colors.sage}" stroke-width="11" stroke-linecap="round" opacity="0.35"/>
    <path d="M95 332 C142 282 192 258 257 238" fill="none" stroke="${colors.peach}" stroke-width="12" stroke-linecap="round" opacity="0.22"/>
    <path d="M618 339 C566 284 525 263 462 239" fill="none" stroke="${colors.ochre}" stroke-width="12" stroke-linecap="round" opacity="0.18"/>
    <circle cx="548" cy="175" r="23" fill="${colors.ochre}" opacity="0.34" filter="url(#softBleed)"/>
    <path d="M120 656 C252 633 465 634 610 657" fill="none" stroke="${colors.gray}" stroke-width="3" stroke-linecap="round" opacity="0.55"/>
  `;
  return svgWrap("cabin_room_base", 720, 720, body);
}

function catHome() {
  const body = `
    ${blob(178, 260, 118, 112, colors.peach, 0.18)}
    <path d="M122 148 L151 82 L189 145 Z" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" stroke-linejoin="round" filter="url(#pencilRough)"/>
    <path d="M233 145 L270 82 L298 150 Z" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" stroke-linejoin="round" filter="url(#pencilRough)"/>
    <ellipse cx="210" cy="182" rx="105" ry="92" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <ellipse cx="210" cy="285" rx="93" ry="105" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M140 270 C90 300 79 351 118 376 C150 396 181 365 165 338" fill="none" stroke="${colors.ink}" stroke-width="12" stroke-linecap="round" opacity="0.82" filter="url(#pencilRough)"/>
    <circle cx="174" cy="172" r="6" fill="${colors.ink}"/>
    <circle cx="241" cy="172" r="6" fill="${colors.ink}"/>
    <path d="M205 190 C207 198 214 198 217 190" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-linecap="round"/>
    <path d="M184 211 C198 224 223 224 237 211" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-linecap="round"/>
    <path d="M149 196 C112 188 93 187 62 190 M151 213 C114 219 96 226 70 239 M267 196 C302 188 326 187 354 190 M265 213 C301 220 325 229 348 242" stroke="${colors.pencil}" stroke-width="3" stroke-linecap="round"/>
    <path d="M169 362 C182 376 200 380 214 367 M225 367 C242 380 260 375 272 360" fill="none" stroke="${colors.ink}" stroke-width="5" stroke-linecap="round"/>
    <path d="M156 136 C179 127 238 127 263 137" fill="none" stroke="${colors.sage}" stroke-width="10" stroke-linecap="round" opacity="0.26"/>
  `;
  return svgWrap("animal_cat_home", 420, 420, body, "", 'fill="none"');
}

function visitorUnknown() {
  const body = `
    ${blob(185, 235, 120, 112, colors.mist, 0.25)}
    <path d="M106 344 C111 254 147 189 203 170 C254 188 292 256 298 344 Z" fill="${colors.sage}" opacity="0.36" stroke="${colors.pencil}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M143 174 L169 111 L199 169 M216 168 L248 111 L271 177" fill="${colors.sage}" opacity="0.28" stroke="${colors.pencil}" stroke-width="5" stroke-linejoin="round" filter="url(#pencilRough)"/>
    <path d="M188 235 C188 211 202 198 222 198 C244 198 258 211 258 230 C258 250 239 259 221 271 C211 278 207 288 207 301" fill="none" stroke="${colors.ink}" stroke-width="13" stroke-linecap="round" stroke-linejoin="round" opacity="0.72" filter="url(#pencilRough)"/>
    <circle cx="207" cy="332" r="8" fill="${colors.ink}" opacity="0.72"/>
    <path d="M82 346 C134 366 267 364 326 346" fill="none" stroke="${colors.gray}" stroke-width="4" stroke-linecap="round" opacity="0.65"/>
  `;
  return svgWrap("animal_visitor_unknown", 380, 420, body);
}

function mapTable() {
  const body = `
    <ellipse cx="320" cy="303" rx="240" ry="38" fill="${colors.pencil}" opacity="0.12"/>
    <path d="M140 234 C198 201 421 199 498 232 C472 276 181 284 140 234 Z" fill="${colors.ochre}" opacity="0.34" stroke="${colors.pencil}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M181 236 L146 352 M458 238 L500 352" stroke="${colors.pencil}" stroke-width="8" stroke-linecap="round" opacity="0.55"/>
    ${paperRect(132, 80, 370, 190, 18, colors.paper, colors.pencil)}
    <path d="M252 84 L238 268 M374 84 L389 267" stroke="${colors.gray}" stroke-width="3" stroke-linecap="round" opacity="0.75"/>
    <path d="M167 187 C216 145 259 151 297 179 C340 213 389 196 456 139" fill="none" stroke="${colors.mist}" stroke-width="12" stroke-linecap="round" opacity="0.58" filter="url(#softBleed)"/>
    <path d="M174 220 C228 211 266 224 304 240 C347 258 396 247 462 220" fill="none" stroke="${colors.sage}" stroke-width="9" stroke-linecap="round" opacity="0.38"/>
    <path d="M207 132 C225 115 243 113 262 130 C283 148 305 147 330 128" fill="none" stroke="${colors.ochre}" stroke-width="6" stroke-linecap="round" opacity="0.62"/>
    <circle cx="408" cy="172" r="12" fill="${colors.peach}" opacity="0.76" filter="url(#softBleed)"/>
    <path d="M408 184 L408 208" stroke="${colors.ink}" stroke-width="4" stroke-linecap="round" opacity="0.65"/>
  `;
  return svgWrap("prop_map_table", 640, 420, body);
}

function ticketSingle() {
  const body = `
    <rect width="520" height="250" fill="none"/>
    <path d="${wobblePath([[46,64],[474,53],[462,190],[57,203]])}" fill="${colors.ochre}" opacity="0.46" filter="url(#softBleed)"/>
    <path d="${wobblePath([[47,62],[475,54],[461,191],[56,203]])}" fill="none" stroke="${colors.pencil}" stroke-width="5" filter="url(#pencilRough)"/>
    <path d="M164 62 C143 85 145 171 171 198" fill="none" stroke="${colors.pencil}" stroke-width="4" stroke-dasharray="12 12" opacity="0.65"/>
    <path d="M208 104 C270 86 348 90 412 115" fill="none" stroke="${colors.sage}" stroke-width="8" stroke-linecap="round" opacity="0.48"/>
    <path d="M214 151 L397 146" stroke="${colors.ink}" stroke-width="5" stroke-linecap="round" opacity="0.55"/>
    <circle cx="98" cy="132" r="31" fill="${colors.paper}" opacity="0.72" stroke="${colors.pencil}" stroke-width="4"/>
    <path d="M82 133 C97 116 113 116 126 132 C114 148 96 150 82 133 Z" fill="none" stroke="${colors.sage}" stroke-width="5" stroke-linejoin="round"/>
  `;
  return svgWrap("prop_ticket_single", 520, 250, body);
}

function onboardingCabinPath() {
  const body = `
    <rect width="900" height="620" fill="${colors.paper}"/>
    <rect width="900" height="620" fill="${colors.ochre}" opacity="0.08" filter="url(#paperNoise)"/>
    ${blob(448, 176, 360, 150, colors.mist, 0.22)}
    <path d="M70 456 C190 391 292 402 402 453 C531 513 674 481 831 408 L831 620 L70 620 Z" fill="${colors.sage}" opacity="0.22" filter="url(#softBleed)"/>
    <path d="M386 614 C377 517 405 441 476 376 C520 336 566 308 600 265" fill="none" stroke="${colors.ochre}" stroke-width="46" stroke-linecap="round" opacity="0.32" filter="url(#softBleed)"/>
    <path d="M389 614 C380 518 407 444 476 377 C520 335 566 309 600 265" fill="none" stroke="${colors.paper}" stroke-width="26" stroke-linecap="round" opacity="0.72"/>
    <path d="M166 352 L290 250 L414 352 Z" fill="${colors.peach}" opacity="0.34" stroke="${colors.ink}" stroke-width="5" stroke-linejoin="round" filter="url(#pencilRough)"/>
    <path d="M190 346 L391 346 L378 489 L205 489 Z" fill="${colors.ivory}" stroke="${colors.pencil}" stroke-width="5" filter="url(#softBleed)"/>
    <rect x="255" y="394" width="58" height="95" rx="18" fill="${colors.sage}" opacity="0.42" stroke="${colors.ink}" stroke-width="4"/>
    <rect x="326" y="381" width="42" height="42" rx="10" fill="${colors.mist}" opacity="0.62" stroke="${colors.pencil}" stroke-width="3"/>
    <path d="M143 494 C239 522 352 522 434 493" fill="none" stroke="${colors.gray}" stroke-width="5" stroke-linecap="round" opacity="0.46"/>
    <path d="M627 235 C674 206 735 211 775 244 C813 218 854 227 879 259" fill="none" stroke="${colors.paper}" stroke-width="9" stroke-linecap="round" opacity="0.92"/>
    <circle cx="735" cy="139" r="34" fill="${colors.ochre}" opacity="0.3" filter="url(#softBleed)"/>
    <path d="M99 397 C137 365 176 359 216 378" fill="none" stroke="${colors.sage}" stroke-width="12" stroke-linecap="round" opacity="0.33"/>
  `;
  return svgWrap("onboarding_cabin_path", 900, 620, body);
}

function onboardingCatSuitcase() {
  const body = `
    <rect width="520" height="520" fill="none"/>
    ${blob(257, 404, 156, 34, colors.gray, 0.17)}
    <path d="M151 166 L179 96 L215 165 M273 165 L309 96 L335 168" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="6" stroke-linejoin="round" filter="url(#pencilRough)"/>
    <ellipse cx="244" cy="207" rx="110" ry="93" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="6" filter="url(#softBleed)"/>
    <ellipse cx="245" cy="327" rx="95" ry="104" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="6" filter="url(#softBleed)"/>
    <circle cx="206" cy="203" r="7" fill="${colors.ink}"/>
    <circle cx="284" cy="203" r="7" fill="${colors.ink}"/>
    <path d="M239 224 C243 231 251 231 255 224 M220 244 C237 259 266 259 282 244" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-linecap="round"/>
    <path d="M165 292 C113 303 98 347 130 372" fill="none" stroke="${colors.ink}" stroke-width="12" stroke-linecap="round" opacity="0.75"/>
    <path d="M327 289 C365 300 382 328 379 361" fill="none" stroke="${colors.ink}" stroke-width="12" stroke-linecap="round" opacity="0.75"/>
    <rect x="320" y="318" width="116" height="94" rx="18" fill="${colors.ochre}" opacity="0.45" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M354 318 C356 292 401 292 404 318" fill="none" stroke="${colors.ink}" stroke-width="5" stroke-linecap="round"/>
    <path d="M345 352 L414 352 M347 382 L410 382" stroke="${colors.pencil}" stroke-width="4" stroke-linecap="round" opacity="0.58"/>
    <path d="M175 407 C189 423 212 427 227 410 M255 410 C274 427 299 424 314 406" fill="none" stroke="${colors.ink}" stroke-width="5" stroke-linecap="round"/>
    <path d="M166 151 C202 134 286 136 325 153" fill="none" stroke="${colors.sage}" stroke-width="11" stroke-linecap="round" opacity="0.24"/>
  `;
  return svgWrap("onboarding_cat_suitcase", 520, 520, body);
}

function healthStepsTicket() {
  const body = `
    <rect width="720" height="480" fill="none"/>
    ${blob(360, 238, 260, 138, colors.mist, 0.18)}
    <path d="M128 258 C184 196 252 192 316 236 C383 281 452 267 541 175" fill="none" stroke="${colors.sage}" stroke-width="16" stroke-linecap="round" opacity="0.36" filter="url(#softBleed)"/>
    <path d="M128 258 C184 196 252 192 316 236 C383 281 452 267 541 175" fill="none" stroke="${colors.ink}" stroke-width="5" stroke-linecap="round" stroke-dasharray="12 16" opacity="0.55" filter="url(#pencilRough)"/>
    <path d="M126 194 C85 154 99 92 154 92 C182 92 204 108 218 132 C233 108 255 92 283 92 C338 92 352 154 311 194 L218 286 Z" fill="${colors.peach}" opacity="0.42" stroke="${colors.ink}" stroke-width="5" stroke-linejoin="round" filter="url(#softBleed)"/>
    <path d="M141 206 L177 206 L194 171 L227 252 L247 212 L286 212" fill="none" stroke="${colors.paper}" stroke-width="9" stroke-linecap="round" stroke-linejoin="round" opacity="0.9"/>
    <path d="${wobblePath([[376,196],[628,176],[612,319],[392,338]])}" fill="${colors.ochre}" opacity="0.46" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M463 190 C444 214 448 304 472 328" fill="none" stroke="${colors.pencil}" stroke-width="4" stroke-dasharray="10 10" opacity="0.7"/>
    <path d="M500 230 L578 224 M502 273 L561 268" stroke="${colors.ink}" stroke-width="5" stroke-linecap="round" opacity="0.58"/>
    <circle cx="417" cy="267" r="26" fill="${colors.paper}" opacity="0.76" stroke="${colors.pencil}" stroke-width="4"/>
    <path d="M403 267 C416 252 430 252 443 267 C430 283 416 283 403 267 Z" fill="none" stroke="${colors.sage}" stroke-width="5" stroke-linejoin="round"/>
    <path d="M118 354 C217 385 462 385 603 352" fill="none" stroke="${colors.gray}" stroke-width="6" stroke-linecap="round" opacity="0.35"/>
  `;
  return svgWrap("health_steps_ticket", 720, 480, body);
}

function ticketConfirmCard() {
  const body = `
    <rect width="760" height="500" fill="none"/>
    <path d="${wobblePath([[76,82],[684,62],[706,405],[93,428]])}" fill="${colors.ivory}" stroke="${colors.pencil}" stroke-width="6" filter="url(#softBleed)"/>
    <path d="${wobblePath([[118,132],[637,112],[653,348],[132,369]])}" fill="${colors.ochre}" opacity="0.28" stroke="${colors.pencil}" stroke-width="4" filter="url(#pencilRough)"/>
    <path d="M259 123 C230 166 235 319 271 360" fill="none" stroke="${colors.pencil}" stroke-width="5" stroke-dasharray="14 13" opacity="0.58"/>
    <circle cx="177" cy="241" r="54" fill="${colors.paper}" opacity="0.75" stroke="${colors.pencil}" stroke-width="5"/>
    <path d="M151 242 C176 214 204 214 228 241 C204 271 176 271 151 242 Z" fill="none" stroke="${colors.sage}" stroke-width="8" stroke-linejoin="round"/>
    <path d="M321 178 C396 154 511 160 588 194" fill="none" stroke="${colors.sage}" stroke-width="12" stroke-linecap="round" opacity="0.36"/>
    <path d="M323 242 L606 232 M326 292 L548 284" stroke="${colors.ink}" stroke-width="7" stroke-linecap="round" opacity="0.34"/>
    <rect x="574" y="113" width="54" height="48" rx="10" fill="${colors.peach}" opacity="0.46" stroke="${colors.pencil}" stroke-width="3"/>
    <path d="M107 438 C239 464 525 461 682 430" fill="none" stroke="${colors.gray}" stroke-width="5" stroke-linecap="round" opacity="0.32"/>
  `;
  return svgWrap("ticket_confirm_card", 760, 500, body);
}

function ticketFlightTrail() {
  const body = `
    <rect width="520" height="220" fill="none"/>
    <path d="M42 157 C116 91 190 180 259 111 C318 52 387 76 470 32" fill="none" stroke="${colors.mist}" stroke-width="12" stroke-linecap="round" opacity="0.32" filter="url(#softBleed)"/>
    <path d="M42 157 C116 91 190 180 259 111 C318 52 387 76 470 32" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-dasharray="9 14" stroke-linecap="round" opacity="0.42" filter="url(#pencilRough)"/>
    <circle cx="96" cy="93" r="8" fill="${colors.ochre}" opacity="0.42"/>
    <circle cx="198" cy="173" r="6" fill="${colors.peach}" opacity="0.42"/>
    <circle cx="354" cy="70" r="7" fill="${colors.sage}" opacity="0.42"/>
    <path d="${wobblePath([[408,63],[493,28],[463,99],[445,72]])}" fill="${colors.paper}" stroke="${colors.ink}" stroke-width="4" stroke-linejoin="round" filter="url(#softBleed)"/>
    <path d="M445 72 L493 28 L456 82" fill="none" stroke="${colors.pencil}" stroke-width="3" stroke-linecap="round"/>
  `;
  return svgWrap("ticket_flight_trail", 520, 220, body);
}

function mailboxTray() {
  const body = `
    ${blob(320, 306, 230, 44, colors.gray, 0.2)}
    <path d="M92 193 C150 151 499 151 552 193 L509 330 C423 361 222 360 132 330 Z" fill="${colors.ivory}" stroke="${colors.pencil}" stroke-width="6" filter="url(#softBleed)"/>
    <path d="M108 199 C199 244 445 244 536 199" fill="none" stroke="${colors.pencil}" stroke-width="5" stroke-linecap="round" opacity="0.72"/>
    <path d="M158 147 C235 121 389 122 470 147 L437 226 C360 250 266 249 197 226 Z" fill="${colors.paper}" stroke="${colors.gray}" stroke-width="4" opacity="0.92" filter="url(#softBleed)"/>
    <path d="M184 163 C240 202 384 203 444 163" fill="none" stroke="${colors.peach}" stroke-width="6" opacity="0.35"/>
    <path d="M260 103 C314 83 379 84 429 107" fill="none" stroke="${colors.sage}" stroke-width="10" stroke-linecap="round" opacity="0.3"/>
  `;
  return svgWrap("mailbox_tray_base", 640, 420, body);
}

function envelope(name, fill, accent, old = false) {
  const stain = old ? `${blob(465, 102, 44, 27, colors.ochre, 0.18)}${blob(132, 179, 35, 24, colors.peach, 0.13)}` : "";
  const body = `
    ${blob(320, 190, 260, 50, colors.gray, 0.14)}
    <path d="${wobblePath([[45,53],[595,47],[578,207],[62,214]])}" fill="${fill}" stroke="${colors.pencil}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M59 66 C174 135 241 174 320 177 C398 177 472 131 583 61" fill="none" stroke="${colors.pencil}" stroke-width="4" stroke-linecap="round" opacity="0.65"/>
    <path d="M64 212 C171 128 244 102 320 177 C396 100 472 124 578 207" fill="none" stroke="${colors.pencil}" stroke-width="4" stroke-linecap="round" opacity="0.52"/>
    <rect x="474" y="74" width="54" height="45" rx="8" fill="${accent}" opacity="0.58" stroke="${colors.pencil}" stroke-width="3" filter="url(#pencilRough)"/>
    <circle cx="141" cy="105" r="31" fill="none" stroke="${accent}" stroke-width="5" opacity="0.58" filter="url(#pencilRough)"/>
    <path d="M112 105 L170 105 M141 76 L141 134" stroke="${accent}" stroke-width="3" opacity="0.48" stroke-linecap="round"/>
    ${stain}
  `;
  return svgWrap(name, 640, 260, body);
}

function postcardTemplate() {
  const body = `
    <rect width="900" height="620" fill="none"/>
    <path d="${wobblePath([[60,48],[842,60],[820,561],[75,548]])}" fill="${colors.ivory}" stroke="${colors.pencil}" stroke-width="6" filter="url(#softBleed)"/>
    <rect x="103" y="103" width="428" height="310" rx="18" fill="${colors.paper}" opacity="0.8" stroke="${colors.gray}" stroke-width="4"/>
    <path d="M588 118 L584 495" stroke="${colors.gray}" stroke-width="5" stroke-linecap="round" opacity="0.75"/>
    <path d="M641 166 L767 166 M641 219 L782 219 M641 272 L760 272 M641 391 L780 391 M641 444 L754 444" stroke="${colors.pencil}" stroke-width="5" stroke-linecap="round" opacity="0.42"/>
    <rect x="711" y="92" width="80" height="67" rx="10" fill="${colors.peach}" opacity="0.35" stroke="${colors.pencil}" stroke-width="4"/>
    <path d="M120 482 C225 458 397 456 512 482" stroke="${colors.sage}" stroke-width="10" stroke-linecap="round" opacity="0.25"/>
  `;
  return svgWrap("postcard_template_classic", 900, 620, body);
}

function parisLine() {
  const body = `
    ${blob(239, 251, 150, 76, colors.peach, 0.14)}
    <path d="M239 73 L151 330 L331 330 Z" fill="none" stroke="${colors.ink}" stroke-width="8" stroke-linejoin="round" stroke-linecap="round" filter="url(#pencilRough)"/>
    <path d="M204 184 L276 184 M184 242 L296 242 M166 300 L315 300" stroke="${colors.ink}" stroke-width="6" stroke-linecap="round" opacity="0.78" filter="url(#pencilRough)"/>
    <path d="M209 159 L277 330 M269 159 L200 330" stroke="${colors.pencil}" stroke-width="5" stroke-linecap="round"/>
    <path d="M130 337 C210 311 298 313 366 337" fill="none" stroke="${colors.sage}" stroke-width="9" stroke-linecap="round" opacity="0.35"/>
    <path d="M85 354 C182 376 320 375 408 354" fill="none" stroke="${colors.mist}" stroke-width="7" stroke-linecap="round" opacity="0.45"/>
  `;
  return svgWrap("destination_paris_line", 480, 360, body);
}

function icelandLine() {
  const body = `
    ${blob(236, 225, 190, 90, colors.mist, 0.18)}
    <path d="M45 293 L142 159 L208 249 L281 119 L430 293 Z" fill="${colors.mist}" opacity="0.28" stroke="${colors.ink}" stroke-width="7" stroke-linejoin="round" filter="url(#softBleed)"/>
    <path d="M142 159 L169 217 L207 249 M281 119 L244 215 L310 192" fill="none" stroke="${colors.paper}" stroke-width="8" stroke-linecap="round" opacity="0.86"/>
    <path d="M94 90 C136 63 180 68 214 101 C252 73 305 77 342 112" fill="none" stroke="${colors.pencil}" stroke-width="7" stroke-linecap="round" opacity="0.48"/>
    <path d="M64 306 C162 337 316 337 421 306" fill="none" stroke="${colors.sage}" stroke-width="8" stroke-linecap="round" opacity="0.33"/>
  `;
  return svgWrap("destination_iceland_line", 480, 360, body);
}

function tripRouteMapParis() {
  const body = `
    <rect width="640" height="360" fill="none"/>
    <path d="${wobblePath([[55,45],[586,56],[568,316],[72,304]])}" fill="${colors.paper}" stroke="${colors.pencil}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M118 250 C178 185 230 198 282 145 C340 84 432 113 506 69" fill="none" stroke="${colors.mist}" stroke-width="13" stroke-linecap="round" opacity="0.56" filter="url(#softBleed)"/>
    <path d="M118 250 C178 185 230 198 282 145 C340 84 432 113 506 69" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-dasharray="10 13" stroke-linecap="round" opacity="0.6" filter="url(#pencilRough)"/>
    <circle cx="118" cy="250" r="24" fill="${colors.sage}" opacity="0.46" stroke="${colors.ink}" stroke-width="4" filter="url(#softBleed)"/>
    <path d="M106 250 L119 238 L132 250 M112 250 L112 266 L126 266 L126 250" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="506" cy="69" r="26" fill="${colors.ochre}" opacity="0.5" stroke="${colors.ink}" stroke-width="4" filter="url(#softBleed)"/>
    <path d="M506 48 L486 109 L526 109 Z M498 79 L514 79" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M95 107 C143 87 197 91 236 118 C280 94 347 94 393 126" fill="none" stroke="${colors.pencil}" stroke-width="5" stroke-linecap="round" opacity="0.34"/>
    <path d="M103 294 C228 319 420 318 544 294" fill="none" stroke="${colors.sage}" stroke-width="8" stroke-linecap="round" opacity="0.25"/>
  `;
  return svgWrap("trip_route_map_paris", 640, 360, body);
}

function tripRouteMapIceland() {
  const body = `
    <rect width="640" height="360" fill="none"/>
    <path d="${wobblePath([[58,43],[584,54],[570,315],[70,306]])}" fill="${colors.paper}" stroke="${colors.pencil}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M116 253 C177 219 211 165 276 165 C342 164 377 109 443 111 C486 112 516 86 548 61" fill="none" stroke="${colors.mist}" stroke-width="15" stroke-linecap="round" opacity="0.52" filter="url(#softBleed)"/>
    <path d="M116 253 C177 219 211 165 276 165 C342 164 377 109 443 111 C486 112 516 86 548 61" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-dasharray="10 13" stroke-linecap="round" opacity="0.58" filter="url(#pencilRough)"/>
    <circle cx="116" cy="253" r="24" fill="${colors.sage}" opacity="0.46" stroke="${colors.ink}" stroke-width="4" filter="url(#softBleed)"/>
    <path d="M104 253 L117 241 L130 253 M110 253 L110 269 L124 269 L124 253" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="548" cy="61" r="27" fill="${colors.mist}" opacity="0.58" stroke="${colors.ink}" stroke-width="4" filter="url(#softBleed)"/>
    <path d="M514 90 L544 48 L562 75 L581 43 L606 90 Z" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
    <path d="M89 125 C132 93 184 97 220 127 C264 96 337 98 378 137" fill="none" stroke="${colors.pencil}" stroke-width="5" stroke-linecap="round" opacity="0.34"/>
    <path d="M110 297 C226 322 421 321 546 294" fill="none" stroke="${colors.sage}" stroke-width="8" stroke-linecap="round" opacity="0.22"/>
    <path d="M312 252 C351 220 394 219 433 248 C466 225 511 230 544 260" fill="none" stroke="${colors.gray}" stroke-width="5" stroke-linecap="round" opacity="0.32"/>
  `;
  return svgWrap("trip_route_map_iceland", 640, 360, body);
}

function tripMarkerCat() {
  const body = `
    ${blob(92, 112, 58, 44, colors.peach, 0.18)}
    <path d="M90 168 C59 129 40 99 40 69 C40 37 62 17 91 17 C120 17 141 38 141 68 C141 99 121 130 90 168 Z" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M65 61 L76 38 L90 62 M96 62 L110 38 L119 63" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="4" stroke-linejoin="round"/>
    <circle cx="77" cy="76" r="4.5" fill="${colors.ink}"/>
    <circle cx="103" cy="76" r="4.5" fill="${colors.ink}"/>
    <path d="M86 89 C89 94 94 94 97 89 M78 101 C87 109 101 109 110 101" fill="none" stroke="${colors.ink}" stroke-width="3" stroke-linecap="round"/>
    <path d="M90 168 C83 151 97 151 90 168 Z" fill="${colors.sage}" opacity="0.42"/>
  `;
  return svgWrap("trip_marker_cat", 180, 180, body);
}

function paperPlane() {
  const body = `
    <rect width="260" height="180" fill="none"/>
    <path d="${wobblePath([[24,92],[229,28],[162,151],[123,104]])}" fill="${colors.paper}" stroke="${colors.ink}" stroke-width="5" stroke-linejoin="round" filter="url(#softBleed)"/>
    <path d="M123 104 L229 28 L142 120" fill="none" stroke="${colors.pencil}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" filter="url(#pencilRough)"/>
    <path d="M24 92 L123 104 L88 133 Z" fill="${colors.mist}" opacity="0.38" stroke="${colors.ink}" stroke-width="4" stroke-linejoin="round" filter="url(#softBleed)"/>
    <path d="M40 137 C70 161 120 164 158 145" fill="none" stroke="${colors.sage}" stroke-width="6" stroke-linecap="round" opacity="0.38"/>
    <path d="M22 128 C43 145 72 150 94 143" fill="none" stroke="${colors.ochre}" stroke-width="4" stroke-linecap="round" opacity="0.34"/>
  `;
  return svgWrap("prop_paper_plane", 260, 180, body);
}

function catSelfie() {
  const body = `
    <rect x="53" y="54" width="318" height="322" rx="32" fill="${colors.paper}" opacity="0.85" stroke="${colors.pencil}" stroke-width="5" filter="url(#softBleed)"/>
    ${blob(212, 219, 104, 113, colors.peach, 0.18)}
    <path d="M134 168 L159 109 L192 166 M235 166 L266 109 L289 171" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" stroke-linejoin="round"/>
    <ellipse cx="212" cy="206" rx="92" ry="84" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <ellipse cx="213" cy="314" rx="86" ry="72" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <circle cx="181" cy="200" r="6" fill="${colors.ink}"/>
    <circle cx="242" cy="200" r="6" fill="${colors.ink}"/>
    <path d="M204 218 C211 226 218 226 224 218 M190 238 C205 252 231 252 246 238" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-linecap="round"/>
    <path d="M129 305 C94 280 85 241 103 216" fill="none" stroke="${colors.ink}" stroke-width="10" stroke-linecap="round" opacity="0.75"/>
    <path d="M307 305 C349 278 356 237 333 211" fill="none" stroke="${colors.ink}" stroke-width="10" stroke-linecap="round" opacity="0.75"/>
    <circle cx="306" cy="116" r="20" fill="${colors.ochre}" opacity="0.4" filter="url(#softBleed)"/>
  `;
  return svgWrap("animal_cat_selfie", 420, 420, body);
}

function dogHome() {
  const body = `
    <rect width="420" height="420" fill="none"/>
    ${blob(210, 310, 120, 52, colors.ochre, 0.14)}
    <ellipse cx="210" cy="255" rx="102" ry="114" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <ellipse cx="210" cy="163" rx="98" ry="82" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M122 142 C86 151 83 205 115 225 C138 238 157 210 151 171" fill="${colors.ochre}" opacity="0.42" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M298 142 C334 151 337 205 305 225 C282 238 263 210 269 171" fill="${colors.ochre}" opacity="0.42" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <circle cx="177" cy="162" r="6" fill="${colors.ink}"/>
    <circle cx="243" cy="162" r="6" fill="${colors.ink}"/>
    <path d="M204 183 C210 190 218 190 224 183 M188 207 C203 222 236 222 251 207" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-linecap="round"/>
    <path d="M167 349 C182 370 202 372 216 352 M225 352 C244 373 267 370 279 348" fill="none" stroke="${colors.ink}" stroke-width="5" stroke-linecap="round"/>
    <path d="M291 295 C340 298 360 268 344 235" fill="none" stroke="${colors.ink}" stroke-width="11" stroke-linecap="round" opacity="0.75"/>
    <path d="M153 96 C190 82 259 84 295 99" fill="none" stroke="${colors.sage}" stroke-width="10" stroke-linecap="round" opacity="0.23"/>
  `;
  return svgWrap("animal_dog_home", 420, 420, body);
}

function dogVisitor() {
  const body = `
    <rect width="380" height="420" fill="none"/>
    ${blob(191, 260, 116, 100, colors.ochre, 0.14)}
    <path d="M94 346 C101 259 137 190 198 171 C257 191 293 260 300 346 Z" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M129 178 C91 190 87 244 124 260 M268 178 C306 190 310 244 273 260" fill="${colors.ochre}" opacity="0.38" stroke="${colors.ink}" stroke-width="5" stroke-linecap="round" filter="url(#softBleed)"/>
    <circle cx="171" cy="236" r="6" fill="${colors.ink}"/>
    <circle cx="225" cy="236" r="6" fill="${colors.ink}"/>
    <path d="M191 255 C197 262 204 262 210 255 M180 276 C193 288 217 288 230 276" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-linecap="round"/>
    <path d="M82 347 C136 367 269 366 326 347" fill="none" stroke="${colors.gray}" stroke-width="4" stroke-linecap="round" opacity="0.58"/>
  `;
  return svgWrap("animal_dog_visitor", 380, 420, body);
}

function rabbitHome() {
  const body = `
    <rect width="420" height="420" fill="none"/>
    ${blob(208, 314, 125, 50, colors.peach, 0.12)}
    <path d="M151 151 C136 98 147 47 178 41 C211 35 218 93 202 155" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M240 154 C224 93 236 35 270 42 C301 49 310 100 291 154" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <ellipse cx="211" cy="184" rx="99" ry="84" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <ellipse cx="210" cy="302" rx="96" ry="105" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M165 72 C183 99 184 121 177 146 M263 72 C248 101 249 122 258 146" stroke="${colors.peach}" stroke-width="10" stroke-linecap="round" opacity="0.34"/>
    <circle cx="176" cy="182" r="6" fill="${colors.ink}"/>
    <circle cx="244" cy="182" r="6" fill="${colors.ink}"/>
    <path d="M204 203 C210 210 218 210 224 203 M189 224 C204 237 235 237 250 224" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-linecap="round"/>
    <circle cx="295" cy="309" r="26" fill="${colors.paper}" stroke="${colors.ink}" stroke-width="5" opacity="0.88"/>
    <path d="M169 367 C184 383 203 385 216 368 M227 368 C245 386 266 383 280 365" fill="none" stroke="${colors.ink}" stroke-width="5" stroke-linecap="round"/>
  `;
  return svgWrap("animal_rabbit_home", 420, 420, body);
}

function rabbitVisitor() {
  const body = `
    <rect width="380" height="420" fill="none"/>
    ${blob(190, 260, 112, 100, colors.peach, 0.12)}
    <path d="M144 186 C126 116 136 54 170 47 C205 40 212 117 196 188" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M216 188 C200 117 208 40 244 47 C278 54 287 116 265 186" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M94 346 C101 260 137 196 199 177 C258 197 293 260 300 346 Z" fill="${colors.ivory}" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <circle cx="173" cy="241" r="6" fill="${colors.ink}"/>
    <circle cx="226" cy="241" r="6" fill="${colors.ink}"/>
    <path d="M193 259 C198 265 205 265 211 259 M181 279 C194 291 218 291 231 279" fill="none" stroke="${colors.ink}" stroke-width="4" stroke-linecap="round"/>
    <circle cx="282" cy="310" r="22" fill="${colors.paper}" stroke="${colors.ink}" stroke-width="4" opacity="0.82"/>
    <path d="M82 347 C136 367 269 366 326 347" fill="none" stroke="${colors.gray}" stroke-width="4" stroke-linecap="round" opacity="0.58"/>
  `;
  return svgWrap("animal_rabbit_visitor", 380, 420, body);
}

function stamp(name, titleShape, accent) {
  const inner = titleShape === "paris"
    ? `<path d="M91 62 L59 143 L122 143 Z M77 102 L104 102" fill="none" stroke="${accent}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>`
    : `<path d="M42 132 L77 82 L103 119 L133 62 L171 132 Z" fill="none" stroke="${accent}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>`;
  const body = `
    <circle cx="90" cy="90" r="69" fill="none" stroke="${accent}" stroke-width="7" opacity="0.72" filter="url(#pencilRough)"/>
    <circle cx="90" cy="90" r="52" fill="none" stroke="${accent}" stroke-width="3" opacity="0.45" filter="url(#pencilRough)"/>
    ${inner}
    <path d="M22 163 C65 143 124 145 164 164" fill="none" stroke="${accent}" stroke-width="5" stroke-linecap="round" opacity="0.5"/>
    <path d="M17 26 C63 42 122 40 164 24" fill="none" stroke="${accent}" stroke-width="4" stroke-linecap="round" opacity="0.45"/>
  `;
  return svgWrap(name, 180, 180, body);
}

function settingsNotificationNote() {
  const body = `
    <rect width="560" height="360" fill="none"/>
    ${blob(280, 276, 180, 34, colors.gray, 0.13)}
    <path d="${wobblePath([[110,68],[451,54],[469,276],[125,296]])}" fill="${colors.ivory}" stroke="${colors.pencil}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M177 147 C177 111 201 83 240 83 C279 83 303 111 303 147 C303 180 309 203 329 226 L151 236 C171 211 177 182 177 147 Z" fill="${colors.mist}" opacity="0.34" stroke="${colors.ink}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="M222 246 C229 260 252 259 260 244" fill="none" stroke="${colors.ink}" stroke-width="5" stroke-linecap="round"/>
    <path d="M350 128 L416 124 M348 178 L421 173 M348 228 L397 224" stroke="${colors.pencil}" stroke-width="5" stroke-linecap="round" opacity="0.42"/>
    <circle cx="401" cy="95" r="18" fill="${colors.ochre}" opacity="0.32" filter="url(#softBleed)"/>
  `;
  return svgWrap("settings_notification_note", 560, 360, body);
}

function settingsCollectionEmpty() {
  const body = `
    <rect width="560" height="360" fill="none"/>
    ${blob(281, 284, 200, 34, colors.gray, 0.13)}
    <path d="${wobblePath([[132,93],[417,77],[432,274],[145,290]])}" fill="${colors.ivory}" stroke="${colors.pencil}" stroke-width="5" filter="url(#softBleed)"/>
    <path d="${wobblePath([[176,122],[385,111],[394,242],[186,253]])}" fill="${colors.paper}" stroke="${colors.gray}" stroke-width="4" filter="url(#pencilRough)"/>
    <path d="M210 206 C249 181 305 183 342 207" fill="none" stroke="${colors.sage}" stroke-width="9" stroke-linecap="round" opacity="0.36"/>
    <path d="M222 166 C245 147 274 150 293 171 C314 151 346 151 367 174" fill="none" stroke="${colors.mist}" stroke-width="7" stroke-linecap="round" opacity="0.56"/>
    <rect x="325" y="127" width="44" height="38" rx="8" fill="${colors.peach}" opacity="0.38" stroke="${colors.pencil}" stroke-width="3"/>
    <path d="M157 286 C246 306 343 306 431 284" fill="none" stroke="${colors.gray}" stroke-width="4" stroke-linecap="round" opacity="0.4"/>
  `;
  return svgWrap("settings_collection_empty", 560, 360, body);
}

function settingsAboutCabin() {
  const body = `
    <rect width="560" height="360" fill="none"/>
    ${blob(283, 270, 190, 38, colors.gray, 0.13)}
    <circle cx="409" cy="88" r="27" fill="${colors.ochre}" opacity="0.28" filter="url(#softBleed)"/>
    <path d="M160 198 L257 116 L354 198 Z" fill="${colors.peach}" opacity="0.32" stroke="${colors.ink}" stroke-width="5" stroke-linejoin="round" filter="url(#pencilRough)"/>
    <path d="M180 196 L335 196 L324 286 L194 286 Z" fill="${colors.ivory}" stroke="${colors.pencil}" stroke-width="5" filter="url(#softBleed)"/>
    <rect x="234" y="232" width="45" height="54" rx="14" fill="${colors.sage}" opacity="0.38" stroke="${colors.ink}" stroke-width="4"/>
    <rect x="292" y="219" width="32" height="32" rx="8" fill="${colors.mist}" opacity="0.55" stroke="${colors.pencil}" stroke-width="3"/>
    <path d="M112 287 C215 312 341 312 447 286" fill="none" stroke="${colors.gray}" stroke-width="4" stroke-linecap="round" opacity="0.42"/>
    <path d="M367 168 C398 149 440 151 467 176" fill="none" stroke="${colors.paper}" stroke-width="8" stroke-linecap="round" opacity="0.88"/>
  `;
  return svgWrap("settings_about_cabin", 560, 360, body);
}

function texturePaper() {
  const body = `
    <rect width="512" height="512" fill="${colors.paper}"/>
    <rect width="512" height="512" fill="${colors.ochre}" opacity="0.12" filter="url(#paperNoise)"/>
    <g opacity="0.09" stroke="${colors.pencil}" stroke-width="1">
      ${Array.from({ length: 36 }, (_, i) => {
        const y = 16 + i * 14;
        const x2 = 512 - (i % 5) * 9;
        return `<path d="M${(i % 7) * 4} ${y} C120 ${y - 8} 250 ${y + 10} ${x2} ${y - 2}" fill="none"/>`;
      }).join("\n")}
    </g>
  `;
  return svgWrap("texture_paper_grain", 512, 512, body);
}

const artAssets = {
  texture_paper_grain: texturePaper,
  cabin_room_base: cabinRoomBase,
  onboarding_cabin_path: onboardingCabinPath,
  onboarding_cat_suitcase: onboardingCatSuitcase,
  health_steps_ticket: healthStepsTicket,
  animal_cat_home: catHome,
  animal_dog_home: dogHome,
  animal_dog_visitor: dogVisitor,
  animal_rabbit_home: rabbitHome,
  animal_rabbit_visitor: rabbitVisitor,
  prop_map_table: mapTable,
  prop_ticket_single: ticketSingle,
  animal_visitor_unknown: visitorUnknown,
  mailbox_tray_base: mailboxTray,
  envelope_unread: () => envelope("envelope_unread", colors.ivory, colors.ochre),
  envelope_read: () => envelope("envelope_read", "#F3E8D4", colors.sage),
  envelope_old: () => envelope("envelope_old", "#E9D9B8", colors.warn, true),
  postcard_template_classic: postcardTemplate,
  destination_paris_line: parisLine,
  destination_iceland_line: icelandLine,
  trip_route_map_paris: tripRouteMapParis,
  trip_route_map_iceland: tripRouteMapIceland,
  animal_cat_selfie: catSelfie,
  trip_marker_cat: tripMarkerCat,
  prop_paper_plane: paperPlane,
  ticket_flight_trail: ticketFlightTrail,
  ticket_confirm_card: ticketConfirmCard,
  stamp_paris: () => stamp("stamp_paris", "paris", colors.ochre),
  stamp_iceland: () => stamp("stamp_iceland", "iceland", colors.mist),
  settings_notification_note: settingsNotificationNote,
  settings_collection_empty: settingsCollectionEmpty,
  settings_about_cabin: settingsAboutCabin,
};

function iconSvg(name, body) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="${name}">
  ${body}
</svg>
`;
}

const icons = {
  icon_home: iconSvg("icon_home", `<path d="M3.8 11.2 12 4.4l8.2 6.8"/><path d="M6.2 10.5v8.1c0 .7.4 1.1 1.1 1.1h9.4c.7 0 1.1-.4 1.1-1.1v-8.1"/><path d="M9.7 19.5v-5.1h4.6v5.1"/><path d="M8.2 8.2c1.2-.8 2.4-1.1 3.8-1.1 1.5 0 2.7.4 3.8 1.1"/>`),
  icon_mail: iconSvg("icon_mail", `<path d="M4.2 7.2h15.6c.7 0 1.2.5 1.2 1.2v9c0 .7-.5 1.2-1.2 1.2H4.2c-.7 0-1.2-.5-1.2-1.2v-9c0-.7.5-1.2 1.2-1.2Z"/><path d="M4 8.4c2.2 1.7 4.5 3.4 8 6.1 3.5-2.7 5.8-4.4 8-6.1"/><path d="M4.1 17.5c1.9-1.6 3.3-2.7 5.1-4.1"/><path d="M19.9 17.5c-1.9-1.6-3.3-2.7-5.1-4.1"/>`),
  icon_settings: iconSvg("icon_settings", `<path d="M12 8.2a3.8 3.8 0 1 0 0 7.6 3.8 3.8 0 0 0 0-7.6Z"/><path d="M19.5 13.4c.1-.5.1-.9 0-1.4l2-1.4-2-3.4-2.4 1a7.2 7.2 0 0 0-1.3-.8L15.5 5h-7l-.3 2.4c-.5.2-.9.5-1.3.8l-2.4-1-2 3.4 2 1.4a6.2 6.2 0 0 0 0 1.4l-2 1.4 2 3.4 2.4-1c.4.3.8.6 1.3.8l.3 2.4h7l.3-2.4c.5-.2.9-.5 1.3-.8l2.4 1 2-3.4-2-1.4Z"/>`),
  icon_back: iconSvg("icon_back", `<path d="M15.6 5.2 8.4 12l7.2 6.8"/><path d="M9.2 12h11.1"/><path d="M7.6 12c.7-.5 1.4-.9 2.2-1.2"/>`),
  icon_health: iconSvg("icon_health", `<path d="M12 20.2S4.5 15.8 4.5 9.5c0-2.2 1.6-4 3.8-4 1.5 0 2.8.8 3.7 2.1.9-1.3 2.2-2.1 3.7-2.1 2.2 0 3.8 1.8 3.8 4 0 6.3-7.5 10.7-7.5 10.7Z"/><path d="M7.2 12.2h2.7l1.2-2.5 2.1 5.1 1.3-2.6h2.5"/>`),
  icon_ticket: iconSvg("icon_ticket", `<path d="M4.1 7.2 19.4 5.8c.7-.1 1.3.4 1.4 1.1l.8 8.7c.1.7-.4 1.3-1.1 1.4L5.2 18.4c-.7.1-1.3-.4-1.4-1.1L3 8.6c-.1-.7.4-1.3 1.1-1.4Z"/><path d="M8.4 6.9c1.1 1.1 1.3 2.4.6 3.8-.7 1.3-.6 2.8.4 4.1.5.7.7 1.6.6 2.5"/><path d="M12.4 9.5 17 9.1"/><path d="M12.9 13.6l4.6-.4"/>`),
  icon_steps: iconSvg("icon_steps", `<path d="M8.1 13.3c1.8.4 3 .1 3.6-.8.8-1.1.3-2.7-1-3.6-1.4-1-3.3-.8-4.2.5-.8 1.2-.4 2.9 1.6 3.9Z"/><path d="M15.5 18.9c1.9.3 3.1-.1 3.6-1.2.7-1.3 0-2.8-1.5-3.5-1.6-.7-3.4-.1-4.1 1.3-.6 1.3.1 2.8 2 3.4Z"/><path d="M7.8 4.5c.6-.5 1.5-.7 2.4-.5"/><path d="M14.5 9.8c.8-.2 1.7-.1 2.5.4"/>`),
  icon_notification: iconSvg("icon_notification", `<path d="M6.2 17.5h11.6c-1.1-1.3-1.5-3.2-1.5-5.6 0-2.6-1.7-4.7-4.3-4.7s-4.3 2.1-4.3 4.7c0 2.4-.4 4.3-1.5 5.6Z"/><path d="M10 19.2c.4.8 1.1 1.2 2 1.2s1.6-.4 2-1.2"/><path d="M10.5 5.4c.2-.9.7-1.4 1.5-1.4s1.3.5 1.5 1.4"/><path d="M18.7 8.2c.8.7 1.3 1.6 1.5 2.7"/><path d="M5.3 8.2c-.8.7-1.3 1.6-1.5 2.7"/>`),
  icon_collection: iconSvg("icon_collection", `<path d="M5.2 5.7h10.6c.8 0 1.2.4 1.2 1.2v12.4l-5.9-3.2-5.9 3.2V6.9c0-.8.4-1.2 1.2-1.2Z"/><path d="M8.1 8.6h5.8"/><path d="M8.1 11.3h4.1"/><path d="M17.2 8.1h1.2c.8 0 1.2.4 1.2 1.2v11.1"/>`),
  icon_about: iconSvg("icon_about", `<path d="M12 20.4a8.4 8.4 0 1 0 0-16.8 8.4 8.4 0 0 0 0 16.8Z"/><path d="M12 10.8v5.1"/><path d="M12 7.5h.1"/><path d="M8.7 5.5c1-.5 2.2-.8 3.4-.8 1.3 0 2.4.3 3.4.8"/>`),
};

function categoryFor(name) {
  return Object.entries(groups).find(([, names]) => names.includes(name))?.[0];
}

function writeAsset(name, svg, options) {
  const group = categoryFor(name);
  if (!group) throw new Error(`Missing group for ${name}`);
  const groupDir = path.join(assetRoot, group);
  const imageSetDir = path.join(groupDir, `${name}.imageset`);
  const sourceDir = path.join(sourceRoot, group);
  ensureDir(groupDir);
  ensureDir(imageSetDir);
  ensureDir(sourceDir);
  writeJSON(path.join(groupDir, "Contents.json"), groupContents());
  fs.writeFileSync(path.join(imageSetDir, `${name}.svg`), svg);
  fs.writeFileSync(path.join(sourceDir, `${name}.svg`), svg);
  writeJSON(path.join(imageSetDir, "Contents.json"), imageContents(`${name}.svg`, options));
}

function writeRootContents() {
  writeJSON(path.join(assetRoot, "Contents.json"), groupContents());
}

writeRootContents();
for (const [name, render] of Object.entries(artAssets)) {
  writeAsset(name, render(), { vector: true });
}
for (const [name, svg] of Object.entries(icons)) {
  writeAsset(name, svg, { template: true });
}

console.log(`Generated ${Object.keys(artAssets).length} watercolor assets and ${Object.keys(icons).length} UI icons.`);
