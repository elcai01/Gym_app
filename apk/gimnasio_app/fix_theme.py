import re

def main():
    file_path = r"d:\Proyectos\Gimnasio_app\apk\gimnasio_app\lib\main.dart"
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Find the start and end of ThemeData
    start_str = "theme: ThemeData("
    start_idx = content.find(start_str)
    if start_idx == -1:
        print("Could not find ThemeData")
        return
        
    end_str = "home: const LoginPage(),"
    end_idx = content.find(end_str, start_idx)
    
    new_theme = """theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.goldSoft,
          surface: AppColors.card,
        ),
        textTheme: GoogleFonts.outfitTextTheme(const TextTheme(
          titleLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          titleMedium: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: AppColors.text),
          bodyMedium: TextStyle(color: AppColors.text),
        )),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.outfit(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
        cardTheme: CardThemeData(
          color: AppColors.card,
          elevation: 16,
          shadowColor: AppColors.gold.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: AppColors.border, width: 1.2),
          ),
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.input,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          labelStyle: const TextStyle(color: AppColors.textSoft, fontWeight: FontWeight.w500),
          floatingLabelStyle: const TextStyle(color: AppColors.goldSoft, fontWeight: FontWeight.w700),
          hintStyle: const TextStyle(color: AppColors.textSoft),
          prefixIconColor: AppColors.gold,
          suffixIconColor: AppColors.textSoft,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.gold, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.8),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
            elevation: 8,
            shadowColor: AppColors.gold.withValues(alpha: 0.4),
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 0.3,
            ),
            minimumSize: const Size.fromHeight(56),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gold,
            side: const BorderSide(color: AppColors.gold),
            minimumSize: const Size.fromHeight(52),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.gold;
            return AppColors.textSoft;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.gold.withValues(alpha: 0.35);
            }
            return AppColors.border;
          }),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.card,
          contentTextStyle: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      """
      
    content = content[:start_idx] + new_theme + content[end_idx:]

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
        
    print("Done fixing theme")

if __name__ == "__main__":
    main()
