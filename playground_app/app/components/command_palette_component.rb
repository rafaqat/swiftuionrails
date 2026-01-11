# frozen_string_literal: true

class CommandPaletteComponent < ApplicationComponent
  include SwiftUIRails::DSL

  # Usage:
  # render CommandPaletteComponent.new do |palette|
  #   palette.group("Navigation") do
  #     palette.command("Dashboard", icon: "home", action: "visit:/dashboard")
  #     palette.command("Settings", icon: "cog", action: "visit:/settings")
  #   end
  # end

  def initialize
    @groups = []
    @current_group = nil
  end

  def group(name, &block)
    @current_group = { name: name, commands: [] }
    @groups << @current_group
    yield if block_given?
  end

  def command(title, icon: nil, shortcut: nil, action: nil, keywords: [])
    return unless @current_group
    @current_group[:commands] << {
      title: title,
      icon: icon,
      shortcut: shortcut,
      action: action,
      keywords: keywords + [title]
    }
  end

  swift_ui do
    div(
      data: {
        controller: "command-palette",
        action: "keydown.meta+k@window->command-palette#toggle keydown.ctrl+k@window->command-palette#toggle keydown.esc@window->command-palette#close"
      },
      class: "relative z-50"
    ) do
      # Backdrop
      div(
        class: "fixed inset-0 bg-gray-900/50 backdrop-blur-sm transition-opacity opacity-0 pointer-events-none",
        data: { command_palette_target: "backdrop", action: "click->command-palette#close" }
      )

      # Modal Container
      div(
        class: "fixed inset-0 overflow-y-auto px-4 py-4 sm:px-6 md:py-20 opacity-0 pointer-events-none scale-95 transition-all",
        data: { command_palette_target: "container" }
      ) do
        # The Palette
        div(
          class: "mx-auto max-w-xl transform divide-y divide-gray-100 overflow-hidden rounded-xl bg-white shadow-2xl ring-1 ring-black/5 transition-all"
        ) do
          # Search Input
          div(class: "relative") do
            # Search Icon
            svg(
              class: "pointer-events-none absolute left-4 top-3.5 h-5 w-5 text-gray-400",
              viewBox: "0 0 20 20", fill: "currentColor"
            ) do
              path(
                fill_rule: "evenodd",
                d: "M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z",
                clip_rule: "evenodd"
              )
            end

            input(
              type: "text",
              class: "h-12 w-full border-0 bg-transparent pl-11 pr-4 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm",
              placeholder: "Type a command or search...",
              role: "combobox",
              aria_expanded: "false",
              aria_controls: "options",
              data: {
                command_palette_target: "input",
                action: "input->command-palette#search keydown.down->command-palette#next keydown.up->command-palette#prev keydown.enter->command-palette#execute"
              }
            )
          end

          # Results List
          div(
            class: "max-h-96 scroll-py-3 overflow-y-auto p-3",
            id: "options",
            role: "listbox",
            data: { command_palette_target: "results" }
          ) do
            # Render all groups initially
            @groups.each do |group|
              div(class: "group-container", data: { group: group[:name] }) do
                div(class: "px-2 py-1.5 text-xs font-semibold text-gray-500") { text(group[:name]) }
                
                group[:commands].each do |cmd|
                  command_item(cmd)
                end
              end
            end
            
            # Empty State
            div(
              class: "hidden px-6 py-14 text-center text-sm sm:px-14",
              data: { command_palette_target: "empty" }
            ) do
              svg(
                class: "mx-auto h-6 w-6 text-gray-400",
                fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor"
              ) do
                path(
                  stroke_linecap: "round", stroke_linejoin: "round",
                  d: "M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z"
                )
              end
              text("No commands found").class("mt-4 text-gray-900 font-semibold")
            end
          end
          
          # Footer
          div(class: "flex flex-wrap items-center bg-gray-50 px-4 py-2.5 text-xs text-gray-700") do
            text("Type ").class("text-gray-500")
            kbd("Cmd K").class("mx-1 flex h-5 w-5 items-center justify-center rounded border bg-white font-semibold sm:mx-2 border-gray-400 text-gray-900")
            text("to open").class("text-gray-500")
          end
        end
      end
    end
  end

  private

  def command_item(cmd)
    div(
      class: "cursor-default select-none rounded-xl px-4 py-2 hover:bg-gray-100 hover:text-gray-900 group flex items-center justify-between",
      role: "option",
      tabindex: "-1",
      data: {
        command_palette_target: "item",
        action: "click->command-palette#execute",
        keywords: cmd[:keywords].join(" ").downcase,
        payload: cmd[:action]
      }
    ) do
      div(class: "flex items-center gap-3") do
        # Icon
        if cmd[:icon]
          div(class: "flex h-6 w-6 flex-none items-center justify-center rounded-lg bg-gray-50 group-hover:bg-white") do
            icon_svg(cmd[:icon])
          end
        end
        
        span(class: "font-medium text-gray-900") { text(cmd[:title]) }
      end
      
      if cmd[:shortcut]
        span(class: "ml-3 flex-none text-xs font-semibold text-gray-500") { text(cmd[:shortcut]) }
      end
    end
  end

  def icon_svg(name)
    # Simple icon mapping for demo
    d = case name.to_s
        when "home" then "M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
        when "plus" then "M12 4.5v15m7.5-7.5h-15"
        when "cog" then "M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"
        when "moon" then "M21.752 15.002A9.718 9.718 0 0118 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 003 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 009.002-5.998z"
        else "M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.348a1.125 1.125 0 010 1.971l-11.54 6.347a1.125 1.125 0 01-1.667-.985V5.653z"
        end
    
    svg(class: "h-4 w-4 text-gray-500 group-hover:text-gray-900", fill: "none", viewBox: "0 0 24 24", stroke_width: "1.5", stroke: "currentColor") do
      path(stroke_linecap: "round", stroke_linejoin: "round", d: d)
    end
  end
end
