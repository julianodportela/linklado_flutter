package com.linklado.tuklado.tuklado_flutter

import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.inputmethodservice.InputMethodService
import android.os.Handler
import android.os.Looper
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.LinearLayout
import android.widget.PopupWindow
import android.widget.TextView
import android.view.KeyEvent as AndroidKeyEvent

class Linklado : InputMethodService() {

    private enum class ShiftState { OFF, ON, LOCKED }
    private enum class Layer { LETTERS, NUMBERS, SYMBOLS }

    private var shiftState  = ShiftState.OFF
    private var currentLayer = Layer.LETTERS

    private lateinit var rootView: LinearLayout

    private val backspaceHandler = Handler(Looper.getMainLooper())
    private val longPressHandler  = Handler(Looper.getMainLooper())

    // ── Brand colors ──────────────────────────────────────────────────────────
    private val cBg      = Color.parseColor("#1a1025")
    private val cKey     = Color.parseColor("#2d2040")
    private val cAction  = Color.parseColor("#130d1e")
    private val cPurple  = Color.parseColor("#7c3aed")
    private val cGreen   = Color.parseColor("#16a34a")
    private val cShiftOn = Color.parseColor("#a78bfa")
    private val cShiftLk = Color.parseColor("#c4b5fd")
    private val cPressed = Color.parseColor("#4c3a7a")
    private val cSubtext = Color.parseColor("#a0a0c0")

    // ── Drag popup state ──────────────────────────────────────────────────────
    private var activePopup:      PopupWindow? = null
    private var popupAlts:        List<String> = emptyList()
    private var popupViews:       List<TextView> = emptyList()
    private var popupHighlighted: Int = -1
    private var popupLeft:        Int = 0   // screen x of first item's left edge
    private var popupTop:         Int = 0   // screen y of first row's top edge
    private var popupItemWidth:   Int = 0   // px per slot (item width + margins)
    private var popupRowHeight:   Int = 0   // px per row
    private var popupItemsPerRow: Int = 1   // items in the first (widest) row

    // ── Diacríticos combinantes ───────────────────────────────────────────────
    // Pressionar ~ ou ´ envia uma marca Unicode combinante que se empilha sobre
    // o caractere anterior. Múltiplos toques empilham: a → ã → ã́ (til + agudo).
    private val combiningMap = mapOf(
        "~"  to "̃",  // TIL COMBINANTE          → ã õ ñ ĩ
        "´"  to "́",  // ACENTO AGUDO COMBINANTE → á é í ó ú
        "`"  to "̀",  // ACENTO GRAVE COMBINANTE → à è ì ò ù
        "^"  to "̂",  // CIRCUNFLEXO COMBINANTE  → â ê î ô û
        "¨"  to "̈",  // TREMA COMBINANTE        → ä ë ï ö ü
        "¯"  to "̄",  // MÁCRON COMBINANTE       → ā ē ī ō ū
        "˙"  to "̇",  // PONTO ACIMA COMBINANTE  → ȧ ċ ż
        "ˇ"  to "̌",  // CARON COMBINANTE        → ǎ č š ž
    )

