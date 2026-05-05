import { Component, OnInit, OnDestroy, ElementRef, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-hero',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './hero.component.html',
  styleUrl: './hero.component.scss'
})
export class HeroComponent implements OnInit, OnDestroy {
  @ViewChild('parallaxBg', { static: true }) parallaxBg!: ElementRef;

  private scrollHandler = () => {
    const scrollY = window.scrollY;
    if (this.parallaxBg?.nativeElement) {
      this.parallaxBg.nativeElement.style.transform = `translateY(${scrollY * 0.45}px)`;
    }
  };

  ngOnInit() {
    window.addEventListener('scroll', this.scrollHandler, { passive: true });
  }

  ngOnDestroy() {
    window.removeEventListener('scroll', this.scrollHandler);
  }

  scrollToAbout() {
    document.getElementById('about')?.scrollIntoView({ behavior: 'smooth' });
  }
}
