"""Safe disposable OpenRouter Gauntlet smoke fixture. Not imported by the game.

The function is deliberately incorrect so a real builder must fix it. The
workflow works exclusively on a short-lived isolated checkout and never ships
the result to main or the Android app.
"""

def standard_d6_faces() -> int:
    return 5