    // ── Alternativas de pressão longa ────────────────────────────────────────
    // Combinações pré-compostas (letra + diacrítico em uma única opção no popup)
    // permitem inserir com um toque em vez de digitar base + tecla de acento.
    private val longPressMap = mapOf(
        // Vogais — formas acentuadas pré-compostas e combinações indígenas chave
        "a"  to listOf("á","à","â","ã","ä","ā","ă","æ"),
        "e"  to listOf("é","è","ê","ẽ","ë","ē","ə","ə̃"),  // ə̃ = schwa nasalizado (Hup)
        "i"  to listOf("í","ì","î","ĩ","ï","ī"),
        "o"  to listOf("ó","ò","ô","õ","ö","ō"),
        "u"  to listOf("ú","ù","û","ũ","ü","ü̃","ǘ","ǜ","ū"),  // ü̃ = Ticuna/Siona; ǘ ǜ = Tukano tonal
        "y"  to listOf("ỹ","ỳ","ý"),
        // Vogais IPA — combinações mais usadas nas línguas indígenas
        "ɛ"  to listOf("ɛ̃","ɛ́","ɛ̀","Ɛ","ə","æ"),
        "ɔ"  to listOf("ɔ̃","ɔ́","ɔ̀","Ɔ"),
        "ɨ"  to listOf("ɨ̃","ɨ́","ɨ̀","Ɨ"),
        "ʉ"  to listOf("ʉ̃","ʉ́","ʉ̀","ʉ̈","Ʉ"),  // ʉ̈ = u-barra com trema (ortografias Tukano)
        "ñ"  to listOf("Ñ"),
        "ç"  to listOf("Ç"),
        "ŋ"  to listOf("Ŋ"),
        "ɲ"  to listOf("Ɲ"),
        "n"  to listOf("ŋ","ɲ"),
        "c"  to listOf("ç"),
        "g"  to listOf("g̃"),   // g̃ = g nasal (Guaraní)
        "s"  to listOf("ß"),
        // Fileira de diacríticos — pressão longa revela o conjunto completo de marcas combinantes
        "~"  to listOf("^","¨","¯","˙","ˇ","`"),
        "´"  to listOf("`","^","¨","¯","˙","ˇ"),
        "."  to listOf(":","…","!","?","·"),
        ","  to listOf("-","_",";","«","»"),
        "’"  to listOf("’","’",""","""),
        "-"  to listOf("–","—"),
        "?"  to listOf("¿"),
        "!"  to listOf("¡"),
        "/"  to listOf("\\","|"),
        "("  to listOf("[","{","<"),
        ")"  to listOf("]","}",">"),
        "1"  to listOf("¹","½","¼"),
        "2"  to listOf("²","⅔"),
        "3"  to listOf("³","¾"),
        "0"  to listOf("°","∞"),
        "@"  to listOf("©","®","™"),
    )

    // ── InputMethodService lifecycle ──────────────────────────────────────────

    override fun onCreateInputView(): View {
        rootView = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(cBg)
            setPadding(0, dp(8), 0, 0)
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
        buildLayer()
        return rootView
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        if (!restarting) {
            dismissPopup()
            if (currentLayer != Layer.LETTERS || shiftState == ShiftState.ON) {
                shiftState   = ShiftState.OFF
                currentLayer = Layer.LETTERS
                rebuildKeys()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        backspaceHandler.removeCallbacksAndMessages(null)
        longPressHandler.removeCallbacksAndMessages(null)
        dismissPopup()
    }

    // ── Keyboard builder ──────────────────────────────────────────────────────

    private fun rebuildKeys() {
        dismissPopup()
        rootView.removeAllViews()
        buildLayer()
    }

    private fun buildLayer() = when (currentLayer) {
        Layer.LETTERS -> buildLetters()
        Layer.NUMBERS -> buildNumbers()
        Layer.SYMBOLS -> buildSymbols()
    }

    // ── Camada de letras (5 fileiras) ────────────────────────────────────────
    //
    // Fileira 1: q  w  e  r  t  y  u [ʉ]  i [ɨ]  o  p   ← ʉ ao lado de u, ɨ ao lado de i
    // Fileira 2: a  s  d  f  g  h  j   k   l   '
    // Fileira 3: ⇧  z  x  c  v  b  n  [ñ]  m   ⌫
    // Fileira 4: [ɛ  ɔ  ŋ  ç  ʔ  ʼ  ~  ´]              ← todas roxas, largura total
    // Fileira 5: ?123  ,  ─── espaço ───  .  ↵

    private fun buildLetters() {
        val up = shiftState != ShiftState.OFF
        fun s(v: String) = if (up && v.length == 1 && v[0].isLetter()) v.uppercase() else v

        addRow { row ->
            listOf("q","w","e","r","t","y").forEach { row.addView(charKey(s(it), 1f)) }
            row.addView(charKey(s("u"), 1f))
            row.addView(charKey("ʉ", 1f, cPurple))
            row.addView(charKey(s("i"), 1f))
            row.addView(charKey("ɨ", 1f, cPurple))
            listOf("o","p").forEach { row.addView(charKey(s(it), 1f)) }
        }
        addRow { row ->
            listOf("a","s","d","f","g","h","j","k","l","'").forEach { row.addView(charKey(s(it), 1f)) }
        }
        addRow { row ->
            row.addView(shiftKey(1.5f))
            listOf("z","x","c","v","b","n").forEach { row.addView(charKey(s(it), 1f)) }
            row.addView(charKey(s("ñ"), 1f, cPurple))
            row.addView(charKey(s("m"), 1f))
            row.addView(backspaceKey(1.5f))
        }
        // fileira de caracteres indígenas — todos roxos, largura total
        addRow { row ->
            listOf("ɛ","ɔ","ŋ","ç","ʔ","ʼ","~","´").forEach { row.addView(charKey(it, 1f, cPurple)) }
        }
        addRow { row ->
            row.addView(actionKey("?123", 1.5f) { currentLayer = Layer.NUMBERS; rebuildKeys() })
            row.addView(charKey(",", 1f))
            row.addView(spaceKey(5f))
            row.addView(charKey(".", 1f))
            row.addView(returnKey(1.5f))
        }
    }

    // ── Camada de números ─────────────────────────────────────────────────────
    //
    // Fileira 1: 1  2  3  4  5  6  7  8  9  0
    // Fileira 2: @  #  $  %  &  -  +  (  )  /
    // Fileira 3: #+= | .  _  ?  !  '  "  | ⌫
    // Fileira 4: ABC | ,  ──── espaço ────  .  ↵

    private fun buildNumbers() {
        addRow { row ->
            listOf("1","2","3","4","5","6","7","8","9","0").forEach { row.addView(charKey(it, 1f)) }
        }
        addRow { row ->
            listOf("@","#","\$","%","&","-","+","(",")","/").forEach { row.addView(charKey(it, 1f)) }
        }
        addRow { row ->
            row.addView(actionKey("#+＝", 1.5f) { currentLayer = Layer.SYMBOLS; rebuildKeys() })
            listOf(".","_","?","!","'","\"").forEach { row.addView(charKey(it, 1f)) }
            row.addView(backspaceKey(1.5f))
        }
        addRow { row ->
            row.addView(actionKey("ABC", 1.5f) { currentLayer = Layer.LETTERS; rebuildKeys() })
            row.addView(charKey(",", 1f))
            row.addView(spaceKey(4.5f))
            row.addView(charKey(".", 1f))
            row.addView(returnKey(1.5f))
        }
    }

    // ── Camada de símbolos ────────────────────────────────────────────────────
    //
    // Fileira 1: [  ]  {  }  \  |  ~  `  ^  °
    // Fileira 2: €  £  ¥  ¢  §  ©  ™  ®  …  •
    // Fileira 3: 123 | ÷  ×  =  _  <  >  — | ⌫
    // Fileira 4: ABC | ───────── espaço ──────  ↵

    private fun buildSymbols() {
        addRow { row ->
            listOf("[","]","{","}","\\","|","~","`","^","°").forEach { row.addView(charKey(it, 1f)) }
        }
        addRow { row ->
            listOf("€","£","¥","¢","§","©","™","®","…","•").forEach { row.addView(charKey(it, 1f)) }
        }
        addRow { row ->
            row.addView(actionKey("123", 1.5f) { currentLayer = Layer.NUMBERS; rebuildKeys() })
            listOf("÷","×","=","_","<",">","—").forEach { row.addView(charKey(it, 1f)) }
            row.addView(backspaceKey(1.5f))
        }
        addRow { row ->
            row.addView(actionKey("ABC", 1.5f) { currentLayer = Layer.LETTERS; rebuildKeys() })
            row.addView(spaceKey(7f))
            row.addView(returnKey(1.5f))
        }
    }

    // ── Row builder ───────────────────────────────────────────────────────────

    private fun addRow(block: (LinearLayout) -> Unit) {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity     = Gravity.FILL_HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, dp(52)
            )
            setPadding(dp(2), dp(3), dp(2), dp(3))
        }
        block(row)
        rootView.addView(row)
    }

    // ── Key factories ─────────────────────────────────────────────────────────

    private fun charKey(
        label: String,
        weight: Float,
        bgColor: Int = cKey,
        textSizeSp: Float = 19f
    ): TextView {
        val tv   = baseTextView(label, weight, bgColor, textSizeSp)
        val alts = longPressMap[label.lowercase()] ?: longPressMap[label]
        var longFired = false

        tv.setOnTouchListener { v, e ->
            when (e.action) {
                MotionEvent.ACTION_DOWN -> {
                    longFired = false
                    v.background = roundRect(cPressed)
                    if (alts != null) {
                        longPressHandler.postDelayed({
                            longFired = true
                            showKeyPopup(v, alts)
                        }, 380)
                    }
                }
                MotionEvent.ACTION_MOVE -> {
                    if (activePopup != null) updatePopupHover(e.rawX, e.rawY)
                }
                MotionEvent.ACTION_UP -> {
                    longPressHandler.removeCallbacksAndMessages(null)
                    v.background = roundRect(bgColor)
                    if (activePopup != null) {
                        commitAndDismissPopup()
                    } else if (!longFired) {
                        handleChar(label)
                    }
                }
                MotionEvent.ACTION_CANCEL -> {
                    longPressHandler.removeCallbacksAndMessages(null)
                    v.background = roundRect(bgColor)
                    dismissPopup()
                }
            }
            true
        }
        return tv
    }

    private fun shiftKey(weight: Float): TextView {
        val (label, bg) = when (shiftState) {
            ShiftState.OFF    -> "⇧" to cAction
            ShiftState.ON     -> "⬆" to cShiftOn
            ShiftState.LOCKED -> "⬆" to cShiftLk
        }
        return baseTextView(label, weight, bg, 18f).apply {
            setOnClickListener { handleShift() }
        }
    }

    private fun backspaceKey(weight: Float): TextView {
        val tv = baseTextView("⌫", weight, cAction, 18f)
        var bsRunnable: Runnable? = null
        tv.setOnTouchListener { v, e ->
            when (e.action) {
                MotionEvent.ACTION_DOWN -> {
                    v.background = roundRect(cPressed)
                    handleBackspace()
                    bsRunnable = object : Runnable {
                        override fun run() {
                            handleBackspace()
                            backspaceHandler.postDelayed(this, 45)
                        }
                    }
                    backspaceHandler.postDelayed(bsRunnable!!, 500)
                }
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                    v.background = roundRect(cAction)
                    bsRunnable?.let { backspaceHandler.removeCallbacks(it) }
                    bsRunnable = null
                }
            }
            true
        }
        return tv
    }

    private fun actionKey(label: String, weight: Float = 1f, onClick: () -> Unit): TextView =
        baseTextView(label, weight, cAction, 13f).apply {
            setOnTouchListener { v, e ->
                when (e.action) {
                    MotionEvent.ACTION_DOWN   -> v.background = roundRect(cPressed)
                    MotionEvent.ACTION_UP     -> { v.background = roundRect(cAction); onClick() }
                    MotionEvent.ACTION_CANCEL -> v.background = roundRect(cAction)
                }
                true
            }
        }

    private fun spaceKey(weight: Float): TextView =
        baseTextView("espaço", weight, cKey, 13f).apply {
            setTextColor(cSubtext)
            setOnTouchListener { v, e ->
                when (e.action) {
                    MotionEvent.ACTION_DOWN   -> v.background = roundRect(cPressed)
                    MotionEvent.ACTION_UP     -> { v.background = roundRect(cKey); handleChar(" ") }
                    MotionEvent.ACTION_CANCEL -> v.background = roundRect(cKey)
                }
                true
            }
        }

    private fun returnKey(weight: Float): TextView =
        baseTextView("↵", weight, cGreen, 20f).apply {
            setOnTouchListener { v, e ->
                when (e.action) {
                    MotionEvent.ACTION_DOWN   -> v.background = roundRect(cPressed)
                    MotionEvent.ACTION_UP     -> { v.background = roundRect(cGreen); handleReturn() }
                    MotionEvent.ACTION_CANCEL -> v.background = roundRect(cGreen)
                }
                true
            }
        }

    private fun baseTextView(
        label: String, weight: Float, bgColor: Int, textSizeSp: Float
    ): TextView = TextView(this).apply {
        text = label
        gravity = Gravity.CENTER
        setTextSize(TypedValue.COMPLEX_UNIT_SP, textSizeSp)
        setTextColor(Color.WHITE)
        typeface = Typeface.DEFAULT_BOLD
        layoutParams = LinearLayout.LayoutParams(
            0, ViewGroup.LayoutParams.MATCH_PARENT, weight
        ).apply { setMargins(dp(2), dp(2), dp(2), dp(2)) }
        background = roundRect(bgColor)
    }

    // ── Popup de seleção por arraste ─────────────────────────────────────────
    // Segurar tecla → popup aparece acima. Se os itens não couberem em uma
    // fileira, quebram para a seguinte. Arrastar destaca; soltar confirma.

    private fun showKeyPopup(anchor: View, alts: List<String>) {
        dismissPopup()

        val itemW    = dp(48)
        val margin   = dp(4)
        val padding  = dp(4)
        val rowH     = dp(52)
        val screenW  = resources.displayMetrics.widthPixels

        // Quebra em quantas fileiras forem necessárias para não ultrapassar a largura da tela.
        // totalW é fixado em maxPerRow colunas para que o popup nunca saia da tela.
        val rowGap    = dp(6)
        val maxPerRow = ((screenW - padding * 2) / (itemW + margin)).coerceAtLeast(1)
        val rows      = alts.chunked(maxPerRow)
        val totalW    = maxPerRow.coerceAtMost(alts.size) * (itemW + margin) + padding * 2
        val totalH    = rows.size * rowH + (rows.size - 1).coerceAtLeast(0) * rowGap + padding * 2

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(padding, padding, padding, padding)
            background = GradientDrawable().apply {
                setColor(cAction)
                cornerRadius = dp(12).toFloat()
            }
        }

        val allViews = mutableListOf<TextView>()
        rows.forEachIndexed { rowIdx, rowAlts ->
            if (rowIdx > 0) {
                // spacer between rows
                val spacer = android.view.View(this).apply {
                    layoutParams = LinearLayout.LayoutParams(
                        LinearLayout.LayoutParams.MATCH_PARENT, rowGap
                    )
                }
                container.addView(spacer)
            }
            val rowLayout = LinearLayout(this).apply {
                orientation  = LinearLayout.HORIZONTAL
                gravity      = Gravity.CENTER_HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, rowH
                )
            }
            rowAlts.forEach { alt ->
                val tv = TextView(this).apply {
                    text     = alt
                    gravity  = Gravity.CENTER
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
                    setTextColor(Color.WHITE)
                    typeface = Typeface.DEFAULT_BOLD
                    layoutParams = LinearLayout.LayoutParams(itemW, ViewGroup.LayoutParams.MATCH_PARENT)
                        .apply { setMargins(margin / 2, 0, margin / 2, 0) }
                    background = roundRect(cKey)
                }
                rowLayout.addView(tv)
                allViews.add(tv)
            }
            container.addView(rowLayout)
        }

        popupViews       = allViews
        popupAlts        = alts
        popupItemWidth   = itemW + margin
        popupRowHeight   = rowH
        popupItemsPerRow = maxPerRow
        popupHighlighted = 0
        highlightPopupItem(0)

        val popup = PopupWindow(container, totalW, totalH, false).apply {
            isTouchable        = false
            isOutsideTouchable = false
        }

        val loc = IntArray(2)
        anchor.getLocationOnScreen(loc)
        val centeredLeft = loc[0] + anchor.width / 2 - totalW / 2
        val clampedLeft  = centeredLeft.coerceAtLeast(0).coerceAtMost(screenW - totalW)
        val xOff         = clampedLeft - loc[0]
        val yOff         = -(totalH + anchor.height + dp(6))

        popup.showAsDropDown(anchor, xOff, yOff)
        activePopup = popup

        popupLeft = clampedLeft + padding + margin / 2
        popupTop  = loc[1] + anchor.height + yOff + padding
    }

    private fun updatePopupHover(rawX: Float, rawY: Float) {
        if (popupViews.isEmpty()) return
        val maxRow = (popupAlts.size - 1) / popupItemsPerRow
        val row    = ((rawY - popupTop) / popupRowHeight).toInt().coerceIn(0, maxRow)
        // Last row may have fewer items than popupItemsPerRow
        val itemsInRow = if (row == maxRow) popupAlts.size - row * popupItemsPerRow
                         else popupItemsPerRow
        val col = ((rawX - popupLeft) / popupItemWidth).toInt().coerceIn(0, itemsInRow - 1)
        val idx = row * popupItemsPerRow + col
        if (idx != popupHighlighted) highlightPopupItem(idx)
    }

    private fun highlightPopupItem(idx: Int) {
        popupViews.forEachIndexed { i, tv ->
            tv.background = roundRect(if (i == idx) cShiftOn else cKey)
        }
        popupHighlighted = idx
    }

    private fun commitAndDismissPopup() {
        val idx = popupHighlighted
        if (idx in popupAlts.indices) {
            val chosen = popupAlts[idx]
            // If chosen is a diacritic key, go through handleChar so combining logic applies
            handleChar(chosen)
        }
        dismissPopup()
    }

    private fun dismissPopup() {
        activePopup?.dismiss()
        activePopup      = null
        popupViews       = emptyList()
        popupAlts        = emptyList()
        popupHighlighted = -1
        popupItemsPerRow = 1
    }

    // ── Input handlers ────────────────────────────────────────────────────────

    private fun handleChar(raw: String) {
        val ic = currentInputConnection ?: return

        // Diacríticos combinantes só funcionam na camada de letras. Nas camadas
        // de números e símbolos, ~ ` ^ etc. são caracteres literais.
        if (currentLayer == Layer.LETTERS) {
            val combining = combiningMap[raw]
            if (combining != null) {
                ic.commitText(combining, 1)
                return
            }
        }

        ic.commitText(applyShift(raw), 1)
        autoDownShift()
    }

    private fun applyShift(raw: String): String =
        if (shiftState != ShiftState.OFF && raw.length == 1 && raw[0].isLetter())
            raw.uppercase() else raw

    private fun autoDownShift() {
        if (shiftState == ShiftState.ON) {
            shiftState = ShiftState.OFF
            rebuildKeys()
        }
    }

    private fun handleShift() {
        shiftState = when (shiftState) {
            ShiftState.OFF    -> ShiftState.ON
            ShiftState.ON     -> ShiftState.LOCKED
            ShiftState.LOCKED -> ShiftState.OFF
        }
        rebuildKeys()
    }

    private fun handleBackspace() {
        val ic = currentInputConnection ?: return
        // Apaga marcas combinantes uma de cada vez para desfazer diacríticos empilhados
        val before = ic.getTextBeforeCursor(2, 0) ?: ""
        ic.deleteSurroundingText(1, 0)
    }

    private fun handleReturn() {
        currentInputConnection?.let { ic ->
            ic.sendKeyEvent(AndroidKeyEvent(AndroidKeyEvent.ACTION_DOWN, AndroidKeyEvent.KEYCODE_ENTER))
            ic.sendKeyEvent(AndroidKeyEvent(AndroidKeyEvent.ACTION_UP,   AndroidKeyEvent.KEYCODE_ENTER))
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private fun roundRect(color: Int): GradientDrawable = GradientDrawable().apply {
        setColor(color)
        cornerRadius = dp(8).toFloat()
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density + 0.5f).toInt()
}
